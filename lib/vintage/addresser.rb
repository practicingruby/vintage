module Vintage
  module Addresser
    def self.read(mem, mode, x, y)
      case mode
      when "#"
        nil
      when "@"
        offset = mem.next

        mem.pos + (offset <= 0x80 ? offset : -(0xff - offset + 1)) 
      when "IM"
        mem.pos.tap { mem.next }
      when "ZP"
        mem.next
      when "ZX"
        mem.next + x
      when  "AB"
        mem.int16([mem.next, mem.next])
      when "AY"
        mem.int16([mem.next, mem.next]) + y
      when "IX"
        value = mem.next
          
        l = mem[value + x]
        h = mem[value + x + 1]

        mem.int16([l, h])
      when "IY"
        value = mem.next

        l = mem[value]
        h = mem[value + 1]

        mem.int16([l,h]) + y
      else
        raise NotImplementedError, mode.inspect
      end
    end
  end
end
