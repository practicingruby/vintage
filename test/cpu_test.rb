require_relative "helper"

describe "CPU" do
  let(:cpu) { Vintage::CPU.new }

  let(:registers) { [:a, :x, :y] }
  let(:flags)     { [:c, :n, :z] }

  it "initializes registers and flags to zero" do
    (registers + flags).each { |e| cpu[e].must_equal(0) }
  end

  it "allows directly setting registers" do
    registers.each do |e|
      value  = rand(0xff)

      cpu[e] = value
      cpu[e].must_equal(value)
    end
  end

  it "does not allow directly setting flags" do
    flags.each do |e|
      value  = rand(0xff)

      err = -> { cpu[e] = value }.must_raise(ArgumentError)
      err.message.must_equal "#{e.inspect} is not a register"
    end
  end

  it "truncates results to fit in a single byte" do
    cpu.result(0x1337).must_equal(0x37)
  end

  it "sets z=1 when a result is zero, sets z=0 otherwise" do
    cpu.result(0)
    cpu[:z].must_equal(1)

    cpu.result(0xcc)
    cpu[:z].must_equal(0)
  end

  it "sets n=1 when result is 0x80 or higher, n=0 otherwise" do
    cpu.result(rand(0x80..0xff))
    cpu[:n].must_equal(1)

    cpu.result(rand(0x00..0x7f))
    cpu[:n].must_equal(0)
  end
  
  it "implicitly calls result() when registers are set" do
    registers.each do |e|
      cpu[e] = 0x100
      
      cpu[e].must_equal(0)
      cpu[:z].must_equal(1)
      cpu[:n].must_equal(0)

      cpu[e] -= 1
      
      cpu[e].must_equal(0xff)
      cpu[:z].must_equal(0)
      cpu[:n].must_equal(1)
    end
  end

  it "allows setting the c flag via set_carry and clear_carry" do
    cpu.set_carry
    cpu[:c].must_equal(1)

    cpu.clear_carry
    cpu[:c].must_equal(0)
  end

  it "allows conditionally setting the c flag via carry_if" do
    # true condition
    x = 3
    cpu.carry_if { x > 1 }

    cpu[:c].must_equal(1)

    # false condition
    x = 0
    cpu.carry_if { x > 1 }

    cpu[:c].must_equal(0)
  end

 
end
