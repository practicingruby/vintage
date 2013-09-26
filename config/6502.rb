#       IM      ZP  ZX, ZP, ZX, 

op(:LDA).all { |m| reg[:a] = 0   }
op(:LDX).all { |m| reg[:x] = m   }
op(:STA).all { |m| mem[m]  = reg[:a] }
op(:STX).all { |m| mem[m]  = reg[:x] }
op(:TAX).all { |m| 
