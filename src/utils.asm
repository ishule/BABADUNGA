INCLUDE "consts.inc"
SECTION "Utils",ROM0

clean_all_tiles::
    xor a             ; Valor a escribir (0)
    ld hl, $8000      ; Inicio de VRAM
    ld c, 12          ; Vamos a limpiar 32 bloques de 256 bytes (8 KB total)
.loop:
    ld b, 0           ; Código para limpiar 256 bytes con memset_256
    call memset_256   ; Limpia un bloque de 256 bytes (HL se incrementa)
    dec c             ; Un bloque menos
    jr nz, .loop      ; Repetir hasta limpiar los 32 bloques
    ret

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

;; memcut_256:  ¡¡ADVERTENCIA!! : Solo sirve para cuando h no cambia al ir incrementando
;; INPUT 
;; hl: Source
;; de: Destination
;; b: bytes
memcut_256::
		ld a,[hl]
		ld [hl], $00
		inc l
		ld [de],a
		inc de
		dec b
	jr nz,memcut_256
	ret


;; draw_map: Draws a map on the screen
;; hl: Puntero a tilemap
draw_map::
	ld de,$9800 ; Destination: VRAM Tile Map 0
	ld b,18  ; B: Altura (18 rows)
		
	.loopRow:
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
		dec b
		jr nz,.loopRow ; Loop back for the next row

		ret; Exit the subroutine

;; Apaga la pantalla del Game Boy
;; LCD_CONTROL ($FF40) bit 7 = LCD Display Enable
turn_screen_off::
	di
	call wait_vblank
   ld hl, LCD_CONTROL
   res 7, [hl]
   ei
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
	call set_palette_sprites_1
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

set_palette_sprites_1::
	ld hl, rOBP1
	ld[hl], %11100100
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

;; INPUT
;;		HL: Destination
;;		B: bytes
;;	Escribe en hl 0 hasta que b sea cero
memreset_256::
	ld [hl], $00
	inc hl
	dec b 
	jr nz, memreset_256
	ret

;;Abre la puerta para avanzar al siguiente nivel
open_door::
	call wait_vblank
	xor a
	ld [$99B3],a
	ld [$99D3],a
	ld a,0
	ld [$9A13],a
	ld [$99F3],a
	ret
;; Función que hace que se inicialize el sonido para que se pueda escuchar básicamente
init_sound::
	ld hl,$FF10
	ld b,20 ;; 20 Direcciones que hay que poner a 0
	xor a
	;; Se inicializa de $FF10 a $FF23
	.loop:
		ld [hl+],a
		dec b
		jr nz,.loop
	;; Ahora los registros NR50 y NR51 si ponen a $FF. NR52 ponesmo el bit 7 a uno para producir audio
	ld a,$FF
	ld[hl+],a
	ld[hl+],a
	ld a,[hl]
	or %10000000
	ld [hl],a
	ret

; INPUT
;  BC -> positive number
;
; RETURN
;  BC -> BC x (-1)
;
; MODIFIES: A
positive_to_negative_BC::
	ld a, b
	cpl
	ld b, a

	ld a, c
	cpl
	ld c, a

	inc bc

	ret

; INPUT
;  DE -> positive number
;
; RETURN
;  DE -> DE x (-1)
;
; MODIFIES: A
positive_to_negative_DE::
	ld a, d
	cpl
	ld d, a

	ld a, e
	cpl
	ld e, a

	inc de

	ret