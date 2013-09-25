module Vintage
  class Processor
    OPCODES = { 0xA9 => :LDA_I,
                0xA5 => :LDA_Z,
                0xB5 => :LDA_ZX,
                0x8D => :STA_A,
                0xAA => :TAX, 
                0xE8 => :INX, 
                0xC8 => :INY,
                0x69 => :ADC_I, 
                0x00 => :BRK,
                0x85 => :STA_Z,
                0x95 => :STA_ZX,
                0x91 => :STA_IY,
                0x81 => :STA_IX,
                0x65 => :ADC_Z, 
                0xa2 => :LDX_I,
                0xa6 => :LDX_Z,
                0xCA => :DEX, 
                0x8E => :STX_A, 
                0xE0 => :CPX_I,
                0xE4 => :CPX_Z,
                0xC0 => :CPY_I,
                0xD0 => :BNE,
                0xF0 => :BEQ,
                0xA0 => :LDY, 
                0x8A => :TXA,
                0x99 => :STA_AY,
                0x48 => :PHA,
                0x68 => :PLA,
                0x4C => :JMP,
                0x20 => :JSR,
                0x60 => :RTS,
                0x29 => :AND_I,
                0x18 => :CLC,
                0xC9 => :CMP_I,
                0xC5 => :CMP_Z,
                0x10 => :BPL,
                0x4A => :LSR,
                0xB0 => :BCS,
                0x90 => :BCC,
                0x38 => :SEC,
                0xE9 => :SBC_I,
                0xEA => :NOP,
                0x24 => :BIT,
                0xC6 => :DEC,
                0xE6 => :INC }

    STACK_OFFSET = 0x0100

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
        op = OPCODES[code]

        # FIXME: OPERATIONS NEED TO TAKE FLAGS INTO ACCOUNT
        case op
        when :LDA_I
          self.acc = @memory.shift
        when :LDA_Z
          self.acc = @memory[@memory.shift]
        when :LDA_ZX
          self.acc = @memory[(@memory.shift + x) % 256]
        when :LDX_I
          self.x = @memory.shift
        when :LDX_Z
          self.x = @memory[@memory.shift]
        when :LDY
          self.y = @memory.shift
        when :STA_A
          @memory[int16(@memory.shift(2))] = acc
        when :STA_AY
          @memory[int16(@memory.shift(2)) + y] = acc  
        when :STA_IX
          #zero confidence in correctness here
          
          address = @memory.shift
          l = @memory[address + x]
          h = @memory[address + x + 1]

          @memory[int16([l, h])] = acc
        when :STA_IY
          address = @memory.shift
          l = @memory[address]
          h = @memory[address + 1]

          @memory[int16([l,h]) + y] = acc
        when :STX_A
          @memory[int16(@memory.shift(2))] = x
        when :STA_Z
          @memory[@memory.shift] = acc
        when :STA_ZX
          @memory[(@memory.shift + x) % 256] = acc
        when :TAX
          self.x = acc
        when :TXA
          self.acc = x
        when :INX
          self.x += 1 
        when :INY
          self.y += 1
        when :DEX
          self.x -= 1
        when :DEC
          address = @memory.shift
         
          t = normalize(@memory[address] - 1)

          @memory[address] = t
        when :INC
          address = @memory.shift
         
          t = normalize(@memory[address] + 1)

          @memory[address] = t
        when :CPX_I
          m = @memory.shift
          
          t  = x - m
          @n = t[7]
          @c = x >= m ? 1 : 0
          @z = (t == 0 ? 1 : 0)
        when :CPX_Z
          m = @memory[@memory.shift]

          t  = x - m
          @n = t[7]
          @c = x >= m ? 1 : 0
          @z = (t == 0 ? 1 : 0 )
        when :CPY_I
          m = @memory.shift

          t = y - m
          @n = t[7]
          @c = y >= m ? 1 : 0
          @z = (t == 0 ? 1 : 0 )
        when :CMP_I
          m = @memory.shift

          t = acc - m

          @n = t[7]
          @c = y >= acc ? 1 : 0
          @z = (t == 0 ? 1 : 0 )
        when :CMP_Z
          m = @memory[@memory.shift]

          t = acc - m

          @n = t[7]
          @c = y >= acc ? 1 : 0
          @z = (t == 0 ? 1 : 0 )
        when :ADC_I
          t = acc + @memory.shift + @c
          @n   = acc[7]
          @z   = (t == 0 ? 1 : 0)

          @c   = t > 255 ? 1 : 0
          @acc = t % 256
        when :ADC_Z
          t = acc + @memory[@memory.shift] + @c

          @n   = acc[7]
          @z   = (t == 0 ? 1 : 0)

          @c   = t > 255 ? 1 : 0
          @acc = t % 256
        when :SBC_I
          t  = acc - @memory.shift - (@c == 0 ? 1 : 0)
          @c = (t >= 0 ? 1 : 0)
          @n = t[7]
          @z = (t == 0 ? 1 : 0)

          @acc = t % 256
        when :BNE
          branch { @z == 0 }
        when :BEQ
          branch { @z == 1 }
        when :BPL
          branch { @n == 0 }
        when :BCS
          branch { @c == 1 }
        when :BCC
          branch { @c == 0 }
        when :PHA
          @memory[STACK_OFFSET + @sp] = @acc
          @sp -= 1
        when :PLA
          @sp += 1
          self.acc = @memory[STACK_OFFSET + @sp]
        when :JMP
          @memory.program_counter = int16(@memory.shift(2))
        when :JSR
         low, high = [@memory.program_counter + 2].pack("v").unpack("c*")
         @memory[STACK_OFFSET + @sp] = low
         @sp -= 1
         @memory[STACK_OFFSET + @sp] = high
         @sp -= 1

         @memory.program_counter = int16(@memory.shift(2))
        when :RTS
          @sp += 1
          h = @memory[STACK_OFFSET + @sp]
          @sp += 1
          l = @memory[STACK_OFFSET + @sp]

          @memory.program_counter = int16([l, h])
        when :AND_I 
          self.acc = @acc & @memory.shift
        when :SEC
          @c = 1
        when :CLC
          @c = 0
        when :LSR
          @n   = 0
          @c   = acc[0]
          @acc = (acc >> 1) % 127
          @z   = (@acc == 0 ? 1 : 0)
        when :BIT
          bits = (acc & @memory[@memory.shift])
          
          bits.zero? ? @z = 1 : @z = 0
          @n = bits[7]
        when :NOP
        when :BRK
          return
        else
          p code
          raise LoadError, "No operator matches code: #{'%.2x' % code}"
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
