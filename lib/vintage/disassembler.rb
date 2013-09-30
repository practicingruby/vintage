require "csv"
require "set"

module Vintage
  class Disassembler
    CONFIG_DIR = "#{File.dirname(__FILE__)}/../../config"

    def initialize(file)
      @bytes      = File.binread(file).bytes
      @pc         = 0x0600
      @operations = Set.new
      @modes      = Set.new

      load_codes("#{CONFIG_DIR}/6502.csv")
    end

    def display_source
      loop do
        instruction, mode = @codes[@bytes.next]

        @operations << instruction
        @modes      << mode

        puts ["%.4x:" % @pc, instruction, argument(mode)].join(" ")
        @pc += 1
      end

      puts "\n\nOPERATIONS USED:"
      puts @operations.sort.join(" ")

      puts "\nADDRESSING MODES USED:"
      puts @modes.sort.join(" ")
    end

    def argument(mode)
      case mode
      when "#"
        ""
      when "@"
        "@" + int8
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

    def int8
      @pc += 1
      '%.2x' % @bytes.next
    end

    def int16
      l = int8
      h = int8

      [h,l].join
    end

    def load_codes(file)
      @codes = Hash[CSV.read(file)
                       .map { |r| [Integer(r[0], 16), [r[1].to_sym, r[2]]] }]
    end
  end
end
