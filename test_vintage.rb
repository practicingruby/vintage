require_relative "vintage"

def bytecode(filename)
  File.binread("test/data/#{filename}.dump").unpack("C*")
end

def assert_equal(a,b)
  if a == b
    print "."
  else
    abort "\n\nFAIL -- Didn't expect #{b.inspect}... expected #{a.inspect}"
  end
end

# -- test pixels from assembly to bytecode

assembled = Vintage::Assembler.load("test/data/pixels.asm")

assert_equal(bytecode("pixels"), assembled)

## -- test arithmetic from bytecode to processor state

processor = Vintage::Processor.new(Vintage::NullVisualization)

assert_equal(processor.x, 0)
assert_equal(processor.acc, 0)

code = Vintage::Assembler.load("test/data/arithmetic.asm")

processor.run(code)

assert_equal(0xc1, processor.x)
assert_equal(0x84, processor.acc)
