require "csv"

module Vintage
  class Config
    CONFIG_DIR = "#{File.dirname(__FILE__)}/../../config"

    def initialize
      load_codes
      load_definitions
    end

    attr_reader :definitions, :codes

    private

    def load_codes
      csv_data = CSV.read("#{CONFIG_DIR}/6502.csv")
                    .map { |r| [r[0].to_i(16), [r[1].to_sym, r[2]]] }

      @codes = Hash[csv_data]
    end

    def load_definitions
      @definitions = {}

      instance_eval(File.read("#{CONFIG_DIR}/6502.rb"))
    end

    def method_missing(id, *a, &b)
      return super unless id == id.upcase

      @definitions[id] = b
    end
  end
end
