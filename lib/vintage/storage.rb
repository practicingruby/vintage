module Vintage
  class Storage
    PROGRAM_OFFSET = 0x0600

    def initialize(&callback)
      @memory          = Hash.new(0)
      @program_counter = PROGRAM_OFFSET
      @watchers        = []
      @masks           = []
    end

    def mask(filter, &callback)
      @masks << [filter, callback]
    end

    def watch(filter, &callback)
      @watchers << [filter, callback]
    end

    attr_accessor :program_counter

    def [](address)
      @masks.each do |filter, callback| 
        return callback.call if filter === address 
      end

      @memory[address]
    end

    def []=(address, value)
      @memory[address] = value

      @watchers.each do |filter, callback| 
         callback.call(address, value) if filter === address
      end
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
