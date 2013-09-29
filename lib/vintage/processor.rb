require "csv"

module Vintage
  class Processor
    STACK_OFFSET = 0x0100

    # TODO: MOVE INTO SOME SORT OF BUILDER PROXY

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

      dir  = File.dirname(__FILE__)
      instance_eval(File.read("#{dir}/../../config/6502.rb"))
    end

    attr_reader :a, :x, :y, :memory, :z, :c, :n

    # TODO: MOVE INTO SOME SORT OF BUILDER PROXY

    def method_missing(id, *a, &b)
      return super unless id == id.upcase
      singleton_class.send(:define_method, id, *a, &b)
    end

    def reg
      self
    end

    def x=(new_x)
      set(:x, new_x)
    end

    def y=(new_y)
      set(:y, new_y)
    end

    def a=(new_a)
      set(:a, new_a)
    end

    def normalize(number)
      number &= 0xff
      number == 0 ? @z = 1 : @z = 0
      @n = number[7]
      
      (@c = yield ? 1 : 0) if block_given?

      number
    end

    attr_accessor :m

    def run(bytecode)
      @memory.load(bytecode)

      loop do
        # FIXME: There should be a better way to do this
        code = @memory.next

        return unless code
        name, mode = self.class.opcodes[code]

        if name
          self.m = MemoryAccessor.new(self, mode)

          send(name)
        else
         raise LoadError, "No operator matches code: #{'%.2x' % code}"
        end
      end
    end

    private

    def set(key, value, &block)
      raise ArgumentError unless [:a, :x, :y].include?(key) || key.respond_to?(:value=)

      t = normalize(value, &block)

      if Symbol === key 
        instance_variable_set("@#{key}", t)
      else
        m.value = t
      end
    end

    # FIXME: Extract into Storage object 

    def jump
      @memory.program_counter = m.address
    end

    # FIXME: Extract into Storage object 

    def jsr
      low, high = bytes(@memory.program_counter)

      push(low)
      push(high)

      jump
    end

    # FIXME: Extract into Storage object 

    def rts
      h = pull
      l = pull

      @memory.program_counter = int16([l, h])
    end

    # FIXME: Extract into Storage object 

    def push(value)
      @memory[STACK_OFFSET + @sp] = value
      @sp -= 1
    end

    # FIXME: Extract into Storage object 

    def pull
      @sp += 1

      @memory[STACK_OFFSET + @sp]
    end

    # ... consider moving these helpers elsewehere...

    def compare(a,b)
      normalize(a - b) { a >= b }
    end

    def branch(test)
      return unless test

      offset = m.address
       
      if offset <= 0x80
        @memory.program_counter += offset
      else
        @memory.program_counter -= (0xff - offset + 1)
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
