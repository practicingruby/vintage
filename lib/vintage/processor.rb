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

    def method_missing(id, *a, &b)
      return super unless id == id.upcase
      singleton_class.send(:define_method, id, *a, &b)
    end

    def reg
      self
    end

    def x=(new_x)
      @x = normalize(new_x)
    end

    def y=(new_y)
      @y = normalize(new_y)
    end

    def a=(new_a)
      @a = normalize(new_a) 
    end

    def normalize(number)
      number %= 256
      number == 0 ? @z = 1 : @z = 0
      @n = number[7]

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

    def add(value)
      t = @a + value + @c

      @n   = @a[7]
      @z   = (t == 0 ? 1 : 0)

      @c   = t > 255 ? 1 : 0
      @a = t % 256
    end

    def subtract(value)
      t  = a - value - (@c == 0 ? 1 : 0)

      @n = t[7]
      @z = (t == 0 ? 1 : 0)

      @c = (t >= 0 ? 1 : 0)
      @a = t % 256
    end

    def jump
      @memory.program_counter = m.address
    end

    def jsr
      low, high = bytes(@memory.program_counter)

      push(low)
      push(high)

      jump
    end

    def rts
      h = pull
      l = pull

      @memory.program_counter = int16([l, h])
    end

    def lsr
      @n  = 0
      @c  = a[0]
      @a  = (a >> 1) % 127
      @z  = (@a == 0 ? 1 : 0)
    end
    
    def bit(value)
      bits = (a & value)
      
      bits.zero? ? @z = 1 : @z = 0
      @n = bits[7]
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
