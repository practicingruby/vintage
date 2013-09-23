module Vintage
  class Storage
    PROGRAM_OFFSET = 0x0600

    def initialize(&callback)
      @memory          = Hash.new(0)
      @write_callback  = callback
      @program_counter = PROGRAM_OFFSET
    end

    attr_accessor :program_counter

    # FIXME: Unify with write_callback somehow, or have multiple callbacks.
    def [](address)
      if address == 0xfe
        rand(0xff)
      else
        @memory[address]
      end
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
        line.gsub!(/;.*\Z/, '')
        line.upcase!

        next if line.strip.empty?

        # FIXME: THIS CAN BE CLEANED UP MASSIVELY BY SPLITTING BETWEEN OP PART
        # AND ARGUMENTS PART.

        begin
          case line
          when /\s*(.*):\s*\Z/
            labels[$1] = bytecode.count
          when /LDA #/
            bytecode << lookup[:LDA_I]
            int8(line, bytecode)
          when /LDX/
            bytecode << lookup[:LDX_I]
            int8(line, bytecode)
          when /LDY/
            bytecode << lookup[:LDY]
            int8(line, bytecode)
          when /TAX/
            bytecode << lookup[:TAX]
          when /TXA/
            bytecode << lookup[:TXA]
          when /INX/
            bytecode << lookup[:INX]
          when /INY/
            bytecode << lookup[:INY]
          when /DEX/
            bytecode << lookup[:DEX]
          when /CPX/
            bytecode << lookup[:CPX_I]
            int8(line, bytecode)
          when /CPY/
            bytecode << lookup[:CPY_I]
            int8(line, bytecode)
          when /BNE (.*)\s*\Z/
            bytecode << lookup[:BNE]
            bytecode << $1.strip
          when /JMP (.*)\s*\Z/
            bytecode << lookup[:JMP]
            bytecode << $1.strip
          when /JSR (.*)\s*\Z/
            bytecode << lookup[:JSR]
            bytecode << $1.strip
          when /RTS/
            bytecode << lookup[:RTS]
          when /ADC #/
            bytecode << lookup[:ADC_I]
            int8(line, bytecode)
          when /ADC \$/
            bytecode << lookup[:ADC_Z]
            address8(line, bytecode)
          when /STA \$\h{4}\s*,\s*Y/
             bytecode << lookup[:STA_AY]
             address16_y(line, bytecode)
          when /PHA/
            bytecode << lookup[:PHA]
          when /PLA/
            bytecode << lookup[:PLA]
          when /STA \$\h{4}/
            bytecode << lookup[:STA_A]
            address16(line, bytecode)  
          when /STX \$\h{4}/
            bytecode << lookup[:STX_A]
            address16(line, bytecode)
          when /STA \$\h{2}/
            bytecode << lookup[:STA_Z]
            address8(line, bytecode)
          when /BRK/
            bytecode << lookup[:BRK]
          else
            raise "Syntax Error on line #{i + 1}:\n  #{line}"
          end
        rescue
          warn "error on line #{i + 1}:\n #{line}"
          next
        end
      end

      # FIXME: Possibly wrong, come back to it later
      bytecode.flat_map.with_index do |c,i| 
        next c unless String === c

        if bytecode[i - 1] == lookup[:BNE]
          offset = labels[c] - i
          if offset < 0
            255 + offset
          else
            offset 
          end
        else
          [labels[c] + 1, 0x06]
        end
      end
    end

    def self.int8(text, bytecode)
      bytecode << text[/#\$(\h{2})\s*\Z/, 1].to_i(16)
    end

    def self.address8(text, bytecode)
      bytecode << text[/\$(\h{2})\s*\Z/, 1].to_i(16)
    end

    def self.address16(text, bytecode)
       md = text.match(/\$(\h{2})(\h{2})\s*\Z/)

       bytecode << md[2].to_i(16)
       bytecode << md[1].to_i(16)
    end

    def self.address16_y(text, bytecode)
       md = text.match(/\$(\h{2})(\h{2})\s*,\s*Y\s*\Z/)

       bytecode << md[2].to_i(16)
       bytecode << md[1].to_i(16)
    end
  end

  class Processor
    OPCODES = { 0xA9 => :LDA_I,
                0xA5 => :LDA_Z,
                0xB5 => :LDA_ZX,
                0x8D => :STA_A,
                0xAA => :TAX, 
                0xE8 => :INX, 
                0xC8 => :INY,
                0x69 => :ADC_I, 
                0x00 => :BRK,
                0x85 => :STA_Z, 
                0x65 => :ADC_Z, 
                0xa2 => :LDX_I,
                0xa6 => :LDX_Z,
                0xCA => :DEX, 
                0x8E => :STX_A, 
                0xE0 => :CPX_I,
                0xE4 => :CPX_Z,
                0xC0 => :CPY_I,
                0xD0 => :BNE,
                0xF0 => :BEQ,
                0xA0 => :LDY, 
                0x8A => :TXA,
                0x99 => :STA_AY,
                0x48 => :PHA,
                0x68 => :PLA,
                0x4C => :JMP,
                0x20 => :JSR,
                0x60 => :RTS,
                0x29 => :AND_I,
                0x18 => :CLC,
                0xC9 => :CMP_I,
                0xC5 => :CMP_Z }

    STACK_OFFSET = 0x0100

    def initialize(memory)
      @acc     = 0
      @x       = 0
      @y       = 0
      @sp      = 255
      @z       = 0 # FIXME: Move this all into a single byte flag array later
      @c       = 0 # ........................................................
      @memory  = memory
    end

    attr_reader :acc, :x, :y, :memory, :z, :c

    def run(bytecode)
      @memory.load(bytecode)

      loop do
        code = @memory.shift

        return unless code
        op = OPCODES[code]

        # FIXME: OPERATIONS NEED TO TAKE FLAGS INTO ACCOUNT
        case op
        when :LDA_I
          @acc = @memory.shift
        when :LDA_Z
          @acc = @memory[@memory.shift]
        when :LDA_ZX
          @acc = @memory[(@memory.shift + @x) % 256]
        when :LDX_I
          @x = @memory.shift
        when :LDX_Z
          @x = @memory[@memory.shift]
        when :LDY
          @y = @memory.shift
        when :STA_A
          @memory[int16(@memory.shift(2))] = @acc
        when :STA_AY
          @memory[int16((@memory.shift(2)) + @y) % 256] = @acc 
        when :STX_A
          @memory[int16(@memory.shift(2))] = @x
        when :STA_Z
          @memory[@memory.shift] = @acc
        when :TAX
          @x = @acc
        when :TXA
          @acc = @x
        when :INX
          @x = (@x + 1) % 256
        when :INY
          @y = (@y + 1) % 256
        when :DEX
          @x = (@x - 1) % 256
        when :CPX_I
          @x == @memory.shift ? @z = 1 : @z = 0
        when :CPX_Z
          @x == @memory[@memory.shift] ? @z = 1 : @z = 0
        when :CPY_I
          @y == @memory.shift ? @z = 1 : @z = 0
        when :CMP_I
          @acc == @memory.shift ? @z = 1 : @z = 0
        when :CMP_Z
          @acc == @memory[@memory.shift] ? @z = 1 : @z = 0
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
        when :BEQ
          if @z == 1
            offset = @memory.shift

            if offset <= 0x80
              @memory.program_counter += offset
            else
              @memory.program_counter -= (0xff - offset + 1)
            end
          else
            @memory.shift
          end
        when :PHA
          @memory[STACK_OFFSET + @sp] = @acc
          @sp -= 1
        when :PLA
          @sp += 1
          @acc = @memory[STACK_OFFSET + @sp]
        when :JMP
          @memory.program_counter = int16(@memory.shift(2))
        when :JSR
         low, high = [@memory.program_counter + 2].pack("v").unpack("c*")
         @memory[STACK_OFFSET + @sp] = low
         @sp -= 1
         @memory[STACK_OFFSET + @sp] = high
         @sp -= 1

         @memory.program_counter = int16(@memory.shift(2))
        when :RTS
          @sp += 1
          h = @memory[STACK_OFFSET + @sp]
          @sp += 1
          l = @memory[STACK_OFFSET + @sp]

          @memory.program_counter = int16([l, h])
        when :AND_I # FIXME: May be wrong or incomplete
          @acc = @acc & @memory.shift
        when :CLC
          @c = 0
        when :BRK
          return
        else
          p code
          raise LoadError, "No operator matches code: #{'%.2x' % code}"
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
      @pixels.push(Pixel.new(key % 32, (key - 0x200) / 32, Colors[value]))
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
