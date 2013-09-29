NOP { }                         # does nothing
BRK { raise StopIteration }     # halts execution

LDA { reg.a = m.value }
LDX { reg.x = m.value }
LDY { reg.y = m.value }

STA { m.value = reg.a }
STX { m.value = reg.x }

TAX { reg.x = reg.a }
TXA { reg.a = reg.x }

INX { reg.x += 1  }
INY { reg.y += 1 }

DEX { reg.x -= 1 }
DEC { set(m, m.value - 1) }
INC { set(m, m.value + 1) } 

CPX { compare(x, m.value) }
CPY { compare(y, m.value) }
CMP { compare(a, m.value) }

BNE { branch(z == 0) }
BEQ { branch(z == 1) }
BPL { branch(n == 0) }
BCS { branch(c == 1) }
BCC { branch(c == 0) }

# TODO: convert to a memory instruction and inline
PHA { push(reg.a) }
PLA { reg.a = pull }

# TODO: convert to a memory instruction and inline (memory.jump)
JMP { jump }

# TODO: convert to a memory instruction and inline (memory.jsr)
JSR { jsr }

# TODO: convert to a memory instruction and inline (memory.rts)
RTS { rts }

AND { reg.a &= m.value }

SEC { @c = 1 }
CLC { @c = 0 }

BIT { normalize(a & m.value) }

LSR { 
  t = (reg.a >> 1) & 0x7F
 
  set(:a, t) { reg.a[0] == 1 } 
}

ADC { 
  t = reg.a + m.value + @c

  set(:a, t) { t > 0xff }
}

SBC {
  t  = a - m.value - (@c == 0 ? 1 : 0)

  set(:a, t) { t >= 0 }
}
