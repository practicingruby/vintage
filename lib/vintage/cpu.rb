module Vintage
  class CPU
    def initialize
      @registers = { :a => 0, :x => 0, :y => 0 }
      @flags     = { :z => 0, :c => 0, :n => 0 }
    end

    def [](key)
      @registers[key] || @flags.fetch(key)
    end

    def []=(key, value)
      raise ArgumentError unless @registers.key?(key)

      @registers[key] = result(value)
    end

    def set_carry
      @flags[:c] = 1
    end

    def clear_carry
      @flags[:c] = 0
    end

    def carry_if
      yield ? set_carry : clear_carry
    end

    def result(number)
      number &= 0xff

      @flags[:z] = (number == 0 ? 1 : 0)
      @flags[:n] = number[7]

      number
    end
  end
end

                   
