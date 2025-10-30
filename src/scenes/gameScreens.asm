SECTION "Game Start", ROM0
;;	En este archivo se cargará todo el tema de los tiles de las pantallas auxiliares (inicio y finales)
;; Además se esperará a que el jugador toque el joypad
;;PANTALLA DE FINAL
;;PANTALLA DE INICIO
;;ESTO ES UNA PRUEBA
;; LAS PANTALLAS SON PROVISIONALES


init_title_screen::
	ld de,$8000
	ld hl,font
	ld b,128-16
	call memcpy_256
	ld de,$8100
	ld hl,startTiles
	ld b,0
	call memcpy_256

	ld hl,startTiles + 256 * 1
	ld b,0
	call memcpy_256


	ld hl,startTiles + 256 * 2
	ld b,0
	call memcpy_256

	call draw_title_screen
	ret

draw_title_screen::
	call clear_map
	ld hl, StartScreen
	ld a,5
	ld c,4
	call draw_bg_line
	ld hl,StartScreen + 20 * 4
	ld a,15
	ld c,1
	call draw_bg_line


	ret

init_win_screen::
	ld de,$8000
	ld hl,font
	ld b,16
	call memcpy_256


	ld de,$8100
	ld hl,startTiles
	ld b,0
	call memcpy_256

	ld hl,startTiles + 256 * 1
	ld b,0
	call memcpy_256


	ld hl,startTiles + 256 * 2
	ld b,0
	call memcpy_256

	ld hl,startTiles + 256 * 3
	ld b,0
	call memcpy_256

	ld hl,startTiles + 256 * 4
	ld b,0
	call memcpy_256


	ld hl,startTiles + 256 * 5
	ld b,0
	call memcpy_256

	call draw_victory_screen
	ret
draw_victory_screen::
	call clear_map
	ld hl,WinScreen
	ld a,7
	ld c,2
	call draw_bg_line
	ret

draw_defeat_screen::
	call clear_map
	ld hl,LoseScreen
	ld a,6
	ld c,5
	call draw_bg_line
	ret
init_defeat_screen::
	ld de,$8000
	ld hl,font
	ld b,16
	call memcpy_256


	ld de,$8100
	ld hl,startTiles
	ld b,0
	call memcpy_256

	ld hl,startTiles + 256 * 1
	ld b,0
	call memcpy_256


	ld hl,startTiles + 256 * 2
	ld b,0
	call memcpy_256

	ld hl,startTiles + 256 * 3
	ld b,0
	call memcpy_256

	ld hl,startTiles + 256 * 4
	ld b,0
	call memcpy_256


	ld hl,startTiles + 256 * 5
	ld b,0
	call memcpy_256


	ld hl,startTiles + 256 * 6
	ld b,128
	call memcpy_256


	call draw_defeat_screen
	ret
;;Letras. No se pueden cambiar
font:
;;BLOQUE 1 Letras Pequeñas
;Tile vacío
DB $00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00
;R
DB $7E,$7E,$42,$42,$42,$42,$7E,$7E
DB $40,$40,$40,$40,$40,$40,$40,$40
;P
DB $7E,$7E,$42,$42,$42,$42,$7E,$7E
DB $60,$60,$50,$50,$48,$48,$44,$44
;E
DB $7C,$7C,$40,$40,$40,$40,$7C,$7C
DB $40,$40,$40,$40,$40,$40,$7C,$7C
;S
DB $FC,$FC,$80,$80,$80,$80,$FC,$FC
DB $04,$04,$04,$04,$04,$04,$FC,$FC
;A
DB $FE,$FE,$10,$10,$10,$10,$10,$10
DB $10,$10,$10,$10,$10,$10,$10,$10
;T
DB $F8,$F8,$88,$88,$88,$88,$F8,$F8
DB $88,$88,$88,$88,$88,$88,$88,$88
;;BLOQUE 2 Fuente del juego como tal
startTiles::
;B $10-$17
DB $FF,$FF,$80,$AA,$80,$D5,$80,$AA
DB $80,$FF,$8F,$FF,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$8F,$FF,$80,$FF
DB $80,$FF,$80,$FF,$80,$FF,$80,$FF
DB $FE,$FE,$01,$AB,$01,$55,$01,$AB
DB $01,$FF,$F1,$FF,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$F1,$FF,$01,$FF
DB $01,$FF,$01,$FF,$01,$FF,$02,$FE
DB $80,$FF,$80,$FF,$80,$FF,$80,$FF
DB $80,$FF,$8F,$FF,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$8F,$FF,$80,$FF
DB $80,$FF,$80,$FF,$80,$FF,$FF,$FF
DB $04,$FC,$02,$FE,$01,$FF,$01,$FF
DB $01,$FF,$F1,$FF,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$F1,$FF,$01,$FF
DB $01,$FF,$01,$FF,$01,$FF,$FE,$FE
;A $18-$1F
DB $FF,$FF,$80,$AA,$80,$D5,$80,$AA
DB $8F,$FF,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$8F,$FF,$80,$FF,$80,$FF
DB $80,$FF,$80,$FF,$80,$FF,$80,$FF
DB $FF,$FF,$01,$AB,$01,$55,$01,$AB
DB $F1,$FF,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$F1,$FF,$01,$FF,$01,$FF
DB $01,$FF,$01,$FF,$01,$FF,$01,$FF
DB $80,$FF,$80,$FF,$8F,$FF,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$F8,$F8
DB $01,$FF,$01,$FF,$F1,$FF,$11,$1F
DB $11,$1F,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$11,$1F,$1F,$1F
;D $20-$27
DB $FF,$FF,$80,$AA,$80,$D5,$80,$AA
DB $8F,$FF,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$88,$F8
DB $F8,$F8,$04,$AC,$04,$54,$02,$AA
DB $E2,$FE,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$11,$1F,$11,$1F
DB $88,$F8,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$88,$F8
DB $8F,$FF,$80,$FF,$80,$FF,$FF,$FF
DB $11,$1F,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$11,$1F,$12,$1E
DB $E2,$FE,$04,$FC,$04,$FC,$F8,$F8
;U $28-$2F
DB $F8,$F8,$88,$A8,$88,$D8,$88,$A8
DB $88,$F8,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$88,$F8
DB $1F,$1F,$11,$15,$11,$1B,$11,$15
DB $11,$1F,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$11,$1F,$11,$1F
DB $88,$F8,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$87,$FF
DB $80,$FF,$40,$7F,$20,$3F,$1F,$1F
DB $11,$1F,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$11,$1F,$E1,$FF
DB $01,$FF,$02,$FE,$04,$FC,$F8,$F8
;G $30-$37
DB $3F,$3F,$40,$55,$80,$AA,$80,$D5
DB $80,$FF,$83,$FF,$84,$FC,$84,$FC
DB $84,$FC,$84,$FC,$84,$FC,$84,$FC
DB $84,$FC,$84,$FC,$84,$FC,$84,$FC
DB $FC,$FC,$02,$56,$01,$AB,$01,$55
DB $01,$FF,$F1,$FF,$0F,$0F,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00
DB $84,$FC,$84,$FC,$84,$FC,$84,$FC
DB $84,$FC,$84,$FC,$84,$FC,$84,$FC
DB $84,$FC,$84,$FC,$84,$FC,$84,$FC
DB $83,$FF,$80,$FF,$40,$7F,$3F,$3F
DB $00,$00,$7F,$7F,$41,$7F,$41,$7F
DB $71,$7F,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$11,$1F,$11,$1F
DB $E1,$FF,$01,$FF,$02,$FE,$FC,$FC
;N $38-$3F
DB $F8,$F8,$8C,$AC,$8C,$DC,$8C,$AC
DB $82,$FE,$82,$FE,$82,$FE,$81,$FF
DB $81,$FF,$81,$FF,$80,$FF,$80,$FF
DB $80,$FF,$80,$FF,$80,$FF,$80,$FF
DB $1F,$1F,$11,$15,$11,$1B,$11,$15
DB $11,$1F,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$91,$9F,$91,$9F
DB $91,$9F,$51,$DF,$51,$DF,$51,$DF
DB $8C,$FF,$8C,$FF,$8C,$FF,$8A,$FB
DB $8A,$FB,$8A,$FB,$89,$F9,$89,$F9
DB $89,$F9,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$F8,$F8
DB $21,$FF,$01,$FF,$01,$FF,$01,$FF
DB $01,$FF,$01,$FF,$01,$FF,$01,$FF
DB $01,$FF,$81,$FF,$81,$FF,$81,$FF
DB $41,$7F,$41,$7F,$41,$7F,$3F,$3F
;S $40-43
DB $FF,$FF,$80,$AA,$80,$D5,$9F,$BF
DB $90,$F0,$90,$F0,$90,$F0,$9F,$FF
DB $80,$FF,$80,$FF,$FF,$FF,$00,$00
DB $FF,$FF,$80,$FF,$80,$FF,$FF,$FF
DB $FE,$FE,$01,$AB,$01,$55,$FE,$FE
DB $00,$00,$00,$00,$00,$00,$FC,$FC
DB $02,$FE,$01,$FF,$F1,$FF,$09,$0F
DB $F9,$FF,$01,$FF,$01,$FF,$FF,$FF
;C 44 47
DB $FF,$FF,$80,$AA,$80,$D5,$80,$AA
DB $8F,$FF,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$8F,$FF
DB $80,$FF,$80,$FF,$80,$FF,$FF,$FF
DB $FF,$FF,$01,$AB,$01,$55,$01,$AB
DB $FF,$FF,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$FF,$FF
DB $01,$FF,$01,$FF,$01,$FF,$FF,$FF
;U 48 4B
DB $F8,$F8,$88,$A8,$88,$D8,$88,$A8
DB $88,$F8,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$8F,$FF
DB $80,$FF,$80,$FF,$80,$FF,$FF,$FF
DB $1F,$1F,$11,$15,$11,$1B,$11,$15
DB $11,$1F,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$11,$1F,$F1,$FF
DB $01,$FF,$01,$FF,$01,$FF,$FF,$FF
;E 4C 4F
DB $FF,$FF,$80,$AA,$80,$D5,$8F,$AF
DB $88,$F8,$88,$F8,$8F,$FF,$80,$FF
DB $80,$FF,$8F,$FF,$88,$F8,$88,$F8
DB $8F,$FF,$80,$FF,$80,$FF,$FF,$FF
DB $FF,$FF,$01,$AB,$01,$55,$FF,$FF
DB $00,$00,$00,$00,$FF,$FF,$01,$FF
DB $01,$FF,$FF,$FF,$00,$00,$00,$00
DB $FF,$FF,$01,$FF,$01,$FF,$FF,$FF
;! 50 53
DB $03,$03,$02,$02,$02,$03,$02,$02
DB $02,$03,$02,$03,$02,$03,$02,$03
DB $02,$03,$03,$03,$00,$00,$00,$00
DB $03,$03,$02,$03,$02,$03,$03,$03
DB $C0,$C0,$40,$C0,$40,$40,$40,$C0
DB $40,$C0,$40,$C0,$40,$C0,$40,$C0
DB $40,$C0,$C0,$C0,$00,$00,$00,$00
DB $C0,$C0,$40,$C0,$40,$C0,$C0,$C0
;A 54 57
DB $7F,$7F,$80,$AA,$80,$D5,$8F,$AF
DB $88,$F8,$8F,$FF,$80,$FF,$80,$FF
DB $8F,$FF,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$F8,$F8
DB $FE,$FE,$01,$AB,$01,$55,$F1,$FB
DB $11,$1F,$F1,$FF,$01,$FF,$01,$FF
DB $F1,$FF,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$11,$1F,$1F,$1F
;G 58 5B
DB $FF,$FF,$80,$AA,$80,$D5,$9F,$BF
DB $90,$F0,$90,$F0,$90,$F0,$90,$F0
DB $90,$F0,$90,$F0,$90,$F0,$90,$F0
DB $9F,$FF,$80,$FF,$80,$FF,$FF,$FF
DB $FF,$FF,$01,$AB,$01,$55,$FF,$FF
DB $00,$00,$00,$00,$00,$00,$FF,$FF
DB $81,$FF,$81,$FF,$F9,$FF,$09,$0F
DB $F9,$FF,$01,$FF,$01,$FF,$FF,$FF
;M 5C 5F
DB $F0,$F0,$88,$A8,$88,$D8,$84,$AC
DB $84,$FC,$82,$FE,$82,$FE,$81,$FF
DB $80,$FF,$98,$FF,$94,$F7,$92,$F3
DB $91,$F1,$90,$F0,$90,$F0,$F0,$F0
DB $0F,$0F,$11,$15,$11,$1B,$21,$35
DB $21,$3F,$41,$7F,$41,$7F,$81,$FF
DB $01,$FF,$19,$FF,$29,$EF,$49,$CF
DB $89,$8F,$09,$0F,$09,$0F,$0F,$0F
;O 60 63
DB $7F,$7F,$80,$AA,$80,$D5,$80,$AA
DB $87,$FF,$88,$F8,$88,$F8,$88,$F8
DB $88,$F8,$88,$F8,$88,$F8,$87,$FF
DB $80,$FF,$80,$FF,$80,$FF,$7F,$7F
DB $FE,$FE,$01,$AB,$01,$55,$01,$AB
DB $E1,$FF,$11,$1F,$11,$1F,$11,$1F
DB $11,$1F,$11,$1F,$11,$1F,$E1,$FF
DB $01,$FF,$01,$FF,$01,$FF,$FE,$FE
;R 64 67
DB $FF,$FF,$80,$AA,$9F,$DF,$90,$B0
DB $90,$F0,$9F,$FF,$80,$FF,$80,$FF
DB $80,$FF,$8C,$FF,$8A,$FB,$89,$F9
DB $88,$F8,$88,$F8,$88,$F8,$F8,$F8
DB $FE,$FE,$01,$AB,$F9,$FD,$09,$0B
DB $09,$0F,$F9,$FF,$01,$FF,$FF,$FF
DB $80,$80,$40,$C0,$20,$E0,$10,$F0
DB $88,$F8,$44,$7C,$22,$3E,$1E,$1E
;V 68 6B
DB $F0,$F0,$90,$B0,$90,$D0,$90,$B0
DB $90,$F0,$90,$F0,$90,$F0,$90,$F0
DB $88,$F8,$44,$7C,$22,$3E,$11,$1F
DB $08,$0F,$04,$07,$02,$03,$01,$01
DB $0F,$0F,$09,$0B,$09,$0D,$09,$0B
DB $09,$0F,$09,$0F,$09,$0F,$09,$0F
DB $11,$1F,$22,$3E,$44,$7C,$88,$F8
DB $10,$F0,$20,$E0,$40,$C0,$80,$80


StartScreen::
;8 lineas de pantalla antes
DB $00,$10,$12,$18,$1A,$10,$12,$18,$1A,$20
DB $22,$28,$2A,$38,$3A,$30,$32,$18,$1A,$00

DB $00,$11,$13,$19,$1B,$11,$13,$19,$1B,$21
DB $23,$29,$2B,$39,$3B,$31,$33,$19,$1B,$00

DB $00,$14,$16,$1C,$1E,$14,$16,$1C,$1E,$24
DB $26,$2C,$2E,$3C,$3E,$34,$36,$1C,$1E,$00

DB $00,$15,$17,$1D,$1F,$15,$17,$1D,$1F,$25
DB $27,$2D,$2F,$3D,$3F,$35,$37,$1D,$1F,$00
;10 lineas de pantalla después
DB $00,$00,$00,$00,$01,$02,$03,$04,$04,$00
DB $00,$04,$05,$06,$02,$05,$00,$00,$00,$00
;8 lineas de pantalla después

;;Lose Screen
LoseScreen::
; 8 lineas antes
DB $00,$00,$00,$00,$58,$5a,$00,$54,$56,$00,$5c,$5e,$00,$4c,$4e,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$59,$5b,$00,$55,$57,$00,$5d,$5f,$00,$4d,$4f,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$60,$62,$00,$68,$6a,$00,$4c,$4E,$00,$64,$66,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$61,$63,$00,$69,$6b,$00,$4D,$4F,$00,$65,$67,$00,$00,$00,$00
;10 lineas después


;; Win Screen
WinScreen::
;8 lineas antes
DB $00,$00,$40,$42,$48,$4a,$44,$46,$44,$46,$4C,$4E,$40,$42,$40,$42,$50,$52,$00,$00
DB $00,$00,$41,$43,$49,$4b,$45,$47,$45,$47,$4D,$4F,$41,$43,$41,$43,$51,$53,$00,$00
;20 lineas después



; =============================================
; draw_bg_lines ; Renamed for clarity
; Draws C consecutive horizontal lines of 20 tiles onto the background map.
; INPUT: A = Starting row number (0-17)
;        HL = Pointer to tile data for ALL lines (C * 20 bytes)
;        C = Number of lines to draw
; MODIFIES: AF, BC, DE, HL
; =============================================
draw_bg_line::
    ld b, c             ; B = Number of lines (Outer loop counter)
    ld c, a             ; C = Current row number (starts with A)
    ; HL already points to the start of the source data

.outer_loop:
    push bc             ; Save Outer loop counter (B) and Current row (C)
    push hl             ; Save current Source pointer (HL)

    ; Calculate Destination Address in DE = $9800 + (Current Row * 32)
    ld a, c             ; A = Current row number (C)
    ld l, a
    ld h, 0
    ; Multiply HL by 32
    add hl, hl          ; * 2
    add hl, hl          ; * 4
    add hl, hl          ; * 8
    add hl, hl          ; * 16
    add hl, hl          ; * 32 (Offset)

    ; Add base address
    ld de, $9800 ; $9800 or $9C00
    add hl, de          ; HL = Target VRAM address for this row
    ld d, h             ; DE = Target VRAM address
    ld e, l

    pop hl              ; Restore Source pointer (HL) for this line's data

    ; Copy 20 bytes for the current line
    ld b, 20            ; B = Tiles per line (Inner loop counter)
.copy_loop:
    ld a, [hl+]         ; Read source tile, increment HL
    ld [de], a          ; Write to VRAM
    inc de              ; Increment DE
    dec b
    jr nz, .copy_loop   ; Loop until 20 tiles copied

    ; HL now points to the start of the data for the *next* line

    pop bc              ; Restore Outer loop counter (B) and Original row (C)
    inc c               ; Increment Current row number for next iteration
    dec b               ; Decrement Number of lines remaining
    jr nz, .outer_loop  ; Loop if more lines to draw

    ret


; =============================================
; clear_visible_map
; Fills the visible 20x18 background map area with Tile ID $00.
; MUST be called with the screen OFF and interrupts DISABLED.
; INPUT: None (Assumes map starts at $9800, change if needed)
; MODIFIES: AF, BC, DE, HL
; =============================================
clear_map::
    ld de, $9800  ; DE = Start address of BG Map ($9800 or $9C00)
    ld b, 18              ; B = Number of rows (0-17)
    xor a                 ; A = 0 (Tile ID to fill with)

.row_loop:
    push bc               ; Save outer loop counter (B)
    ld h,d
    ld l,e
    ld b, 20              ; B = Number of columns per row

.col_loop:
    ld [hl+], a           ; Write 0, increment pointer across the row
    dec b
    jr nz, .col_loop      ; Loop until 20 columns are filled

    ; Advance DE to the start of the next row (Current Address + (32 - 20))
    ; HL already points to the 21st tile of the current row after the loop
    ld bc, 32 - 20        ; BC = 12 (Bytes to skip to reach next row start)
    add hl, bc
    ld d, h               ; Update DE for the next iteration of row_loop
    ld e, l

    pop bc                ; Restore outer loop counter (B)
    dec b
    jr nz, .row_loop      ; Loop until 18 rows are filled

    ret