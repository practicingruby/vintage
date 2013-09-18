require_relative "vintage"

hexdump   = File.binread("test/data/pixels.dump").unpack("C*")
assembled = Vintage::Assembler.load("test/data/pixels.asm")

puts hexdump == assembled ? "OK" : "FAIL -- Didn't expect #{assembled.inspect}... expected #{hexdump.inspect}"
