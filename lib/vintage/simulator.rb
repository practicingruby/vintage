require "csv"

module Vintage
  class Simulator
    CONFIG_DIR = "#{File.dirname(__FILE__)}/../../config"

    def self.run(file, ui)
      mem = Vintage::Storage.new
      cpu = Vintage::CPU.new

      mem.extend(MemoryMap)
      mem.ui = ui

      new(mem, cpu).run(File.binread(file).unpack("C*"))
    end

    def initialize(mem, cpu)
      @mem = mem
      @cpu = cpu

      load_codes("#{CONFIG_DIR}/6502.csv")
      load_definitions("#{CONFIG_DIR}/6502.rb")
    end

    attr_reader :mem, :cpu, :ref

    def run(bytecode)
      mem.load(bytecode)

      loop do 
        code = mem.next
        code ? execute(code) : break
      end
    end

    def execute(code)
      raise StopIteration unless code

      name, mode = @codes[code]

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
      @definitions = {}

      instance_eval(File.read(file))
    end

    def method_missing(id, *a, &b)
      return super unless id == id.upcase

      @definitions[id] = b
    end
  end
end
