module Vintage
  class Storage
    PROGRAM_OFFSET = 0x0600

    def initialize(&callback)
      @memory          = {}
      @write_callback  = callback
      @program_counter = PROGRAM_OFFSET
    end

    attr_accessor :program_counter

    def [](address)
      @memory[address]
    end

    def load(bytecode)
      index = PROGRAM_OFFSET

      bytecode.each_with_index { |c,i| @memory[index+i] = c }
    end

    def shift(n=1)
      bytes = []

      n.times do
        bytes << @memory[@program_counter]
        @program_counter += 1
      end

      n == 1 ? bytes.first : bytes
    end

    def []=(address, value)
      @memory[address] = value

      @write_callback.call(address, value) if @write_callback
    end
  end

  class Assembler
    def self.load_file(filename)
      load(File.read(filename))
    end

    def self.load(src)
      lookup = Processor::OPCODES.invert
      labels = {}

      bytecode = []

      src.each_line.with_index do |line, i|
        begin
          case line
          when /\s*(.*):\s*\Z/
            labels[$1] = bytecode.count
          when /LDA/
            bytecode << lookup[:LDA]
            bytecode << line[/#\$(\h{2})\s*\Z/, 1].to_i(16)
          when /LDX/
            bytecode << lookup[:LDX]
            bytecode << line[/#\$(\h{2})\s*\Z/, 1].to_i(16)
          when /TAX/
            bytecode << lookup[:TAX]
          when /INX/
            bytecode << lookup[:INX]
          when /DEX/
            bytecode << lookup[:DEX]
          when /CPX/
            bytecode << lookup[:CPX_I]
            bytecode << line[/#\$(\h{2})\s*\Z/, 1].to_i(16)
          when /BNE (.*)\s*\Z/
            bytecode << lookup[:BNE]
            bytecode << $1
          when /ADC #/
            bytecode << lookup[:ADC_I]
            bytecode << line[/#\$(\h{2})\s*\Z/, 1].to_i(16)
          when /ADC \$/
            bytecode << lookup[:ADC_Z]
            bytecode << line[/\$(\h{2})\s*\Z/, 1].to_i(16)
          when /STA \$\h{4}/
            bytecode << lookup[:STA_A]
            
            md = line.match(/\$(\h{2})(\h{2})\s*\Z/)

            bytecode << md[2].to_i(16)
            bytecode << md[1].to_i(16)
          when /STX \$\h{4}/
            bytecode << lookup[:STX_A]
            
            md = line.match(/\$(\h{2})(\h{2})\s*\Z/)

            bytecode << md[2].to_i(16)
            bytecode << md[1].to_i(16)
          when /STA \$\h{2}/
            bytecode << lookup[:STA_Z]

            bytecode << line[/\$(\h{2})\s*\Z/, 1].to_i(16)
          when /BRK/
            bytecode << lookup[:BRK]
          else
            raise
          end
        rescue
          raise "Error on line #{i + 1}:\n  #{line}"
        end
      end

      bytecode.map.with_index do |c,i| 
        next c unless String === c
          
        # FIXME: Possibly wrong, come back to it later
        offset = labels[c] - i
        if offset < 0
          255 + offset
        else
          offset 
        end
      end
    end
  end

  class Processor
    OPCODES = { 0xa9 => :LDA, 0x8D => :STA_A, 0xAA => :TAX, 
                0xE8 => :INX, 0x69 => :ADC_I, 0x00 => :BRK,
                0x85 => :STA_Z, 0x65 => :ADC_Z, 0xa2 => :LDX,
                0xCA => :DEX, 0x8E => :STX_A, 0xE0 => :CPX_I,
                0xD0 => :BNE}

    def initialize(memory)
      @acc     = 0
      @x       = 0
      @z       = 0 # FIXME: Move this all into a single byte flag array later
      @c       = 0 # ........................................................
      @memory  = memory
    end

    attr_reader :acc, :x, :memory, :z, :c

    def run(bytecode)
      @memory.load(bytecode)

      loop do
        code = @memory.shift

        return unless code
        op = OPCODES[code]
        
        # FIXME: OPERATIONS NEED TO TAKE FLAGS INTO ACCOUNT
        case op
        when :LDA
          @acc = @memory.shift
        when :LDX
          @x = @memory.shift
        when :STA_A
          @memory[int16(@memory.shift(2))] = @acc
        when :STX_A
          @memory[int16(@memory.shift(2))] = @x
        when :STA_Z
          @memory[@memory.shift] = @acc
        when :TAX
          @x = @acc
        when :INX
          @x = (@x + 1) % 256
        when :DEX
          @x = (@x - 1) % 256
        when :CPX_I
          @x == @memory.shift ? @z = 1 : @z = 0
        when :ADC_I
          @acc = (@acc + @memory.shift) % 256
        when :ADC_Z
          @acc = (@acc + @memory[@memory.shift]) % 256
        when :BNE
          if @z == 0
            offset = @memory.shift

            if offset <= 0x80
              @memory.program_counter += offset
            else
              @memory.program_counter -= (0xff - offset + 1)
            end
          else
            @memory.shift
          end
        when :BRK
          return
        else
          raise LoadError, "No operator matches code: #{'%.2x' % code.inspect}"
        end
      end
    end

    private

    def int16(bytes)
      bytes.pack("c*").unpack("v").first
    end
  end
end

module Vintage
  class NullVisualization
    def self.update(*)
    end
  end
  class Visualization
    include Java
    
    SCALE = 16
    DIMENSIONS = 32

    import java.awt.Color
    import java.awt.Graphics
    import java.awt.BasicStroke
    import java.awt.Dimension
    import java.awt.Polygon

    import java.awt.image.BufferedImage
    import javax.swing.JPanel
    import javax.swing.JFrame
    import java.awt.event.KeyEvent
    import java.awt.event.KeyListener
    import java.awt.event.KeyAdapter

    Pixel = Struct.new(:x, :y, :color)
    Colors = [:black,  :white, :red,   :cyan,  :purple, :green, :blue,  :yellow, 
              :orange, :white, :white, :white, :white,  :white, :white, :white ]


    class Panel < JPanel
      attr_accessor :interface

      def paint(g)
        interface.render(g)
      end
    end

    class KeyCapture < KeyAdapter
      def keyPressed(e)
        p e.getKeyCode
      end
    end

    def initialize
      @panel = Panel.new
      @panel.interface = self
      @new   = true
      @pixels = []
      
      @panel.setPreferredSize(Dimension.new(SCALE * DIMENSIONS,
                                           SCALE * DIMENSIONS))

      @panel.setFocusable(true)
      @panel.addKeyListener(KeyCapture.new)

      frame = JFrame.new
      frame.add(@panel)
      frame.pack
      frame.show
    end

    def update(key, value)
      index = key - 0x0200

      @pixels.push(Pixel.new(index % 32, index / 32, Colors[value]))
      @panel.repaint
    end

    def fill_cell(g, x, y, c)
      g.setColor(c)
      g.fillRect(x * SCALE, y * SCALE, SCALE, SCALE)
    end

    def render(g)
      dim = DIMENSIONS

      img = BufferedImage.new(SCALE * dim, 
                              SCALE * dim,
                              BufferedImage::TYPE_INT_ARGB)

      bg  = img.getGraphics

      bg.setColor(Color.black)
      bg.fillRect(0,0, img.getWidth, img.getHeight)
      @new = false

      @pixels.each do |pixel|
        color = Color.send(pixel.color)

        fill_cell(bg, pixel.x, pixel.y, color)
      end

      g.drawImage(img, 0, 0, nil)
      bg.dispose
    end
  end

end

#require "rubygems"
#require "pry"
#binding.pry
