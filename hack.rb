class Instructions
  def initialize(config_file)
    @config = Struct.new(:codemap, :operations).new
    instance_eval(File.read("config/#{config_file}.rb"))
  end

  def execute(op, context)
    context.instance_exec(&@config.operations[op])
  end

  attr_reader :config
end

instructions = Instructions.new("6502")
processor    = Struct.new(:reg, :e).new(Struct.new(:A, :X, :Y).new)

5.times do
  instructions.execute(:LDA, processor) 
end
