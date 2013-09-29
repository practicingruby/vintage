module Vintage
  class Storage
    PROGRAM_OFFSET = 0x0600
    STACK_OFFSET   = 0x0100

    include NumericHelpers

    def initialize
      @memory          = Hash.new(0)
      @program_counter = PROGRAM_OFFSET
      @sp              = 255
    end

    attr_accessor :program_counter

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
      bytes = []

      n.times do
        bytes << @memory[@program_counter]
        @program_counter += 1
      end

      n == 1 ? bytes.first : bytes
    end

    def jump(m)
      @program_counter = m.address
    end

    def branch(test, ref)
      return unless test

      offset = ref.address
       
      if offset <= 0x80
        @program_counter += offset
      else
        @program_counter -= (0xff - offset + 1)
      end
    end

    def jsr(m)
      low, high = bytes(@program_counter)

      push(low)
      push(high)

      jump(m)
    end

    # FIXME: Extract into Storage object 

    def rts
      h = pull
      l = pull

      @program_counter = int16([l, h])
    end

    def push(value)
      @memory[STACK_OFFSET + @sp] = value
      @sp -= 1
    end

    # FIXME: Extract into Storage object 

    def pull
      @sp += 1

      @memory[STACK_OFFSET + @sp]
    end
  end
end
