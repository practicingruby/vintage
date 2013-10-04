require_relative "helper"

describe "Operand" do
  let(:mem) { Vintage::Storage.new }

  it "implements absolute addressing" do
    expected = { address: 0x1337, pc: mem.pc + 2 }

    read([0x37, 0x13], "AB").must_equal(expected)
  end

  it "implements absolute + y addressing" do
    expected = { address: 0x1337, pc: mem.pc + 2 }

    read([0x30, 0x13], "AY", y: 0x07).must_equal(expected)
  end

  it "implements zero page addressing" do
    expected = { address: 0x01, pc: mem.pc + 1 }

    read([0x01], "ZP").must_equal(expected)
  end

  it "implements zero page + x addressing" do
    expected = { address: 0x11, pc: mem.pc + 1 }

    read([0x01], "ZX", x: 0x10).must_equal(expected)
  end

  it "implements indirect + x addressing" do
    mem[0x12]   = 0x37
    mem[0x13]   = 0x13

    expected = { address: 0x1337,  pc: mem.pc + 1 }

    read([0x10], "IX", x: 2).must_equal(expected)
  end

  it "implements indirect + y addressing" do
    mem[0x10]   = 0x30
    mem[0x11]   = 0x13

    expected = { address: 0x1337, pc: mem.pc + 1 }
    
    read([0x10], "IY", y: 7).must_equal(expected)
  end

  it "implements immediate addressing" do
    expected = { address: mem.pc, pc: mem.pc + 1 }

    # note: actual value is ignored here
    read([0xAB], "IM").must_equal(expected)
  end

  it "implements implicit addressing" do
    expected = { address: nil, pc: mem.pc }
    
    read([0xAB], "#").must_equal(expected)
  end

  def read(bytes, mode, params={})
    x = params.fetch(:x, 0)
    y = params.fetch(:y, 0)

    mem.load(bytes)

    address = Vintage::Operand.read(mem, mode, x, y)
    pc      = mem.pc

    { :address => address, :pc => pc }
  end
end
