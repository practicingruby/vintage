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
      @acc     = 0
      @x       = 0
      @y       = 0
      @sp      = 255
      @z       = 0 # FIXME: Move this all into a single byte flag array later
      @c       = 0 # ........................................................
      @n       = 0
      @memory  = memory
    end

    attr_reader :acc, :x, :y, :memory, :z, :c, :n

    def x=(new_x)
      @x = normalize(new_x)
    end

    def y=(new_y)
      @y = normalize(new_y)
    end

    def acc=(new_acc)
      @acc = normalize(new_acc) 
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

    def run(bytecode)
      @memory.load(bytecode)

      loop do
        code = @memory.shift

        return unless code
        op = self.class.opcodes[code]

        case op.first
        when "LDA"
          self.acc = read(op.last)
        when "LDX"
          self.x = read(op.last)
        when "LDY"
          self.y = read(op.last)
        when "STA"
          write(acc, op.last)
        when "STX"
          write(x, op.last)
        when "TAX"
          self.x = acc
        when "TXA"
          self.acc = x
        when "INX"
          self.x += 1 
        when "INY"
          self.y += 1
        when "DEX"
          self.x -= 1
        when "DEC"
          zp_update { |e| normalize(@memory[e] - 1) }
        when "INC" 
          zp_update { |e| normalize(@memory[e] + 1) }
        when "CPX"
          compare(x, read(op.last))
        when "CPY"
          compare(y, read(op.last))
        when "CMP"
          compare(acc, read(op.last))
        when "ADC"
          t = acc + read(op.last) + @c

          @n   = acc[7]
          @z   = (t == 0 ? 1 : 0)

          @c   = t > 255 ? 1 : 0
          @acc = t % 256
        when "SBC"
          t  = acc - read(op.last) - (@c == 0 ? 1 : 0)

          @n = t[7]
          @z = (t == 0 ? 1 : 0)

          @c = (t >= 0 ? 1 : 0)
          @acc = t % 256
        when "BNE"
          branch { @z == 0 }
        when "BEQ"
          branch { @z == 1 }
        when "BPL"
          branch { @n == 0 }
        when "BCS"
          branch { @c == 1 }
        when "BCC"
          branch { @c == 0 }
        when "PHA"
          push(@acc)
        when "PLA"
          self.acc = pull
        when "JMP"
          jump(@memory.shift(2))
        when "JSR"
         low, high = bytes(@memory.program_counter + 2)

         push(low)
         push(high)

         jump(@memory.shift(2))
        when "RTS"
          h = pull
          l = pull

          jump([l, h])
        when "AND"
          self.acc = @acc & read(op.last)
        when "SEC"
          @c = 1
        when "CLC"
          @c = 0
        when "LSR"
          @n   = 0
          @c   = acc[0]
          @acc = (acc >> 1) % 127
          @z   = (@acc == 0 ? 1 : 0)
        when "BIT"
          bits = (acc & read(op.last))
          
          bits.zero? ? @z = 1 : @z = 0
          @n = bits[7]
        when "NOP"
        when "BRK"
          return
        else
          if op
            raise LoadError, "#{op.inspect} not handled"
          else
            raise LoadError, "No operator matches code: #{'%.2x' % code}"
          end
        end
      end
    end

    private

    def zp_update
      address = @memory.shift

      @memory[address] = yield(address)
    end

    def jump(tuple)
      @memory.program_counter = int16(tuple)
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

    def branch
      if yield
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
