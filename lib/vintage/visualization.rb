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
    
    Colors = [ Color.black,
               Color.white, 
               Color.red,  
               Color.cyan,  
               Color.magenta,
               Color.green,
               Color.blue,
               Color.yellow, 
               Color.orange, 
               Color.new(156, 93, 82),
               Color.pink,
               Color.darkGray, 
               Color.gray,  
               Color.green.brighter,
               Color.blue.brighter,
               Color.lightGray ]


    class Panel < JPanel
      attr_accessor :interface

      def paint(g)
        interface.render(g)
      end
    end

    class KeyCapture < KeyAdapter
      attr_accessor :ui

      def keyPressed(e)
        ui.last_keypress = e.getKeyChar
      end
    end

    attr_accessor :last_keypress

    def initialize
      @panel = Panel.new
      @panel.interface = self
      @new   = true
      @pixels = []
      @last_keypress = 0
      
      @panel.setPreferredSize(Dimension.new(SCALE * DIMENSIONS,
                                           SCALE * DIMENSIONS))

      @panel.setFocusable(true)
      
      key_capture = KeyCapture.new
      key_capture.ui = self
      @panel.addKeyListener(key_capture)


      frame = JFrame.new
      frame.setDefaultCloseOperation JFrame::EXIT_ON_CLOSE

      frame.add(@panel)
      frame.pack
      frame.show
    end

    def update(x, y, c)
      sleep 0.03

      @pixels.push(Pixel.new(x, y, Colors[c]))
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
        fill_cell(bg, pixel.x, pixel.y, pixel.color)
      end

      g.drawImage(img, 0, 0, nil)
      bg.dispose
    end
  end

end
