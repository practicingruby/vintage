module Vintage
  module Operand
    def self.read(mem, mode, x, y)
      case mode
      when "#" # Implicit 
        nil
      when "@" # Relative
        offset = mem.next

        mem.pc + (offset <= 0x80 ? offset : -(0xff - offset + 1)) 
      when "IM" # Immediate
        mem.pc.tap { mem.next }
      when "ZP" # Zero Page
        mem.next
      when "ZX" # Zero Page, X
        mem.next + x
      when  "AB" # Absolute
        mem.int16([mem.next, mem.next])
      when "IX" # Indexed Indirect
        e = mem.next

        mem.int16([mem[e + x], mem[e + x + 1]])
      when "IY" # Indirect Indexed
        e = mem.next

        mem.int16([mem[e], mem[e+1]]) + y
      else
        raise NotImplementedError, mode.inspect
      end
    end
  end
end
