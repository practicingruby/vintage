require_relative "helper"

describe "Storage" do
  let(:mem) { Vintage::Storage.new }

  it "can get and set values" do
    mem[0x01] = 0xAE

    mem[0x01].must_equal(0xAE)
  end

  it "can load a sequence of bytes" do
    mem.load([0x01, 0x03, 0x05, 0x07])

    mem.pos.must_equal(Vintage::Storage::PROGRAM_OFFSET)

    mem.next.must_equal(0x01)
    mem.next.must_equal(0x03)
    mem.next.must_equal(0x05)
    mem.next.must_equal(0x07)

    mem.pos.must_equal(Vintage::Storage::PROGRAM_OFFSET + 4)
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
    starting_pos = mem.pos

    mem.jump(starting_pos + 2)

    mem.pos.must_equal(starting_pos + 2)
  end

  it "implements jsr/rts" do
    starting_pos = mem.pos

    mem.jsr(Vintage::Storage::PROGRAM_OFFSET + 3)

    mem.pos.must_equal(starting_pos + 3)

    mem.rts
    mem.pos.must_equal(starting_pos)
  end

  it "implements conditional branching" do
    starting_pos = mem.pos

    x = 1
    mem.branch(x > 2, mem.pos + 5)

    mem.pos.must_equal(starting_pos)

    x = 3
    mem.branch(x > 2, mem.pos + 5)

    mem.pos.must_equal(starting_pos + 5)
  end

  it "can convert two bytes into a 16 bit integer" do
    mem.int16([0x37, 0x13]).must_equal(0x1337)
  end

  it "can convert a 16 bit integer into two bytes" do
    mem.bytes(0x1337).must_equal([0x37, 0x13])
  end
end
