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

  example "Branching" do
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

=begin
  LDX #$00
  LDY #$00
firstloop:
  TXA
  STA $0200,Y
  PHA
  INX
  INY
  CPY #$10
  BNE firstloop ;loop until Y is $10
secondloop:
  PLA
  STA $0200,Y
  INY
  CPY #$20      ;loop until Y is $20
  BNE secondloop
=end


  example "Stack" do
    processor.run([0xa2, 0x00, 0xa0, 0x00, 0x8a, 0x99, 0x00, 0x02, 0x48, 0xe8,
                   0xc8, 0xc0, 0x10, 0xd0, 0xf5, 0x68, 0x99, 0x00, 0x02, 0xc8,
                   0xc0, 0x20, 0xd0, 0xf7])
  end

  def assemble(string)
    Vintage::Assembler.load(string.strip)
  end

  def bytecode(filename)
    File.binread("test/data/#{filename}.dump").unpack("C*")
  end
end
