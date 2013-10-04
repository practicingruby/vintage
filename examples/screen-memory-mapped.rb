require_relative "../lib/vintage"
require_relative "../lib/vintage/display"

mem = Vintage::Storage.new
mem.extend(Vintage::MemoryMap)

mem.ui = Vintage::Display.new

(mem[0x0410] = mem[0xfe]) until mem[0xff] == 0x20 
