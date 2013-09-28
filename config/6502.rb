LDA { reg.a = m.value }
LDX { reg.x = m.value }
LDY { reg.y = m.value }

STA { m.value = reg.a }
STX { m.value = reg.x }

TAX { reg.x = a }
TXA { reg.a = x }

INX { reg.x += 1  }
INY { reg.y += 1 }

DEX { reg.x -= 1 }
DEC { m.value = normalize(m.value - 1) }
INC { m.value = normalize(m.value + 1) } 

CPX { compare(x, m.value) }
CPY { compare(y, m.value) }
CMP { compare(a, m.value) }

ADC { add(m.value) }
SBC { subtract(m.value) }

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

AND { reg.a &= m.value }

SEC { @c = 1 }
CLC { @c = 0 }

LSR { lsr }
BIT { bit(m.value) }

NOP { }
BRK { raise StopIteration }
