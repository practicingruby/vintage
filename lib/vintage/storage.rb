module Vintage
  class Storage
    PROGRAM_OFFSET = 0x0600
    STACK_OFFSET   = 0x0100

    def initialize
      @memory = Hash.new(0)
      @pos    = PROGRAM_OFFSET
      @sp     = 255
    end

    def load(bytecode)
      index = PROGRAM_OFFSET

      bytecode.each_with_index { |c,i| @memory[index+i] = c }
    end

    def [](address)
      @memory[address]
    end

    def []=(address, value)
      @memory[address] = value
    end

    def next(n=1)
      data = n.times.map { |i| @memory[@pos + i] }
      @pos += n

      n == 1 ? data.first : data
    end

    def jump(address)
      @pos = address
    end

    def branch(test, offset)
      return unless test

      if offset <= 0x80
        @pos += offset
      else
        @pos -= (0xff - offset + 1)
      end
    end

    def jsr(address)
      low, high = bytes(@pos)

      push(low)
      push(high)

      jump(address)
    end

    def rts
      h = pull
      l = pull

      @pos = int16([l, h])
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
