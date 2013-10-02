module Vintage
  module Addresser
    def self.read(mem, mode, x, y)
      case mode
      when "#"
        NullReference
      when "IM", "ZP", "@", "ZX", "ZP", "IX", "IY"
        compute(mem.next, mode, mem, x, y)
      when "AY", "AB"
        l = mem.next
        h = mem.next

        compute([l, h], mode, mem, x, y)
      else
        raise NotImplementedError, mode.inspect
      end
    end

    def self.compute(value, mode, mem, x, y)
      case mode
      when "#"
        NullReference
      when "@"
        RelativeLocation.new(value, mem.pos)
      when "IM"
        ImmediateValue.new(value)
      when "ZP"
        Reference.new(value, mem)
      when "ZX"
        Reference.new((value + x) & 0xff, mem)
      when "AB"
        Reference.new(mem.int16(value), mem)
      when "AY"
        Reference.new(mem.int16(value) + y, mem)
      when "IX"
        l = mem[value + x]
        h = mem[value + x + 1]

        Reference.new(mem.int16([l, h]), mem)
      when "IY"
        l = mem[value]
        h = mem[value + 1]

        Reference.new(mem.int16([l,h]) + y, mem)
      else
        raise NotImplementedError, mode.inspect
      end
    end

    class NullReference; end

    class ImmediateValue
      def initialize(value)
        @value = value
      end

      attr_reader :value
    end

    class RelativeLocation
      def initialize(value, position)
        offset = value <= 0x80 ? value : -(0xff - value + 1)

        @address = position + offset
      end

      attr_reader :address
    end

    class Reference
      def initialize(address, memory)
        @address = address
        @memory  = memory
      end

      attr_reader :address

      def value
        @memory[@address]
      end

      def value=(new_value)
        @memory[@address] = new_value
      end
    end
  end
end
