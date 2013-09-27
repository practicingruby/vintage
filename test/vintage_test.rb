require "minitest/autorun"

require_relative "../lib/vintage"

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
    processor.a.must_equal(0)

    code = assemble '
      LDA #$c0
      TAX
      INX
      ADC #$c4
      BRK
    '

    processor.run(code)

    processor.x.must_equal(0xC1)
    processor.a.must_equal(0x84)
  end

  example "Instructions #2" do
    code = assemble '
      LDA #$80
      STA $01
      ADC $01
    '

    processor.run(code)

    processor.memory[0x01].must_equal(0x80)
    processor.a.must_equal(0)
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


  example "Stack" do
    code = assemble '
      LDX #$00
      LDY #$00
    firstloop:
      TXA
      STA $0200,Y
      PHA
      INX
      INY
      CPY #$10
      BNE firstloop
    secondloop:
      PLA
      STA $0200,Y
      INY
      CPY #$20
      BNE secondloop
    '

    processor.run(code)

    (0..0x0f).each do |i|
      processor.memory[0x0200 + i].must_equal(i)
    end

    (0x10..0x1f).each do |i|
      processor.memory[0x200 + i].must_equal(31 - i)
    end
  end


  example "Jump" do
    code = assemble '
      LDA #$03
      JMP there
      BRK
      BRK
      BRK
    there:
      STA $0200
    '

    processor.run(code)

    processor.memory[0x0200].must_equal(0x03)
  end

  example "JSR/RTS" do
    code = assemble '
      JSR init
      JSR loop
      JSR end

    init:
      LDX #$00
      RTS

    loop:
      INX
      CPX #$05
      BNE loop
      RTS

    end:
      BRK
    '

    processor.run(code)

    processor.x.must_equal(0x05)
  end

  def assemble(string)
    Vintage::Assembler.load(string.strip)
  end

  def bytecode(filename)
    File.binread("test/data/#{filename}.dump").unpack("C*")
  end
end
