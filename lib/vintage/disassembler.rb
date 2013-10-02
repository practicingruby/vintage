require "set"

module Vintage
  class Disassembler
    def self.read(file)
      new(File.binread(file).bytes)
    end

    def initialize(bytes)
      @bytes        = bytes
      @pc           = 0x0600
      @codes        = Vintage::Config.new("6502").codes
      @instruction  = []
    end

    def display_source
      loop do
        @instruction.clear

        # These calls are order dependent!

        adr = address_dump  
        asm = assembly_dump(next_byte)
        ins = instruction_dump

        puts [adr, ins, asm].join(" ")
      end
    end

    def address_dump
      '%.4x:' % @pc
    end

    def assembly_dump(code)
      name, mode = @codes[code]

      [name, reference_dump(mode)].join(" ")
    end

    def reference_dump(mode)
      case mode
      when "#"
        ""
      when "@"
        '$' + relative_address
      when "IM"
        '#$' + int8
      when "ZP"
        '$' + int8
      when "ZX"
        '$' + int8 + ",X"
      when "IX"
        '($' + int8 + ',X)' 
      when "IY"
        '($' + int8 + '),Y'
      when "AB"
        "$" + int16
      when "AY"
        "$" + int16 + ",Y"
      end
    end

    def instruction_dump
      @instruction.map { |e| '%.2x' % e }.join(" ").ljust(10)
    end

    def next_byte
      code = @bytes.next

      @instruction << code
      @pc += 1

      code
    end

    def relative_address
      offset  = next_byte
        
      if offset <= 0x80
        address = @pc + offset + 1
      else
        address = @pc - (0xff - offset)
      end

      '%.4x' % address      
    end

    def int8
      '%.2x' % next_byte
    end

    def int16
      [int8, int8].reverse.join
    end
  end
end
