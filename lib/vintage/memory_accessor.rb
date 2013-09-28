module Vintage
  class MemoryAccessor
    def initialize(processor, mode)
      @processor = processor
      @mode      = mode

      @address   = computed_address
    end

    attr_reader :address
    
    def value
      raise NotImplementedError if ["#", "@"].include?(@mode)
      return @address           if @mode == "IM"


      @processor.memory[@address]
    end

    def value=(e) 
      raise NotImplementedError if ["IM", "#", "@"].include?(@mode)

      @processor.memory[@address] = e
    end

    private

    def computed_address
      @processor.instance_exec(@mode) do |mode|
        case mode
        when "IM", "ZP", "@"
          @memory.next
        when "ZX"
          (@memory.next + x) % 256
        when "IX"
          m = @memory.next

          l = @memory[m + x]
          h = @memory[m + x + 1]

         int16([l, h])
        when "IY"
          m = @memory.next

          l = @memory[m]
          h = @memory[m + 1]

          int16([l,h]) + y
        when "AB"
          int16(@memory.next(2))
        when "AY"
          int16(@memory.next(2)) + y
        when "#"
          # do nothing
        else
          raise NotImplementedError, mode.inspect
        end
      end
    end
  end
end
