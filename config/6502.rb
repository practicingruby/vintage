NOP { }                         # does nothing
BRK { raise StopIteration }     # halts execution

## Storage

LDA { cpu[:a] = ref.value }
LDX { cpu[:x] = ref.value }
LDY { cpu[:y] = ref.value }

TXA { cpu[:a] = cpu[:x] }

STA { ref.value = cpu[:a] }

## Counters

INX { cpu[:x] += 1 }
DEX { cpu[:x] -= 1 }

DEC { ref.value = cpu.result(ref.value - 1) }
INC { ref.value = cpu.result(ref.value + 1) } 

## Flow control

JMP { mem.jump(ref.address) }

JSR { mem.jsr(ref.address) }
RTS { mem.rts }

BNE { mem.branch(cpu[:z] == 0, ref.address) }
BEQ { mem.branch(cpu[:z] == 1, ref.address) }
BPL { mem.branch(cpu[:n] == 0, ref.address) }
BCS { mem.branch(cpu[:c] == 1, ref.address) }
BCC { mem.branch(cpu[:c] == 0, ref.address) }

## Comparisons

CPX do 
  cpu.carry_if(cpu[:x] >= ref.value)

  cpu.result(cpu[:x] - ref.value) 
end

CMP do 
  cpu.carry_if(cpu[:a] >= ref.value)

  cpu.result(cpu[:a] - ref.value) 
end


## Bitwise operations

AND { cpu[:a] &= ref.value }
BIT { cpu.result(cpu[:a] & ref.value) }

LSR do
  t = (cpu[:a] >> 1) & 0x7F
 
  cpu.carry_if(cpu[:a][0] == 1)
  cpu[:a] = t
end

## Arithmetic

SEC { cpu.set_carry   }
CLC { cpu.clear_carry }

ADC do 
  t = cpu[:a] + ref.value + cpu[:c]

  cpu.carry_if(t > 0xff)
  cpu[:a] = t
end

SBC do
  t  = cpu[:a] - ref.value - (cpu[:c] == 0 ? 1 : 0)

  cpu.carry_if(t >= 0)
  cpu[:a] = t
end
