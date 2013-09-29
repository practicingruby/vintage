module Vintage
  module NumericHelpers
    def bytes(num)
      [num].pack("v").unpack("c*")
    end

    def int16(bytes)
      bytes.pack("c*").unpack("v").first
    end
  end
end
