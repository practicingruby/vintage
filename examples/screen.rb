require_relative "../lib/vintage/visualization"

ui = Vintage::Visualization.new
ui.update(16, 16, color=rand(16)) until ui.last_keypress == 0x20 

exit!
