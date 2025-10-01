INCLUDE "consts.inc"
SECTION "Utils",ROM0

wait_vblank::
	ld hl,rLY
	ld a,VBLANK_START
	.loop:
		cp [hl]
	jr nz,.loop
	ret
;; memcpy_256: Subrutina para copiar bytes a memoria(Ejemplo tiles a VRAM)
;; INPUT
;; hl: Source
;; de: Destination
;; b: bytes
memcpy_256::
		ld a,[hl+]
		ld [de],a
		inc de
		dec b
	jr nz,memcpy_256
	ret
;; draw_map: Draws a map on the screen
;; hl: Puntero a tilemap
draw_map::
	ld de,$9800 ; Destination: VRAM Tile Map 0
	ld b,18  ; B: Altura (18 rows)
		
	.loopRow:
		; NO necesitas PUSH BC aquí, ya que solo usas B como contador.
		ld c,20  ; C: Anchura (20 columns)

	.loopCol:
		ld a,[hl+] ; Load tile index from source (HL), advance HL
		ld [de],a ; Write tile index to VRAM (DE)
		inc de; Advance VRAM pointer
		
		dec c
		jr nz,.loopCol ; Loop until 20 columns are done

		;; Ajustamos VRAM: Sumamos 12 bytes (32 - 20)
		;; Usamos A y H para la suma.
	    ld a, 12
	    add a, e    ; Suma 12 al byte bajo (E)
	    ld e, a
	    jr nc, .no_carry ; Si no hay acarreo, salta
	    inc d       ; Si hay acarreo, incrementa el byte alto (D)
	.no_carry:

		; pop bc ya no es necesario.
		dec b
		jr nz,.loopRow ; Loop back for the next row

		ret; Exit the subroutine


turn_screen_off::
   ld a,[LCD_CONTROL]
   and %01111111
   ld [LCD_CONTROL],a
   ret
turn_screen_on::
   ld a,[LCD_CONTROL]
   or %10000000
   ld [LCD_CONTROL],a
   ret

