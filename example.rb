require_relative "vintage"

ui      = Vintage::Visualization.new
memory  = Vintage::Storage.new { |k,v| ui.update(k,v) if (0x0200...0x05ff).include?(k) }

processor = Vintage::Processor.new(memory)

processor.run(Vintage::Assembler.load_file("test/data/example.asm"))
