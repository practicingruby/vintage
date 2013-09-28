module Vintage
  class Simulator
    def self.run(file, ui)
      memory = Vintage::Storage.new

      memory.extend(MemoryMap)
      memory.ui = ui

      processor = Vintage::Processor.new(memory)
      processor.run(File.binread(file).unpack("C*"))
    end
  end
end
