require_relative "../lib/vintage"
require_relative "../lib/vintage/visualization"

mem = Vintage::Storage.new
mem.extend(Vintage::MemoryMap)

mem.ui = Vintage::Visualization.new

(mem[0x0410] = mem[0xfe] % 16) until mem[0xff] == 0x20 
