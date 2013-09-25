module Vintage
  class Assembler
    def self.load_file(filename)
      load(File.read(filename))
    end

    def self.load(src)
      lookup = Processor::OPCODES.invert
      labels = {}

      bytecode = []

      src.each_line.with_index do |line, i|
        line.gsub!(/;.*\Z/, '')
        line.upcase!

        next if line.strip.empty?

        # FIXME: THIS CAN BE CLEANED UP MASSIVELY BY SPLITTING BETWEEN OP PART
        # AND ARGUMENTS PART.

        begin
          case line
          when /\s*(.*):\s*\Z/
            labels[$1] = bytecode.count
          when /LDA #/
            bytecode << lookup[:LDA_I]
            int8(line, bytecode)
          when /LDX/
            bytecode << lookup[:LDX_I]
            int8(line, bytecode)
          when /LDY/
            bytecode << lookup[:LDY]
            int8(line, bytecode)
          when /TAX/
            bytecode << lookup[:TAX]
          when /TXA/
            bytecode << lookup[:TXA]
          when /INX/
            bytecode << lookup[:INX]
          when /INY/
            bytecode << lookup[:INY]
          when /DEX/
            bytecode << lookup[:DEX]
          when /CPX/
            bytecode << lookup[:CPX_I]
            int8(line, bytecode)
          when /CPY/
            bytecode << lookup[:CPY_I]
            int8(line, bytecode)
          when /BNE (.*)\s*\Z/
            bytecode << lookup[:BNE]
            bytecode << $1.strip
          when /JMP (.*)\s*\Z/
            bytecode << lookup[:JMP]
            bytecode << $1.strip
            bytecode << nil # FIXME: this is a placeholder for byte counting
          when /JSR (.*)\s*\Z/
            bytecode << lookup[:JSR]
            bytecode << $1.strip
            bytecode << nil # FIXME: this is a placeholder for byte counting
          when /RTS/
            bytecode << lookup[:RTS]
          when /ADC #/
            bytecode << lookup[:ADC_I]
            int8(line, bytecode)
          when /ADC \$/
            bytecode << lookup[:ADC_Z]
            address8(line, bytecode)
          when /STA \$\h{4}\s*,\s*Y/
             bytecode << lookup[:STA_AY]
             address16_y(line, bytecode)
          when /PHA/
            bytecode << lookup[:PHA]
          when /PLA/
            bytecode << lookup[:PLA]
          when /STA \$\h{4}/
            bytecode << lookup[:STA_A]
            address16(line, bytecode)  
          when /STX \$\h{4}/
            bytecode << lookup[:STX_A]
            address16(line, bytecode)
          when /STA \$\h{2}/
            bytecode << lookup[:STA_Z]
            address8(line, bytecode)
          when /BRK/
            bytecode << lookup[:BRK]
          else
            raise "Syntax Error on line #{i + 1}:\n  #{line}"
          end
        rescue
          warn "error on line #{i + 1}:\n #{line}"
          next
        end
      end

      # FIXME: (still) possibly wrong, come back to it later
      bytecode.flat_map.with_index do |c,i| 
        next c unless String === c

        if bytecode[i - 1] == lookup[:BNE]
          offset = labels[c] - i
          if offset < 0
            255 + offset
          else
            offset 
          end
        else
          [Storage::PROGRAM_OFFSET + labels[c]].pack("v").unpack("c*")
        end
      end.compact
    end

    def self.int8(text, bytecode)
      bytecode << text[/#\$(\h{2})\s*\Z/, 1].to_i(16)
    end

    def self.address8(text, bytecode)
      bytecode << text[/\$(\h{2})\s*\Z/, 1].to_i(16)
    end

    def self.address16(text, bytecode)
       md = text.match(/\$(\h{2})(\h{2})\s*\Z/)

       bytecode << md[2].to_i(16)
       bytecode << md[1].to_i(16)
    end

    def self.address16_y(text, bytecode)
       md = text.match(/\$(\h{2})(\h{2})\s*,\s*Y\s*\Z/)

       bytecode << md[2].to_i(16)
       bytecode << md[1].to_i(16)
    end
  end
end
