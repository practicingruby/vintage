NOP { }                         # does nothing
BRK { raise StopIteration }     # halts execution

LDA { cpu[:a] = ref.value }
LDX { cpu[:x] = ref.value }
LDY { cpu[:y] = ref.value }

STA { ref.value = cpu[:a] }

TXA { cpu[:a] = cpu[:x] }

INX { cpu[:x] += 1 }

DEX { cpu[:x] -= 1 }

DEC { ref.value = cpu.result(ref.value - 1) }
INC { ref.value = cpu.result(ref.value + 1) } 

BNE { mem.branch(cpu[:z] == 0, ref.address) }
BEQ { mem.branch(cpu[:z] == 1, ref.address) }
BPL { mem.branch(cpu[:n] == 0, ref.address) }
BCS { mem.branch(cpu[:c] == 1, ref.address) }
BCC { mem.branch(cpu[:c] == 0, ref.address) }

JMP { mem.jump(ref.address) }
JSR { mem.jsr(ref.address) }
RTS { mem.rts }

AND { cpu[:a] &= ref.value }
BIT { cpu.result(cpu[:a] & ref.value) }

SEC { cpu.set_carry   }
CLC { cpu.clear_carry }

CPX do 
  cpu.carry_if { cpu[:x] >= ref.value }

  cpu.result(cpu[:x] - ref.value) 
end

CMP do 
  cpu.carry_if { cpu[:a] >= ref.value }

  cpu.result(cpu[:a] - ref.value) 
end


LSR do
  t = (cpu[:a] >> 1) & 0x7F
 
  cpu.carry_if { cpu[:a][0] == 1 } 
  cpu[:a] = t
end

ADC do 
  t = cpu[:a] + ref.value + cpu[:c]

  cpu.carry_if { t > 0xff }
  cpu[:a] = t
end

SBC do
  t  = cpu[:a] - ref.value - (cpu[:c] == 0 ? 1 : 0)

  cpu.carry_if{ t >= 0 }
  cpu[:a] = t
end
