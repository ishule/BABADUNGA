INCLUDE "consts.inc"

SECTION "Gorilla Variables", WRAM0 
gorilla_orientation:: DS 1	; 0 = derecha, 1 = izquierda

SECTION "Gorilla Code", ROM0

gorilla_sprites::
    DB $00, $00, $10, %10000000   ; Sprite 0: Columna 1, Fila 1
    DB $00, $00, $12, %10000000   ; Sprite 1: Columna 2, Fila 1
    DB $00, $00, $18, %10000000   ; Sprite 4: Columna 1, Fila 2
    DB $00, $00, $1A, %10000000   ; Sprite 5: Columna 2, Fila 2
    DB $00, $00, $14, %10000000   ; Sprite 2: Columna 3, Fila 1
    DB $00, $00, $16, %10000000   ; Sprite 3: Columna 4, Fila 1

    DB $00, $00, $1C, %10000000   ; Sprite 6: Columna 3, Fila 2
    DB $00, $00, $1E, %10000000   ; Sprite 7: Columna 4, Fila 2


;;============================================================
;; init_gorilla 
;; Inicialización completa del gorila
;;
;; MODIFICA: A, BC, DE, HL
init_gorilla::
	call init_gorilla_tiles
	call init_gorilla_entity
	call gorilla_init_physics
	ret

;;============================================================
;; init_gorilla_tiles
;; Carga los gráficos del gorila en VRAM
;;
;; Tiles cargados: $10-$1F (16 tiles para 8 sprites 8x16)
;;
;; MODIFICA: A, BC, DE, HL
init_gorilla_tiles::
	call wait_vblank
	
	; Primer cuarto: tiles $10-$13 (4 tiles = 64 bytes)
	ld hl, Gorilla
	ld de, VRAM_TILE_DATA_START + ($10 * VRAM_TILE_SIZE)
	ld b, 4 * VRAM_TILE_SIZE
	call memcpy_256

	call wait_vblank
	; Primera mitad: tiles $14-$17 (4 tiles = 64 bytes)
	ld hl, Gorilla + (4 * VRAM_TILE_SIZE)
	ld de, VRAM_TILE_DATA_START + ($14 * VRAM_TILE_SIZE)
	ld b, 4 * VRAM_TILE_SIZE
	call memcpy_256
	
	call wait_vblank
	; Segunda mitad: tiles $18-$1B (4 tiles = 64 bytes)
	ld hl, Gorilla + (8 * VRAM_TILE_SIZE)
	ld de, VRAM_TILE_DATA_START + ($18 * VRAM_TILE_SIZE)
	ld b, 4 * VRAM_TILE_SIZE
	call memcpy_256

	call wait_vblank
	; Primera mitad: tiles $1C-$1E (4 tiles = 64 bytes)
	ld hl, Gorilla + (12 * VRAM_TILE_SIZE)
	ld de, VRAM_TILE_DATA_START + ($1C * VRAM_TILE_SIZE)
	ld b, 4 * VRAM_TILE_SIZE
	call memcpy_256
	
	ret

;;============================================================
;; init_gorilla_entity
;; Crea las entidades de sprites del gorila en OAM
;;
;; Reserva 8 sprites para formar 32x32 con sprites 8x16
;;
;; MODIFICA: A, BC, DE, HL
init_gorilla_entity::
	; Alocar sprite 0
	call man_entity_alloc
	inc h
	ld d, h 
	ld e, l 
	ld hl, gorilla_sprites
	ld b, SPRITE_SIZE
	call memcpy_256
	
	; Alocar sprite 1
	call man_entity_alloc
	inc h
	ld d, h 
	ld e, l 
	ld hl, gorilla_sprites + 4
	ld b, SPRITE_SIZE
	call memcpy_256
	
	; Alocar sprite 2
	call man_entity_alloc
	inc h
	ld d, h 
	ld e, l 
	ld hl, gorilla_sprites + 8
	ld b, SPRITE_SIZE
	call memcpy_256
	
	; Alocar sprite 3
	call man_entity_alloc
	inc h
	ld d, h 
	ld e, l 
	ld hl, gorilla_sprites + 12
	ld b, SPRITE_SIZE
	call memcpy_256
	
	; Alocar sprite 4
	call man_entity_alloc
	inc h
	ld d, h 
	ld e, l 
	ld hl, gorilla_sprites + 16
	ld b, SPRITE_SIZE
	call memcpy_256
	
	; Alocar sprite 5
	call man_entity_alloc
	inc h
	ld d, h 
	ld e, l 
	ld hl, gorilla_sprites + 20
	ld b, SPRITE_SIZE
	call memcpy_256
	
	; Alocar sprite 6
	call man_entity_alloc
	inc h
	ld d, h 
	ld e, l 
	ld hl, gorilla_sprites + 24
	ld b, SPRITE_SIZE
	call memcpy_256
	
	; Alocar sprite 7
	call man_entity_alloc
	inc h
	ld d, h 
	ld e, l 
	ld hl, gorilla_sprites + 28
	ld b, SPRITE_SIZE
	call memcpy_256
	
	call wait_vblank
	call man_entity_draw
	ret

;;=================================================
;; gorilla_init_physics
;; Inicializa el componente de las físicas del gorila
;;
;; Establece:
;; 		- Posición inicial (visible en pantalla)
;; 		- Velocidad inicial: 0, 0 
;;
;; MODIFICA: A, BC, DE
gorilla_init_physics:: 
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	push hl
	
	;; Gorilla INFO 
	ld b, GORILLA_SPRITES_SIZE 
	.info_loop:
		ld a, BYTE_ACTIVE
		ld [hl+], a 		; Active = 1

		ld a, TYPE_BOSS
		ld [hl+], a 	 	; Type = 1

		ld a, [hl]                     ; carga el byte actual
	    or FLAG_CAN_TAKE_DAMAGE | FLAG_CAN_DEAL_DAMAGE
	    ld [hl+], a                     ; guarda el nuevo valor
	    inc l 
	    dec b 
	    jr nz, .info_loop 


	pop hl 
	push hl

	ld b, GROUND_Y - 16	; Y = suelo menos altura del gorila (32 píxeles)
	ld c, $40				
	call change_entity_group_pos_32x32

	;; ASIGNAR WIDTH Y HEIGHT
	ld b, GORILLA_SPRITES_SIZE
	pop hl
	ld h, CMP_COLLISIONS
	inc l
	inc l
	.loop:
   	ld a, GORILLA_HEIGHT 
	ld [hl+], a 

	ld a, GORILLA_WIDTH 
	ld [hl+], a
	inc l
	inc l
	dec b 
	jr nz, .loop
	
	ret