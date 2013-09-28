LDA { reg.a = cell.value }
LDX { reg.x = cell.value }
LDY { reg.y = cell.value }

STA { cell.value = reg.a }
STX { cell.value = reg.x }

TAX { reg.x = a }
TXA { reg.a = x }

INX { reg.x += 1  }
INY { reg.y += 1 }

DEX { reg.x -= 1 }
DEC { cell.value = normalize(cell.value - 1) }
INC { cell.value = normalize(cell.value + 1) } 

CPX { compare(x, cell.value) }
CPY { compare(y, cell.value) }
CMP { compare(a, cell.value) }

ADC { add(cell.value) }
SBC { subtract(cell.value) }

BNE { branch(z == 0) }
BEQ { branch(z == 1) }
BPL { branch(n == 0) }
BCS { branch(c == 1) }
BCC { branch(c == 0) }

PHA { push(reg.a) }
PLA { reg.a = pull }

JMP { jump }

JSR { jsr }
RTS { rts }

AND { reg.a &= cell.value }

SEC { @c = 1 }
CLC { @c = 0 }

LSR { lsr }
BIT { bit(cell.value) }

NOP { }
BRK { raise StopIteration }
