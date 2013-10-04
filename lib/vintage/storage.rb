module Vintage
  class Storage
    PROGRAM_OFFSET = 0x0600
    STACK_OFFSET   = 0x0100
    STACK_ORIGIN   = 0xff

    def initialize
      @memory = Hash.new(0)
      @pc     = PROGRAM_OFFSET
      @sp     = STACK_ORIGIN
    end

    attr_reader :pc, :sp

    def load(bytes)
      index = PROGRAM_OFFSET

      bytes.each_with_index { |c,i| @memory[index+i] = c }
    end

    def [](address)
      @memory[address]
    end

    def []=(address, value)
      @memory[address] = (value & 0xff)
    end

    def next
      @memory[@pc].tap { @pc += 1 }
    end

    def jump(address)
      @pc = address
    end

    def branch(test, address)
      return unless test

      @pc = address
    end

    def jsr(address)
      low, high = bytes(@pc)

      push(low)
      push(high)

      jump(address)
    end

    def rts
      h = pull
      l = pull

      @pc = int16([l, h])
    end

    def push(value)
      @memory[STACK_OFFSET + @sp] = value
      @sp -= 1
    end

    def pull
      @sp += 1

      @memory[STACK_OFFSET + @sp]
    end

    def int16(bytes)
      bytes.pack("c*").unpack("v").first
    end

    def bytes(num)
      [num].pack("v").unpack("c*")
    end
  end
end
