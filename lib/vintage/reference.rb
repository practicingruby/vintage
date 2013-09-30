module Vintage
  class Reference
    def initialize(cpu, mem, mode)
      @mem  = mem
      @mode = mode

      @address = computed_address(cpu)
    end

    def address
      raise NotImplementedError if ["#", "IM"].include?(@mode)

      @address
    end
    
    def value
      raise NotImplementedError if ["#", "@"].include?(@mode)
      return @address           if @mode == "IM"


      @mem[@address]
    end

    def value=(e) 
      raise NotImplementedError if ["IM", "#", "@"].include?(@mode)

      @mem[@address] = e
    end

    private

    def computed_address(cpu)
      case @mode
      when "IM", "ZP", "@"
        @mem.next
      when "ZX"
        (@mem.next + cpu[:x]) % 256
      when "IX"
        m = @mem.next

        l = @mem[m + cpu[:x]]
        h = @mem[m + cpu[:x] + 1]

       @mem.int16([l, h])
      when "IY"
        m = @mem.next

        l = @mem[m]
        h = @mem[m + 1]

        @mem.int16([l,h]) + cpu[:y]
      when "AB"
        @mem.int16(@mem.next(2))
      when "AY"
        @mem.int16(@mem.next(2)) + cpu[:y]
      when "#"
        # do nothing
      else
        raise NotImplementedError, @mode.inspect
      end
    end
  end
end
