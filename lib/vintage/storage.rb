module Vintage
  class Storage
    PROGRAM_OFFSET = 0x0600

    def initialize(&callback)
      @memory          = Hash.new(0)
      @program_counter = PROGRAM_OFFSET
      @write_callbacks = []
    end

    def watch(&block)
      @write_callbacks << block
    end

    attr_accessor :program_counter

    # FIXME: Unify with callbacks somehow, or have multiple callbacks.
    def [](address)
      address == 0xfe ? rand(0xff) : @memory[address]
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

    def []=(address, value)
      @memory[address] = value

      @write_callbacks.each { |c| c.call(address, value) }
    end
  end
end
