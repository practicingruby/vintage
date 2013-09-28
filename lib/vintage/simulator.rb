module Vintage
  class Simulator
    def self.run(file, ui)
      memory = Vintage::Storage.new

      memory.mask(0xfe) { rand(0xff) }
      memory.mask(0xff) { ui.last_keypress }

      memory.watch(0x0200..0x05ff) do |k,v| 
        ui.update(k % 32, (k - 0x0200) / 32, v % 16)
      end

      processor = Vintage::Processor.new(memory)
      processor.run(File.binread(file).unpack("C*"))
    end
  end
end
