require "minitest/autorun"

require_relative "vintage"

# Test cases below come from the examples in:
# http://skilldrick.github.io/easy6502/#first-program

# Use the word "example" instead of it throughout -- TODO: Move into test helper
MiniTest::Spec.singleton_class.module_eval { alias_method :example, :it }

describe "Easy 6502" do
  let(:processor) { Vintage::Processor.new(Vintage::Storage.new) }

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
    processor.x.must_equal(0)
    processor.acc.must_equal(0)

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

    processor.memory[0x01].must_equal(0x80)
    processor.acc.must_equal(0)
  end

  example "Branching #1" do
    code = assemble '
      LDX #$08
    decrement:
      DEX
      STX $0200
      CPX #$03
      BNE decrement
      STX $0201
      BRK
    '
    processor.run(code)

    processor.memory[0x200].must_equal(0x03)
    processor.memory[0x201].must_equal(0x03)
  end

  def assemble(string)
    Vintage::Assembler.load(string.strip)
  end

  def bytecode(filename)
    File.binread("test/data/#{filename}.dump").unpack("C*")
  end
end
