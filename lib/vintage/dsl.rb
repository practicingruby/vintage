module Vintage
  class DSL
    def self.definitions(src)
      new(src).definitions
    end

    def initialize(src)
      @definitions = {}

      instance_eval(src)
    end

    attr_reader :definitions

    def method_missing(id, *a, &b)
      return super unless id == id.upcase

      @definitions[id] = b
    end
  end
end
