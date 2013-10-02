module Vintage
  class Reference
    def initialize(x, y, mem, mode)
      @mem  = mem
      @mode = mode

      @address = computed_address(x, y)
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

    def computed_address(x, y)
      case @mode
      when "#"
        nil
      when "IM", "ZP", "@"
        @mem.next
      when "ZX"
        (@mem.next + x) % 256
      when "AB"
        @mem.int16(@mem.next(2))
      when "AY"
        @mem.int16(@mem.next(2)) + y
      when "IX"
        m = @mem.next

        l = @mem[m + x]
        h = @mem[m + x + 1]

       @mem.int16([l, h])
      when "IY"
        m = @mem.next

        l = @mem[m]
        h = @mem[m + 1]

        @mem.int16([l,h]) + y
      else
        raise NotImplementedError, @mode.inspect
      end
    end
  end
end
