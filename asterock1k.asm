; Sidam Asterock  diag
; Rev 0.1a
; IZ8DWF 2026

; diagnostic output is two or more high beeps, indicating the bad SRAM IC
; (1 low beep at every program reset, cycling when a RAM error is found)
; 2 = lower nibble CPU RAM
; 3 = higher nibble CPU RAM
; 4,5,6,7 = lower, higher 1k, lower, higher 2k on vector RAM

; Asterock has quite a few hardare differences with respect to the original
; Asteroids, so it needs a dedicated diagnostic ROM.

; ROM #7 is mapped from $7C00 to $7FFF (2708 type).

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
; $3400 - WDCLR  (there's no easy hardware way to disable watchdog reset)

; The test switch must be ON otherwise the board
; generates NMI at regular intervals and we aren't prepared for them.

; define length of dit and dash, the lower nibble sets the "thump frequency", D4 must always be 1.
dit = $57
dah = $B0

	* = $7C00
reset
	SEI
	CLD
	
; let's make  "the start sound" 
        LDX #dah        
        STX $3A00       ; enable "thump" (D4=1)
        LDY #$00        ; 2 cycles
intc
	STX $3400	; clear watchdog
        DEY             ; 2 cycles
        BNE intc        ; 4 cycles
        DEX
        BNE intc
; inner loop = 2048 cycles

        STX $3A00       ; disable "thump" as X now is 0
intcy
	STX $3400	; clear watchdog
        DEY             ; 2 cycles
        BNE intcy       ; 4 cycles
        DEX
        BNE intcy

; first test the CPU RAM
	LDY #$01	; we try with different start values
	TYA
cpuram: STX $3400	; clear watchdog
	LDX #$00
	CLC
pag0:	STA $00,X
	ADC #$2F
	INX
	BNE pag0
pag1:	STA $0100,X
	ADC #$2F
	INX
	BNE pag1
pag2:	STA $0200,X
	ADC #$2F
	INX
	BNE pag2
pag3:	STA $0300,X
	ADC #$2F
	INX
	BNE pag3

	STX $3400	; clear watchdog
	CLC
	TYA		; let's read back now
cp0:	EOR $00,X
	BNE mramerr
	LDA $00,X
	ADC #$2F
	INX
	BNE cp0
cp1:	EOR $0100,X
	BNE mramerr
	LDA $0100,X
	ADC #$2F
	INX
	BNE cp1
cp2:	EOR $0200,X
	BNE mramerr
	LDA $0200,X
	ADC #$2F
	INX
	BNE cp2
cp3:	EOR $0300,X
	BNE mramerr
	LDA $0300,X
	ADC #$2F
	INX
	BNE cp3
	TYA
	ASL
	TAY		; save the new start value
	BNE cpuram
	BCS cpuram	; last iteration starting with A=0

	JMP vramtst	; if we get here, main ram is likely good.

mramerr
	TAX
	LDA #$02
	CPX #$0F	; higher or lower nibble error (only one error is beeped out)
        BCC ditdit	; lower nibble
 	ADC #$00	; then high nibble is bad (and carry is set)


; let's make A x  "DIT sound" 
 
ditdit:	LDX #dit        
        STX $3A00       ; enable "thump" (D4=1)
        LDY #$00        ; 2 cycles
intx:	STX $3400	; clear watchdog
        DEY             ; 2 cycles
        BNE intx        ; 4 cycles
        DEX
        BNE intx
; inner loop = 2048 cycles

        STX $3A00       ; disable "thump" as X now is 0
	LDX #dit
inty:
	STX $3400	; clear watchdog
        DEY             ; 2 cycles
        BNE inty       ; 4 cycles
        DEX
        BNE inty
	SEC
	SBC #$01
	BNE ditdit
intd:	STX $3400	; clear watchdog
        DEY             ; 2 cycles
        BNE intd       ; 4 cycles
        DEX
        BNE intd
	JMP reset

vramtst
	LDX #$FF 	; set up the stack pointer 
	TXS
; we then use $00,$01 as pointer for vector memory to be tested
; $02 = last page, $03 = start value
; $11 = start page saved
	LDA #$00
	STA $00
	LDA #$01	; we try with different start values
	STA $03
        LDA #$44
        STA $02
 	LDA #$40        ; first kilobyte at $4000 to $43FF
        STA $01
	JSR test1k
	LDA #$01	; restore the first start value
	STA $03
        LDA #$48
        STA $02
 	LDA #$44        ; second kilobyte at $4400 to $47FF
        STA $01
	JSR test1k
	JMP chkhlt	; if all RAM looks good, loop forever on DVG's HALT

vramerr
	TAX
	LDA #$04	; low nibble fist 1K 
	CPX #$0F
	BCC lower
	ADC #$00	; higher nibble adds one dit
lower:	LDY $01
	CPY #$44	; if higher, it's the second 1K
	BCC ditdit
	ADC #$01	; so add 2 dits
	JMP ditdit

test1k
	STA $11		; save starting page
	LDY #$00
exlop:	LDA $03
	CLC
	STX $3400	; clear watchdog
inlop:	STA ($00),Y
	ADC #$2F
	INY
	BNE inlop
	INC $01		; next page
	LDX $02
	CPX $01
	BNE inlop
	STX $3400	; clear watchdog
	LDA $11
	STA $01
	LDA $03
	CLC
cklop:	EOR ($00),Y
	BNE vramerr
	LDA ($00),Y
	ADC #$2F
	INY
	BNE cklop
	INC $01		; next page
	LDX $02
	CPX $01
	BNE cklop
	LDA $11
	STA $01
	ASL $03		; next starting value
	BNE exlop
	BCS exlop	; last iteration
	RTS


chkhlt	BIT $2002	; check if the DVG is halted
	BMI chkhlt	; not halted 
	STX $3400	; clear watchdog

	LDA #$00	; just execute HALT
	STA $4000
	LDA #$B0
	STA $4001

w3k	BIT $2001	; start on 3KHz going low
	BPL w3k
low3k   BIT $2001
	BMI low3k	
	STX $3000       ; start DVG
	JMP chkhlt	; loops forever


ship0
.byt $0F,$F6,$C8,$FA,$BD,$F9,$00,$65,$00,$C3,$00,$65,$00,$C7,$B9,$F9,$CE,$F9,$CA,$F9,$00,$B0
	

endofcode
; fills the unused space with $FF 
	* = $7FFC
.dsb (*-endofcode), $FF

; reset vector
.byt $00,$7C,$00,$7C
