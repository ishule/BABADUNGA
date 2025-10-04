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

;; Apaga la pantalla del Game Boy
;; LCD_CONTROL ($FF40) bit 7 = LCD Display Enable
turn_screen_off::
   ld a,[LCD_CONTROL]
   and %01111111
   ld [LCD_CONTROL],a
   ret

;; Enciende la pantalla del Game Boy
;; LCD_CONTROL ($FF40) bit 7 = LCD Display Enable
turn_screen_on::
   ld a,[LCD_CONTROL]
   or %10000000
   ld [LCD_CONTROL],a
   ret

init_all_sprites::
	call set_palette_sprites_0
	call wait_vblank
	call init_OAM
	call init_LCDC_sprites
	ret

;; Configura la paleta de sprites 0
;; rOBP0: registro de paleta de sprites
set_palette_sprites_0::
   ld hl, rOBP0
   ld [hl], %11100001
   ret

;; Inicializa la memoria de sprites (OAM)
init_OAM:
	ld hl, OAM_START
	ld b, OAM_TOTAL_SPRITES
	xor a 
	call memset_256
	ret

;; Configura LCDC para sprites
init_LCDC_sprites::
	ld hl, LCD_CONTROL
	set 1, [hl]	;; Enable Objects
	set 2, [hl]	;; Enable 8 x 16 sprites
	ret

;; INPUT
;;		HL: Destination
;;		B: bytes
;;		A: value to set
;;	Escribe en hl el valor a hasta que b sea cero
memset_256::
	ld [hl+], a
	dec b 
	jr nz, memset_256
	ret

;;Abre la puerta para avanzar al siguiente nivel
open_door::
	call wait_vblank
	ld a,0
	ld [$9A13],a
	ld [$99F3],a

