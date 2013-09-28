LDA { reg.a = read(mode) }
LDX { reg.x = read(mode) }
LDY { reg.y = read(mode) }

STA { write(a, mode) }
STX { write(x, mode) }

TAX { reg.x = a }
TXA { reg.a = x }

INX { reg.x += 1  }
INY { reg.y += 1 }

DEX { reg.x -= 1 }
DEC { zp_update { |e| normalize(@memory[e] - 1) } }
INC { zp_update { |e| normalize(@memory[e] + 1) } }

CPX { compare(x, read(mode)) }
CPY { compare(y, read(mode)) }
CMP { compare(a, read(mode)) }

ADC { add(read(mode)) }
SBC { subtract(read(mode)) }

BNE { branch(@z == 0) }
BEQ { branch(@z == 1) }
BPL { branch(@n == 0) }
BCS { branch(@c == 1) }
BCC { branch(@c == 0) }

PHA { push(@a) }
PLA { reg.a = pull }

JMP { jump(@memory.shift(2)) }

JSR { jsr }
RTS { rts }

AND { reg.a &= read(mode) }

SEC { @c = 1 }
CLC { @c = 0 }

LSR { lsr }
BIT { bit(read(mode)) }

NOP { }
BRK { raise StopIteration }
