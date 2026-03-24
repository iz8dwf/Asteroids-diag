; Atari Asteroids DVG diag
; Rev 0.1a
; IZ8DWF 2026

; Main CPU RAM is mapped from $0000 to $03FF

; Vector RAM 
; is mapped from $4000 to $47FF on CPU space
; for DVG it's mapped from $0 to $3FF (16 bit words)
; (first 1K segment from $0 to $1FF, second 1K from $200 to $3FF)

; Vector ROM is mapped from $5000 to $57FF on CPU space
; for DVG from $800 to $BFF

; needed inputs:
; $2001 (D7 only) - 3KHz
; $2002 (D7 only) - HALT 

; Some useful sounds:
; $3C04 (Data 7) - ship fire
; $3C04 (D7) - life
; $3A00 - D4 = 1 "thump on", D4 = 0 "thump off"
; $3A00 - D0,D1,D2,D3 = thump frequency

; needed output addresses:
; $3000	- DMAGO
; $3400 - WDCLR

; This code must be written on a 2716 EPROM and installed on UC1
; A15 is ignored, so we can be addressed either from $F800 to $FFFF
; or from $7800 to $78FF
; The test switch must be ON otherwise the board
; generates NMI at regular intervals and we aren't prepared for them.

; define length of morse dit and dash, the lower nibble sets the "thump frequency", D4 must always be 1.
dit = $57
dah = $B7

; shipdir vector list address in vector rom *CPU addr*
; 17 x two bytes addresses in CPU address space
sdlist = $5270		; for Atari rom1 and some italian clones

; character vector list address in vector rom *CPU addr*
; 37 x DVG's JSR instructions into DVG address space
chlist = $56D6		; Atari rom1 / bootlegs
chsiz = $25

	* = $7800
reset
	SEI
	CLD
	LDX #$FF 	; set up the stack pointer 
	TXS

chkhlt	BIT $2002	; check if the DVG is halted
	BMI chkhlt	; not halted 
	STX $3400	; clear watchdog

	LDA #$FC	; LABS to
	STA $4000
	STA $4400
	LDA #$A1
	STA $4001
	LDA #$A2
	STA $4401	
	LDA #$F4
	STX $4002	
	STX $4402
	LDA #$01
	STA $4003
	STA $4403	
	LDX #$FF
cpch	INX
	CPX #chsiz<<1
	BEQ whalt
	LDA chlist,X
	STA $4004,X
	STA $4404,X
	jmp cpch
whalt
	LDA #$00	
	STA $4004,X
	STA $4404,X
	INX
	LDA #$C1
	STA $4004,X
	LDA #$B0
	STA $4404,X
	JSR w3k
	STX $3000	; start DVG
	NOP
	JMP chkhlt

w3k	BIT $2001	; start on 3KHz going low
	BPL w3k
low3k   BIT $2001
	BMI low3k	
	RTS


ship0
.byt $0F,$F6,$C8,$FA,$BD,$F9,$00,$65,$00,$C3,$00,$65,$00,$C7,$B9,$F9,$CE,$F9,$CA,$F9,$00,$B0
; we then use $00,$01 as pointer for vector memory to be tested
; $02 = last page
; $03 = 0 or $FF for true or negated bits of random data
	
	LDA #$00
	STA $03		; first pass with random data
vecram	STA $00
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
	LDA $03
	CMP #$FF
	BEQ rst
	EOR #$FF
	STA $03
	EOR #$FF
	jmp vecram
rst	JMP reset	; loop forever
test1k
	LDY #$00
	STY $10		; random data in our eprom
	LDA #$7C
	STA $11
	LDA $01		; save starting page
	STA $12
copy
	LDA ($10),Y
	EOR $03		; optional inversion
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
	EOR $03
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
	* = $7FFC
.dsb (*-endofcode), $FF
;
;random
.byt $00,$78,$00,$78
