require "csv"

module Vintage
  class Processor
    STACK_OFFSET = 0x0100

    def self.opcodes
      return @opcodes if @opcodes

      dir  = File.dirname(__FILE__)
      data = CSV.read("#{dir}/../../config/6502.csv")

      @opcodes = Hash[data.map! { |r| [Integer(r[0], 16), [r[1], r[2]]] }]
    end

    def initialize(memory)
      @a     = 0
      @x       = 0
      @y       = 0
      @sp      = 255
      @z       = 0 # FIXME: Move this all into a single byte flag array later
      @c       = 0 # ........................................................
      @n       = 0
      @memory  = memory
    end

    attr_reader :a, :x, :y, :memory, :z, :c, :n

    def reg
      self
    end

    def x=(new_x)
      @x = normalize(new_x)
    end

    def y=(new_y)
      @y = normalize(new_y)
    end

    def a=(new_a)
      @a = normalize(new_a) 
    end

    def normalize(number)
      number %= 256
      number == 0 ? @z = 1 : @z = 0
      @n = number[7]

      number
    end

    def read(mode)
      case mode
      when "IM"
        @memory.shift
      when "ZP"
        @memory[@memory.shift]
      when "ZX"
        @memory[(@memory.shift + x) % 256]
      end
    end

    def write(value, mode)
      case mode
      when "AB"
        @memory[int16(@memory.shift(2))] = value
      when "AY"
        @memory[int16(@memory.shift(2)) + y] = value
      when "ZP"
        @memory[@memory.shift] = value
      when "ZX"
        @memory[(@memory.shift + x) % 256] = value
      when "IX"
        address = @memory.shift
        l = @memory[address + x]
        h = @memory[address + x + 1]

        @memory[int16([l, h])] = value
      when "IY"
        address = @memory.shift
        l = @memory[address]
        h = @memory[address + 1]

        @memory[int16([l,h]) + y] = value
      end
    end

    # FIXME: This is just a placeholder
    def operations
      return @ops if @ops

      # FIXME: replace with m.read, m.write(value) or similar

      @ops = {
        LDA: -> { reg.a = read(mode) },
        LDX: -> { reg.x = read(mode) },
        LDY: -> { reg.y = read(mode) },

        STA: -> { write(a, mode) },
        STX: -> { write(x, mode) },

        TAX: -> { reg.x = a },
        TXA: -> { reg.a = x },

        INX: -> { reg.x += 1  },
        INY: -> { reg.y += 1 },

        DEX: -> { reg.x -= 1 },

        DEC: -> { zp_update { |e| normalize(@memory[e] - 1) } },
        INC: -> { zp_update { |e| normalize(@memory[e] + 1) } },

        CPX: -> { compare(x, read(mode)) },
        CPY: -> { compare(y, read(mode)) },
        CMP: -> { compare(a, read(mode)) },

        ADC: -> { add(read(mode)) },
        SBC: -> { subtract(read(mode)) },

        BNE: -> { branch(@z == 0) },
        BEQ: -> { branch(@z == 1) },
        BPL: -> { branch(@n == 0) },
        BCS: -> { branch(@c == 1) },
        BCC: -> { branch(@c == 0) },
        
        PHA: -> { push(@a) },
        PLA: -> { reg.a = pull },

        JMP: -> { jump(@memory.shift(2)) },

        JSR: -> { jsr }, # NOTE: IS THIS EXCESS ABSTRACTION? 
        RTS: -> { rts },

        AND: -> { reg.a &= read(mode) },

        SEC: -> { @c = 1 },
        CLC: -> { @c = 0 },

        LSR: -> { lsr }, 
        BIT: -> { bit(read(mode)) },

        NOP: -> {},
        BRK: -> { raise StopIteration }
      }
    end

    attr_accessor :mode # FIXME: Ugly hack, roll into m.read / m.write(value) fix

    def run(bytecode)
      @memory.load(bytecode)

      loop do
        code = @memory.shift

        return unless code
        name, mode = self.class.opcodes[code]

        if name
          self.mode = mode
          instance_exec(&operations[name.to_sym])
        else
         raise LoadError, "No operator matches code: #{'%.2x' % code}"
        end
      end
    end

    private

    def add(value)
      t = @a + value + @c

      @n   = @a[7]
      @z   = (t == 0 ? 1 : 0)

      @c   = t > 255 ? 1 : 0
      @a = t % 256
    end

    def subtract(value)
      t  = a - value - (@c == 0 ? 1 : 0)

      @n = t[7]
      @z = (t == 0 ? 1 : 0)

      @c = (t >= 0 ? 1 : 0)
      @a = t % 256
    end

    def zp_update
      address = @memory.shift

      @memory[address] = yield(address)
    end

    def jump(tuple)
      @memory.program_counter = int16(tuple)
    end

    def jsr
      low, high = bytes(@memory.program_counter + 2)

      push(low)
      push(high)

      jump(@memory.shift(2)) 
    end

    def rts
      h = pull
      l = pull

      jump([l, h])
    end

    def lsr
      @n  = 0
      @c  = a[0]
      @a  = (a >> 1) % 127
      @z  = (@a == 0 ? 1 : 0)
    end
    
    def bit(value)
      bits = (a & value)
      
      bits.zero? ? @z = 1 : @z = 0
      @n = bits[7]
    end

    def push(value)
      @memory[STACK_OFFSET + @sp] = value
      @sp -= 1
    end

    def pull
      @sp += 1

      @memory[STACK_OFFSET + @sp]
    end

    def compare(a,b)
      t  = a - b

      @n = t[7]
      @c = a >= b ? 1 : 0
      @z = (t == 0 ? 1 : 0)
    end

    def branch(test)
      if test
        offset = @memory.shift

        if offset <= 0x80
          @memory.program_counter += offset
        else
          @memory.program_counter -= (0xff - offset + 1)
        end
      else
        @memory.shift
      end
    end

    def int16(bytes)
      bytes.pack("c*").unpack("v").first
    end

    def bytes(num)
      [num].pack("v").unpack("c*")
    end
  end
end
