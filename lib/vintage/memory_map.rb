module Vintage
  module MemoryMap
    RANDOMIZER  = 0xfe
    KEY_PRESS   = 0xff
    PIXEL_ARRAY = (0x0200..0x05ff)

    attr_accessor :ui

    def [](address)
      case address
      when RANDOMIZER
        rand(0xff)
      when KEY_PRESS
        ui.last_keypress
      else
        super
      end
    end

    def []=(k, v)
      super

      if PIXEL_ARRAY.include?(k)
        ui.update(k % 32, (k - 0x0200) / 32, v % 16)
      end
    end
  end
end
