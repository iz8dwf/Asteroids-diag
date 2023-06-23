; Atari Asteroids RAM diag
; (when built-in diags can't find any clue)
; Rev 0.1a
; Very quick and effective check, but can identify
; only one defective IC (the first one found bad).
; Must be used only if the built-in diagnostics
; give no errors.
; IZ8DWF 2021

; Main CPU RAM is mapped from $0000 to $03FF
; UD2 makes the low nibble and UE2 makes the high nibble

; Vector RAM (shared with the vector machine) 
; is mapped from $4000 to $47FF
; $4000 to $43FF is on UM4 (low) and UR4 (high)
; $4400 to $47FF is on UN4 (low) and UP4 (high)

; Some useful sounds:
; $3C04 (Data 7) - ship fire
; $3C04 (D7) - life
; $3A00 - D4 = 1 "thump on", D4 = 0 "thump off"
; $3A00 - D0,D1,D2,D3 = thump frequency

; This code must be written on a 2716 EPROM and installed on UC1
; A15 is ignored, so we can be addressed either from $F800 to $FFFF
; or from $7800 to $78FF
; The test switch must be ON otherwise the board
; generates NMI at regular intervals and we aren't prepared for them.

; 1k random data starts at $7C00

; define length of morse dit and dash, the lower nibble sets the "thump frequency", D4 must always be 1.
dit = $57
dah = $B7

	* = $7800
reset
	SEI
	CLD
	LDX #$00
zerop	LDA $7C00,X
	STA $00,X
	INX
	BNE zerop
stack	LDA $7D00,X
	STA $0100,X
	INX
	BNE stack
pag2	LDA $7E00,X
	STA $0200,X
	INX
	BNE pag2
pag3	LDA $7F00,X
	STA $0300,X
	INX
	BNE pag3
zptst	LDA $00,X
	CMP $7C00,X
	BNE zperr
	INX
	BNE zptst
sttst	LDA $0100,X
	CMP $7D00,X
	BNE sterr
	INX
	BNE sttst
p2tst	LDA $0200,X
	CMP $7E00,X
	BNE p2err
	INX
	BNE p2tst
p3tst	LDA $0300,X
	CMP $7F00,X
	BNE p3err
	INX
	BNE p3tst
; if we reach here, main RAM is likely good!
	JMP vectest

zperr	EOR $7C00,X
	JMP mramerr
sterr	EOR $7D00,X
	JMP mramerr
p2err	EOR $7E00,X
	JMP mramerr
p3err	EOR $7F00,X
mramerr
	ASL
	BCS hmerr	; bit 7 bad
	ASL
	BCS hmerr	; bit 6 bad
	ASL
	BCS hmerr	; bit 5 bad
	ASL
	BCS hmerr	; bit 4 bad
	JMP lmerr	; then low nibble is bad
	
hmerr
; high memory nibble fault, this is on UE2
; let's make  "DIT sound" like the "E" morse code
	LDX #dit	
	STX $3A00	; enable "thump" (D4=1)
	LDY #$00	; 2 cycles
intc
	NOP		; 2 cycles
	DEY		; 2 cycles
	BNE intc	; 4 cycles
	DEX
	BNE intc
; inner loop = 2048 cycles
ex
	STX $3A00	; disable "thump" as X now is 0
intcy
	NOP		; 2 cycles
	DEY		; 2 cycles
	BNE intcy	; 4 cycles
	DEX
	BNE intcy
	JMP reset	; and restart forever
	
lmerr
; low memory nibble fault, this is on UD2
; let's make  "DAH DIT DIT sound" like the "D" morse code
	LDX #dah	
	STX $3A00	; enable "thump" (D4=1)
	LDY #$00	; 2 cycles
intc2
	NOP		; 2 cycles
	DEY		; 2 cycles
	BNE intc2	; 4 cycles
	DEX
	BNE intc2
; inner loop = 2048 cycles
	STX $3A00	; disable "thump"
; pause = one dot
	LDX #dit
	LDY #$00	; 2 cycles
intc3
	NOP		; 2 cycles
	DEY		; 2 cycles
	BNE intc3	; 4 cycles
	DEX
	BNE intc3
	LDX #dit	; DIT (1)
	STX $3A00	; enable "thump" 
	LDY #$00	; 2 cycles
intc4
	NOP		; 2 cycles
	DEY		; 2 cycles
	BNE intc4	; 4 cycles
	DEX
	BNE intc4
	STX $3A00	; disable "thump"
; pause = one dot
	LDX #dit	
	LDY #$00	; 2 cycles
intc5
	NOP		; 2 cycles
	DEY		; 2 cycles
	BNE intc5	; 4 cycles
	DEX
	BNE intc5
	LDX #dit	; DIT (2)
	STX $3A00	; enable "thump" 
	LDY #$00	; 2 cycles
intc6
	NOP		; 2 cycles
	DEY		; 2 cycles
	BNE intc6	; 4 cycles
	DEX
	BNE intc6
	JMP ex		
vectest
; we can set up the stack pointer and use zero page pointers
	LDX #$FF
	TXS
; we then use $00,$01 as pointer for vector memory to be tested
	LDA #$00
	STA $00
	LDA #$40	; first kilobyte at $4000 to $43FF
	STA $01
	LDA #$44
	STA $02
	JSR test1k
	LDA #$44	; second kilobyte at $4400 to $47FF
	STA $01
	LDA #$48
	STA $02
	JSR test1k
	JMP reset	; loop forever
test1k
	LDY #$00
	STY $10		; random data in our eprom
	LDA #$7C
	STA $11
	LDA $01		; save starting page
	STA $12
copy
	LDA ($10),Y
	STA ($00),Y
	INY
	BNE copy
	INC $11
	INC $01
	LDA $02
	CMP $01
	BNE copy
	LDA $12		; recover starting page
	STA $01
	LDA #$7C
	STA $11
vfy	
	LDA ($10),Y
	CMP ($00),Y
	BNE vrerr
	INY
	BNE vfy
	INC $11
	INC $01
	LDA $02
	CMP $01
	BNE vfy
	RTS
vrerr
	LDX $12		; see if it's first or second kB
	EOR ($00),Y
	AND #$0F	; clear all high errors
	BEQ hverr	; high nibble bad
	CPX #$40	; if not zero, then low nibble is bad
	BEQ lfirst
	JMP lsec
hverr
	CPX #$40
	BEQ hfirst
	JMP hsec
lfirst
	LDA #$02	; low nibble, first kB -> UM4, then play M
	STA $20
	LDA #$03
	STA $21
	JMP morse
hfirst
	LDA #$03	; high nibble, first kB -> UR4, then play R
	STA $20
	LDA #$02
	STA $21
	JMP morse
lsec
	LDA #$02	; low nibble, 2nd kB -> UN4, then play N
	STA $20
	LDA #$01
	STA $21
	JMP morse
hsec
	LDA #$04	; high nibble, 2nd kB -> UP4, then play P
	STA $20
	LDA #$06
	STA $21
morse
; we have the number of code symbols in $20 and the symbols in $21 (D0 first) as 0 = dit, 1 = dah
symb
	LDX #dit
	LSR $21
	BCC sound
	LDX #dah
sound
	STX $3A00	; enable "thump" 
	LDY #$00	; 2 cycles
ditc
	NOP		; 2 cycles
	DEY		; 2 cycles
	BNE ditc	; 4 cycles
	DEX
	BNE ditc
	STX $3A00	; disable "thump"
; pause = one dot
	LDX #dit	
	LDY #$00	; 2 cycles
ditp
	NOP		; 2 cycles
	DEY		; 2 cycles
	BNE ditp	; 4 cycles
	DEX
	BNE ditp
	DEC $20		
	BNE symb
	JMP reset	; after we play our letter, we can restart the whole test

endofcode
; fills the unused space with $FF 
	* = $7C00
.dsb (*-endofcode), $FF

; random data plus vectors at the end
	* = $7C00
random

