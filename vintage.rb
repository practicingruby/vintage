module Vintage
  class Processor
    OPCODES = { 0xa9 => :LDA, 0x8D => :STA }

    def initialize(display)
      @acc     = 0
      @memory  = {}
      @display = display
    end

    attr_reader :acc, :memory

    def [](key)
      @memory[key]
    end

    def []=(key, value)
      @memory[key] = value

      if (0x0200...0x05ff).include?(key)
        @display.update(key, value) 
      end
    end

    def run(codes)
      loop do
        return if codes.empty?

        op = OPCODES[codes.shift]

        case op
        when :LDA
          @acc = codes.shift
        when :STA
          self[int16(codes.shift(2))] = @acc
        else
          raise NotImplementedError
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

vis = Vintage::Visualization.new

processor = Vintage::Processor.new(vis)
processor.run(File.binread("test/data/pixels.dump").unpack("C*"))

#require "rubygems"
#require "pry"
#binding.pry
