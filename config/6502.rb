#config.codemap = DATA

config.operations = {
  LDA: -> { reg.A  = e },
  LDX: -> { reg.X  = e },
  LDY: -> { reg.Y  = e },

  STA: -> { mem[e] = reg.A },
  STX: -> { mem[e] = reg.X },

  TAX: -> { reg.X  = reg.A },
  TXA: -> { reg.A  = reg.X },

  INX: -> { reg.X += 1 },
  INY: -> { reg.Y += 1 },

  DEX: -> { reg.X -= 1 },

  DEC: -> { mem[e] -= 1 },  # FIXME: probably wrong
  INC: -> { mem[e] += 1 },  # ditto

  CPX: -> { compare(reg.X, e) },
  CPY: -> { compare(reg.Y, e) },
  CMP: -> { compare(reg.A, e) },

  ADC: -> { add(reg.A, e) },

  SBC: -> { subtract(reg.A, e) },

  BNE: -> { branch(sta.Z == 0) },
  BEQ: -> { branch(sta.Z == 1) },

  BPL: -> { branch(sta.N == 1) },

  BCS: -> { branch(sta.C == 1) },
  BCC: -> { branch(sta.C == 0) },

  PHA: -> { push(reg.A) },
  PLA: -> { reg.A = pull },

  JMP: -> { jmp(e) },
  JSR: -> { jsr(e) },
  RTS: -> { rts },

  AND: -> { reg.A &= e },

  SEC: -> { sta.C = 1 },
  CLC: -> { sta.C = 0 },

  LSR: -> { lsr(e) },
  BIT: -> { bit(e) },
  NOP: -> { },
  BRK: -> { abort("We're done here!") }
}

__END__
00,BRK,#
10,BPL,@
18,CLC,#
20,JSR,AB
24,BIT,ZP
29,AND,IM
38,SEC,#
48,PHA,#
4A,LSR,#
4C,JMP,AB
60,RTS,#
65,ADC,ZP
68,PLA,#
69,ADC,IM
81,STA,IX
85,STA,ZP
8A,TXA,#
8D,STA,AB
8E,STX,AB
90,BCC,@
91,STA,IY
95,STA,ZX
99,STA,AY
A0,LDY,IM
A2,LDX,IM
A5,LDA,ZP
A6,LDX,ZP
A9,LDA,IM
AA,TAX,#
B0,BCS,@
B5,LDA,ZX
C0,CPY,IM
C5,CMP,ZP
C6,DEC,ZP
C8,INY,#
C9,CMP,IM
CA,DEX,#
D0,BNE,@
E0,CPX,IM
E4,CPX,ZP
E6,INC,ZP
E8,INX,#
E9,SBC,IM
EA,NOP,#
F0,BEQ,@
