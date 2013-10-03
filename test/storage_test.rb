require_relative "helper"

describe "Storage" do
  let(:mem) { Vintage::Storage.new }
  let(:program_offset) { Vintage::Storage::PROGRAM_OFFSET }

  it "can get and set values" do
    mem[0x1337] = 0xAE

    mem[0x1337].must_equal(0xAE)
  end

  it "can load a bytecode sequence into memory and traverse it" do
    bytes = [0x20, 0x06, 0x06]

    mem.load(bytes)
    mem.pc.must_equal(program_offset)

    bytes.each { |b| mem.next.must_equal(b) }

    mem.pc.must_equal(program_offset + 3)
  end

  it "sets an initial pcition of $0600" do
    program_offset.must_equal(0x0600)

    mem.pc.must_equal(program_offset)
  end

  it "returns zero by default" do
    mem[0x01].must_equal(0)
  end

  it "truncates the values to fit in one byte" do
    mem[0x01] = 0x1337

    mem[0x01].must_equal(0x37)
  end

  it "implements stack-like behavior" do
    mem.push(0x01)
    mem.push(0x03)
    mem.push(0x05)

    mem.pull.must_equal(0x05)
    mem.pull.must_equal(0x03)
    mem.pull.must_equal(0x01)
  end

  it "implements jump" do
    mem.jump(program_offset + 0xAB)

    mem.pc.must_equal(program_offset + 0xAB)
  end

  it "implements jsr/rts" do
    mem.jsr(program_offset + 0xAB)

    mem.pc.must_equal(program_offset + 0xAB)

    mem.rts
    mem.pc.must_equal(program_offset)
  end

  it "implements conditional branching" do
    x = 1
    mem.branch(x > 2, program_offset + 5)

    mem.pc.must_equal(program_offset)

    x = 3
    mem.branch(x > 2, program_offset + 5)

    mem.pc.must_equal(program_offset + 5)
  end

  it "can convert two bytes into a 16 bit integer" do
    mem.int16([0x37, 0x13]).must_equal(0x1337)
  end

  it "can convert a 16 bit integer into two bytes" do
    mem.bytes(0x1337).must_equal([0x37, 0x13])
  end
end
