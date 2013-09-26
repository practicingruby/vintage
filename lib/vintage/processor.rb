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

    def run(bytecode)
      @memory.load(bytecode)

      loop do
        code = @memory.shift

        return unless code
        op = self.class.opcodes[code]

        # FIXME: OPERATIONS NEED TO TAKE FLAGS INTO ACCOUNT
        case op
        when ["LDA", "IM"]
          self.acc = @memory.shift
        when ["LDA", "ZP"]
          self.acc = @memory[@memory.shift]
        when ["LDA", "ZX"]
          self.acc = @memory[(@memory.shift + x) % 256]
        when ["LDX", "IM"]
          self.x = @memory.shift
        when ["LDX", "ZP"]
          self.x = @memory[@memory.shift]
        when ["LDY", "IM"]
          self.y = @memory.shift
        when ["STA", "AB"]
          @memory[int16(@memory.shift(2))] = acc
        when ["STA", "AY"]
          @memory[int16(@memory.shift(2)) + y] = acc  
        when ["STA", "IX"]
          #zero confidence in correctness here
          
          address = @memory.shift
          l = @memory[address + x]
          h = @memory[address + x + 1]

          @memory[int16([l, h])] = acc
        when ["STA", "IY"]
          address = @memory.shift
          l = @memory[address]
          h = @memory[address + 1]

          @memory[int16([l,h]) + y] = acc
        when ["STX", "AB"]
          @memory[int16(@memory.shift(2))] = x
        when ["STA", "ZP"]
          @memory[@memory.shift] = acc
        when ["STA", "ZX"]
          @memory[(@memory.shift + x) % 256] = acc
        when ["TAX", "#"]
          self.x = acc
        when ["TXA", "#"]
          self.acc = x
        when ["INX", "#"]
          self.x += 1 
        when ["INY", "#"]
          self.y += 1
        when ["DEX", "#"]
          self.x -= 1
        when ["DEC", "ZP"]
          address = @memory.shift
         
          t = normalize(@memory[address] - 1)

          @memory[address] = t
        when ["INC", "ZP"]
          address = @memory.shift
         
          t = normalize(@memory[address] + 1)

          @memory[address] = t
        when ["CPX", "IM"]
          m = @memory.shift
          
          t  = x - m
          @n = t[7]
          @c = x >= m ? 1 : 0
          @z = (t == 0 ? 1 : 0)
        when ["CPX", "ZP"]
          m = @memory[@memory.shift]

          t  = x - m
          @n = t[7]
          @c = x >= m ? 1 : 0
          @z = (t == 0 ? 1 : 0 )
        when ["CPY", "IM"]
          m = @memory.shift

          t = y - m
          @n = t[7]
          @c = y >= m ? 1 : 0
          @z = (t == 0 ? 1 : 0 )
        when ["CMP", "IM"]
          m = @memory.shift

          t = acc - m

          @n = t[7]
          @c = y >= acc ? 1 : 0
          @z = (t == 0 ? 1 : 0 )
        when ["CMP", "ZP"]
          m = @memory[@memory.shift]

          t = acc - m

          @n = t[7]
          @c = y >= acc ? 1 : 0
          @z = (t == 0 ? 1 : 0 )
        when ["ADC", "IM"]
          t = acc + @memory.shift + @c
          @n   = acc[7]
          @z   = (t == 0 ? 1 : 0)

          @c   = t > 255 ? 1 : 0
          @acc = t % 256
        when ["ADC", "ZP"]
          t = acc + @memory[@memory.shift] + @c

          @n   = acc[7]
          @z   = (t == 0 ? 1 : 0)

          @c   = t > 255 ? 1 : 0
          @acc = t % 256
        when ["SBC", "IM"]
          t  = acc - @memory.shift - (@c == 0 ? 1 : 0)
          @c = (t >= 0 ? 1 : 0)
          @n = t[7]
          @z = (t == 0 ? 1 : 0)

          @acc = t % 256
        when ["BNE", "@"]
          branch { @z == 0 }
        when ["BEQ", "@"]
          branch { @z == 1 }
        when ["BPL", "@"]
          branch { @n == 0 }
        when ["BCS", "@"]
          branch { @c == 1 }
        when ["BCC", "@"]
          branch { @c == 0 }
        when ["PHA", "#"]
          @memory[STACK_OFFSET + @sp] = @acc
          @sp -= 1
        when ["PLA", "#"]
          @sp += 1
          self.acc = @memory[STACK_OFFSET + @sp]
        when ["JMP", "AB"]
          @memory.program_counter = int16(@memory.shift(2))
        when ["JSR", "AB"]
         low, high = [@memory.program_counter + 2].pack("v").unpack("c*")
         @memory[STACK_OFFSET + @sp] = low
         @sp -= 1
         @memory[STACK_OFFSET + @sp] = high
         @sp -= 1

         @memory.program_counter = int16(@memory.shift(2))
        when ["RTS", "#"]
          @sp += 1
          h = @memory[STACK_OFFSET + @sp]
          @sp += 1
          l = @memory[STACK_OFFSET + @sp]

          @memory.program_counter = int16([l, h])
        when ["AND", "IM"]
          self.acc = @acc & @memory.shift
        when ["SEC", "#"]
          @c = 1
        when ["CLC", "#"]
          @c = 0
        when ["LSR", "#"]
          @n   = 0
          @c   = acc[0]
          @acc = (acc >> 1) % 127
          @z   = (@acc == 0 ? 1 : 0)
        when ["BIT", "ZP"]
          bits = (acc & @memory[@memory.shift])
          
          bits.zero? ? @z = 1 : @z = 0
          @n = bits[7]
        when ["NOP", "#"]
        when ["BRK", "#"]
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
  end
end
