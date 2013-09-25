module Vintage
  class Visualization
    include Java
    
    SCALE = 12
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
    
    # FIXME: Still not 100% compatible w. Easy6502 colors
    Colors = [:black,  :white, :red,   :cyan,  :magenta, :green, :blue,  :yellow, 
              :orange, :pink, :red, :darkGray, :gray,  :green, :blue, :lightGray ]


    class Panel < JPanel
      attr_accessor :interface

      def paint(g)
        interface.render(g)
      end
    end

    class KeyCapture < KeyAdapter
      attr_accessor :memory

      def keyPressed(e)
        memory[0xff] = e.getKeyChar
      end
    end

    def initialize(memory)
      @panel = Panel.new
      @panel.interface = self
      @new   = true
      @pixels = []
      
      @panel.setPreferredSize(Dimension.new(SCALE * DIMENSIONS,
                                           SCALE * DIMENSIONS))

      @panel.setFocusable(true)
      
      key_capture = KeyCapture.new
      key_capture.memory = memory
      @panel.addKeyListener(key_capture)

      memory.watch { |k,v| update(k,v) if (0x0200...0x05ff).include?(k) }

      frame = JFrame.new
      frame.add(@panel)
      frame.pack
      frame.show
    end

    def update(key, value)
      sleep 0.03

      @pixels.push(Pixel.new(key % 32, (key - 0x200) / 32, Colors[value % 16]))
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

