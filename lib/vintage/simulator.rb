require "csv"

module Vintage
  class Simulator
    def self.run(file, ui)
      config = Vintage::Config.new("6502")
      cpu    = Vintage::CPU.new
      mem    = Vintage::Storage.new

      mem.extend(MemoryMap)
      mem.ui = ui
      
      mem.load(File.binread(file).bytes)

      sim = new(mem, cpu, config)

      loop { sim.step } 
    end

    def initialize(mem, cpu, config)
      @mem    = mem
      @cpu    = cpu
      @config = config
    end

    attr_reader :mem, :cpu, :ref

    def step
      name, mode = @config.codes[mem.next]

      if name
        @ref = Addresser.read(mem, mode, cpu[:x], cpu[:y])

        instance_exec(&@config.definitions[name])
      else
        raise LoadError, "No operator matches code: #{'%.2x' % code}"
      end
    end
  end
end
