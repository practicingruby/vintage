module Vintage
  module Addresser
    def self.read(mem, mode, x, y)
      case mode
      when "#"
        nil
      when "IM", "ZP", "@", "ZX", "ZP", "IX", "IY"
        compute(mem.next, mode, mem, x, y)
      when "AY", "AB"
        l = mem.next
        h = mem.next

        compute(mem.int16([l, h]), mode, mem, x, y)
      else
        raise NotImplementedError, mode.inspect
      end
    end

    def self.compute(value, mode, mem, x, y)
      case mode
      when "#"
        nil
      when "@"
        offset = value <= 0x80 ? value : -(0xff - value + 1)
        mem.pos + offset
      when "IM"
        mem.pos - 1
      when "ZP", "AB"
        value
      when "ZX"
        value + x
      when "AY"
        value + y
      when "IX"
        l = mem[value + x]
        h = mem[value + x + 1]

        mem.int16([l, h])
      when "IY"
        l = mem[value]
        h = mem[value + 1]

        mem.int16([l,h]) + y
      else
        raise NotImplementedError, mode.inspect
      end
    end
  end
end
