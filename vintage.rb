module Vintage
  Pixel = Struct.new(:x, :y, :color)

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

    def update(pixels)
      @pixels = pixels
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


Thread.abort_on_exception = true

vis = Vintage::Visualization.new

Thread.new do
  pixels = []
  loop do
    pixels += 20.times.map { Vintage::Pixel.new(rand(32), rand(32), [:red, :green, :blue, :yellow].sort_by { rand }.first) }
    vis.update(pixels)
    sleep 0.03
  end
end

sleep

