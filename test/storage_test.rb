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
    mem.pc.must_equal(program_offset) # load() does not increment counter

    bytes.each { |b| mem.next.must_equal(b) }

    mem.pc.must_equal(program_offset + 3)
  end

  it "sets an initial pcition of $0600" do
    program_offset.must_equal(0x0600)

    mem.pc.must_equal(program_offset)
  end

  it "returns zero by default" do
    mem[0x0101].must_equal(0)
  end

  it "truncates the values to fit in one byte" do
    mem[0x0101] = 0x1337

    mem[0x0101].must_equal(0x37)
  end

  let(:stack_origin) { Vintage::Storage::STACK_ORIGIN }
  let(:stack_offset) { Vintage::Storage::STACK_OFFSET }

  it "has a 256 element stack between 0x0100-0x01ff" do
    stack_offset.must_equal(0x0100)
    stack_origin.must_equal(0xff) # this value gets added to the offset
  end

  it "implements stack-like behavior" do
    mem.sp.must_equal(stack_origin)

    mem.push(0x01)
    mem.push(0x03)
    mem.push(0x05)

    mem.sp.must_equal(stack_origin - 3)

    mem.pull.must_equal(0x05)
    mem.pull.must_equal(0x03)
    mem.pull.must_equal(0x01)

    mem.sp.must_equal(stack_origin)
  end

  it "implements jump" do
    mem.jump(program_offset + 0xAB)

    mem.pc.must_equal(program_offset + 0xAB)
  end

  it "implements jsr/rts" do
    mem.jsr(0x0606)
    mem.jsr(0x060d)

    mem.pc.must_equal(0x060d)

    mem.rts
    mem.pc.must_equal(0x0606)

    mem.rts
    mem.pc.must_equal(program_offset)
  end

  it "implements conditional branching" do
    big   = 0xAB
    small = 0x01

    # a false condition does not affect mem.pc
    mem.branch(small > big, program_offset + 5)
    mem.pc.must_equal(program_offset)

    # true condition jumps to the provided address
    mem.branch(big > small, program_offset + 5)
    mem.pc.must_equal(program_offset + 5)
  end

  it "can convert two bytes into a 16 bit integer" do
    mem.int16([0x37, 0x13]).must_equal(0x1337)
  end

  it "can convert a 16 bit integer into two bytes" do
    mem.bytes(0x1337).must_equal([0x37, 0x13])
  end
end
