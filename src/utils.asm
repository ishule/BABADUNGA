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

wait_not_vblank::
    ld hl, rLY          ; HL = Address of LY register ($FF44)
    ld a, VBLANK_START  ; A = VBLANK start line (usually 144 / $90)
.loop:
    cp [hl]             ; Compare A with the value at [HL]
    jr z, .loop         ; If equal (still in VBLANK range start), keep checking
    ret                 ; Return when not equal (outside VBLANK range)

; Waits for a specific number of VBLANK periods (frames)
; In this case, waits for 4 VBLANKs.
; MODIFIES: B
wait_time_vblank::
    ld b, 12             ; Initialize counter B to 4
.wait_loop:
    call wait_vblank    ; Wait for the start of one VBLANK period
    dec b               ; Decrement counter
    jr nz, .wait_loop   ; If counter is not zero, loop again
    ret                 ; Return after 4 VBLANKs have passed


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
	ld[hl], %01010101
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

;; Abre la puerta DERECHA con animación ascendente (CORREGIDO)
open_door::
    ; 1. Find the first gate entity
    ld a, TYPE_VERJA
    call man_entity_locate_first_type
    ret c ; Exit if no gate found (Carry set)

    ; 2. Calculate the ID of the first gate sprite
    ld a, l ; Get the offset L
    srl a   ; A = L / 2
    srl a   ; A = L / 4 = ID of the first (left) gate sprite

    ; 3. Calculate the ID of the second (right) gate sprite
    inc a   ; A = ID_Left + 1 = ID_Right
    push af ; Save the ID of the right gate for later deactivation

    ; 4. Locate the second gate entity's SPRITE component
    call man_entity_locate_v2 ; HL = Address of right gate's Info ($C0xx + L')
    inc h                     ; HL = Address of right gate's Sprite ($C1xx + L')
    ld d, h                   ; Store Sprite component address in DE
    ld e, l                   ; DE now points to the Y coordinate byte

    ; --- 5. Animation Loop: Move Up 16 Pixels (1 pixel per frame) ---
    ld c, 16                  ; C = Number of pixels to move up
.anim_loop:
    ; *** CORRECCIÓN: Esperar UN VBLANK por cada píxel ***
    call wait_time_vblank
    ; Read current Y, decrement, write back
    ld a, [de]                ; Read current Y from Sprite Component
    dec a                     ; Move up 1 pixel
    ld [de], a                ; Write new Y back

    push bc
    call man_entity_draw
    pop bc
    ; *** DIBUJAR INMEDIATAMENTE PARA VER EL CAMBIO (Opcional pero recomendado) ***
    ; Si tu man_entity_draw es rápido, puedes llamarlo aquí para actualizar OAM
    ; Si no, el cambio se verá en el siguiente wait_vblank del bucle principal
    ; call man_entity_draw ; (Opcional)
    call sys_sound_door_opening_scrape
    dec c
    jr nz, .anim_loop         ; Loop until moved 16 pixels

    ; --- 6. Deactivate the entity AFTER animation ---
    pop af                    ; Restore the ID of the right gate into A
    call man_entity_locate_v2 ; HL = Address of right gate's Info ($C0xx + L')
    xor a                     ; A = 0 (Inactive value)
    ld [hl], a                ; Set ACTIVE flag to 0
    call sys_sound_door_opened_clink
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