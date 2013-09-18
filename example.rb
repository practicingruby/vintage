require_relative "vintage"

processor = Vintage::Processor.new(Vintage::Visualization.new)

processor.run(Vintage::Assembler.load("test/data/example.asm"))
