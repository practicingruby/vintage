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

CPX { cpu.compare(cpu[:x], ref.value) }
CMP { cpu.compare(cpu[:a], ref.value) }

BNE { mem.branch(cpu[:z] == 0, ref.address) }
BEQ { mem.branch(cpu[:z] == 1, ref.address) }
BPL { mem.branch(cpu[:n] == 0, ref.address) }
BCS { mem.branch(cpu[:c] == 1, ref.address) }
BCC { mem.branch(cpu[:c] == 0, ref.address) }

JMP { mem.jump(ref.address) }
JSR { mem.jsr(ref.address) }
RTS { mem.rts }

AND { cpu[:a] &= ref.value }

SEC { cpu.set_carry   }
CLC { cpu.clear_carry }

BIT { cpu.result(cpu[:a] & ref.value) }

LSR { 
  t = (cpu[:a] >> 1) & 0x7F
 
  cpu.update_carry { cpu[:a][0] == 1 } 
  cpu[:a] = t
}

ADC { 
  t = cpu[:a] + ref.value + cpu[:c]

  cpu.update_carry { t > 0xff }
  cpu[:a] = t
}

SBC {
  t  = cpu[:a] - ref.value - (cpu[:c] == 0 ? 1 : 0)

  cpu.update_carry{ t >= 0 }
  cpu[:a] = t
}
