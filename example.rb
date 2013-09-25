require_relative "lib/vintage"
require_relative "lib/vintage/visualization"

memory  = Vintage::Storage.new
ui      = Vintage::Visualization.new(memory)

processor = Vintage::Processor.new(memory)

#processor.run(Vintage::Assembler.load_file("test/data/snake.asm"))
processor.run(File.binread("test/data/snake.dump").unpack("C*"))
