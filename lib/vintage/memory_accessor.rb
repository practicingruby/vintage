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


      @processor.mem[@address]
    end

    def value=(e) 
      raise NotImplementedError if ["IM", "#", "@"].include?(@mode)

      @processor.mem[@address] = e
    end

    private

    def computed_address
      @processor.instance_exec(@mode) do |mode|
        case mode
        when "IM", "ZP", "@"
          mem.next
        when "ZX"
          (mem.next + cpu[:x]) % 256
        when "IX"
          m = mem.next

          l = mem[m + cpu[:x]]
          h = mem[m + cpu[:x] + 1]

         int16([l, h])
        when "IY"
          m = mem.next

          l = mem[m]
          h = mem[m + 1]

          int16([l,h]) + cpu[:y]
        when "AB"
          int16(mem.next(2))
        when "AY"
          int16(mem.next(2)) + cpu[:y]
        when "#"
          # do nothing
        else
          raise NotImplementedError, mode.inspect
        end
      end
    end
  end
end
