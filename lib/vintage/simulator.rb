require "csv"

module Vintage
  class Simulator
    CONFIG_DIR = "#{File.dirname(__FILE__)}/../../config"

    def self.run(file, ui)
      mem = Vintage::Storage.new
      cpu = Vintage::CPU.new

      mem.extend(MemoryMap)
      mem.ui = ui
      
      mem.load(File.binread(file).unpack("C*"))

      sim = new(mem, cpu)

      loop { sim.step } 
    end

    def initialize(mem, cpu)
      @mem = mem
      @cpu = cpu

      load_codes("#{CONFIG_DIR}/6502.csv")
      load_definitions("#{CONFIG_DIR}/6502.rb")
    end

    attr_reader :mem, :cpu, :ref

    def step
      name, mode = @codes[mem.next]

      if name
        @ref = Reference.new(cpu, mem, mode)

        instance_exec(&@definitions[name])
      else
        raise LoadError, "No operator matches code: #{'%.2x' % code}"
      end
    end

    def load_codes(file)
      @codes = Hash[CSV.read(file)
                       .map { |r| [Integer(r[0], 16), [r[1].to_sym, r[2]]] }]
    end

    def load_definitions(file)
      @definitions = Vintage::DSL.definitions(File.read(file))
    end
  end
end
