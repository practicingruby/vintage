module Vintage
  class Simulator
    EvaluationContext = Struct.new(:mem, :cpu, :e)
      
    def self.run(file, ui)
      config = Vintage::Config.new("6502")
      cpu    = Vintage::CPU.new
      mem    = Vintage::Storage.new

      mem.extend(MemoryMap)
      mem.ui = ui
      
      mem.load(File.binread(file).bytes)

      loop do
        code = mem.next

        name, mode = config.codes[code]
        if name
          e = Operand.read(mem, mode, cpu[:x], cpu[:y])

          EvaluationContext.new(mem, cpu, e)
                           .instance_exec(&config.definitions[name])
        else
          raise LoadError, "No operator matches code: #{'%.2x' % code}"
        end
      end
    end
  end
end
