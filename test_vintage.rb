require "minitest/autorun"

require_relative "vintage"

# Test cases below come from the examples in:
# http://skilldrick.github.io/easy6502/#first-program

# Use the word "example" instead of it throughout -- TODO: Move into test helper
MiniTest::Spec.singleton_class.module_eval { alias_method :example, :it }

describe "Easy 6502" do
  let(:processor) { Vintage::Processor.new(Vintage::NullVisualization) }

  example "First Program" do
    code = assemble '
      LDA #$01
      STA $0200
      LDA #$05
      STA $0201
      LDA #$08
      STA $0202
    '

    bytecode("pixels").must_equal(code)
  end

  example "Instructions #1" do
    assert_equal(processor.x, 0)
    assert_equal(processor.acc, 0)

    code = assemble '
      LDA #$c0
      TAX
      INX
      ADC #$c4
      BRK
    '

    processor.run(code)

    processor.x.must_equal(0xC1)
    processor.acc.must_equal(0x84)
  end

  example "Instructions #2" do
    code = assemble '
      LDA #$80
      STA $01
      ADC $01
    '

    processor.run(code)

    processor[0x01].must_equal(0x80)
    processor.acc.must_equal(0)
  end

  def assemble(string)
    Vintage::Assembler.load(string.strip)
  end

  def bytecode(filename)
    File.binread("test/data/#{filename}.dump").unpack("C*")
  end
end
