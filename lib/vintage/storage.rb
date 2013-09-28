module Vintage
  class Storage
    PROGRAM_OFFSET = 0x0600

    def initialize
      @memory          = Hash.new(0)
      @program_counter = PROGRAM_OFFSET
    end

    attr_accessor :program_counter

    def [](address)
      @memory[address]
    end

    def []=(address, value)
      @memory[address] = value
    end

    def load(bytecode)
      index = PROGRAM_OFFSET

      bytecode.each_with_index { |c,i| @memory[index+i] = c }
    end

    def shift(n=1)
      bytes = []

      n.times do
        bytes << @memory[@program_counter]
        @program_counter += 1
      end

      n == 1 ? bytes.first : bytes
    end
  end
end
