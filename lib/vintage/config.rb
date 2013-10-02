require "csv"

module Vintage
  class Config
    CONFIG_DIR = "#{File.dirname(__FILE__)}/../../config"

    def initialize(name)
      load_codes(name)
      load_definitions(name)
    end

    attr_reader :definitions, :codes

    private

    def load_codes(name)
      csv_data = CSV.read("#{CONFIG_DIR}/#{name}.csv")
                    .map { |r| [r[0].to_i(16), [r[1].to_sym, r[2]]] }

      @codes = Hash[csv_data]
    end

    def load_definitions(name)
      @definitions = {}

      instance_eval(File.read("#{CONFIG_DIR}/#{name}.rb"))
    end

    def method_missing(id, *a, &b)
      return super unless id == id.upcase

      @definitions[id] = b
    end
  end
end
