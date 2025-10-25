INCLUDE "gorilla_consts.inc"

SECTION "Gorilla Initialization", ROM0

gorilla_entity_data::
    DB GORILLA_SPAWN_POINT_Y                , GORILLA_SPAWN_POINT_X                 , ENEMY_START_TILE_ID     , SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 11, 3, 5, 5

    DB GORILLA_SPAWN_POINT_Y                , GORILLA_SPAWN_POINT_X + SPRITE_WIDTH  , ENEMY_START_TILE_ID + 2 , SPRITE_ATTR_PRIORITY   ; Sprite 1: Columna 2, Fila 1
    DB 4, 0, 12, 8

    DB GORILLA_SPAWN_POINT_Y + SPRITE_HEIGHT, GORILLA_SPAWN_POINT_X                 , ENEMY_START_TILE_ID + 4 , SPRITE_ATTR_PRIORITY   ; Sprite 2: Columna 1, Fila 2
    DB 0, 2, 16, 6

    DB GORILLA_SPAWN_POINT_Y + SPRITE_HEIGHT, GORILLA_SPAWN_POINT_X + SPRITE_WIDTH  , ENEMY_START_TILE_ID + 6 , SPRITE_ATTR_PRIORITY   ; Sprite 3: Columna 2, Fila 2
    DB 0, 0, 16, 8

    DB GORILLA_SPAWN_POINT_Y                , GORILLA_SPAWN_POINT_X + SPRITE_WIDTH*2, ENEMY_START_TILE_ID + 8 , SPRITE_ATTR_PRIORITY   ; Sprite 4: Columna 3, Fila 1
    DB 3, 0, 13, 8

    DB GORILLA_SPAWN_POINT_Y                , GORILLA_SPAWN_POINT_X + SPRITE_WIDTH*3, ENEMY_START_TILE_ID + 10, SPRITE_ATTR_PRIORITY   ; Sprite 5: Columna 4, Fila 1
    DB 11, 0, 3, 1

    DB GORILLA_SPAWN_POINT_Y + SPRITE_HEIGHT, GORILLA_SPAWN_POINT_X + SPRITE_WIDTH*2, ENEMY_START_TILE_ID + 12, SPRITE_ATTR_PRIORITY   ; Sprite 6: Columna 3, Fila 2
    DB 0, 0, 16, 6

    DB GORILLA_SPAWN_POINT_Y + SPRITE_HEIGHT, GORILLA_SPAWN_POINT_X + SPRITE_WIDTH*3, ENEMY_START_TILE_ID + 14, SPRITE_ATTR_PRIORITY   ; Sprite 7: Columna 4, Fila 2
    DB 0, 0, 0, 0

;;============================================================
;; init_gorilla 
;; Inicialización completa del gorila
;;
;; MODIFICA: A, BC, DE, HL
init_gorilla::
	call init_gorilla_tiles

	ld hl, gorilla_entity_data
	ld c, GORILLA_NUM_ENTITIES
	call spawn_group_entity
	
	call gorilla_init_info

	ld hl, gorilla_state
	ld [hl], 0

	ld hl, gorilla_stage
	ld [hl], 0


	ld hl, gorilla_state_counter
	ld [hl], STAND_TIME

	; Looking left
	ld hl, gorilla_looking_dir
	ld [hl], 1

	call rotate_gorilla_x

	ret

;;============================================================
;; init_gorilla_tiles
;; Carga los gráficos del gorila en VRAM
;;
;; Tiles cargados: $10-$1F (16 tiles para 8 sprites 8x16)
;;
;; MODIFICA: A, BC, DE, HL
init_gorilla_tiles::
	call turn_screen_off
	
	ld hl, gorilla
	ld de, VRAM_TILE_DATA_START + (ENEMY_START_TILE_ID * VRAM_TILE_SIZE)
	ld b, 0
	call memcpy_256
	
	;; Animación
	ld b, 0
	call memcpy_256

	;; Golpe
	ld b, 0
	call memcpy_256

	;; Piedras
	ld b, 208
	call memcpy_256

	call turn_screen_on
	ret


;;=================================================
;; gorilla_init_info
;; Inicializa el componente de las físicas del gorila
;;
;; Establece:
;; 		- Posición inicial (visible en pantalla)
;; 		- Velocidad inicial: 0, 0 
;;
;; MODIFICA: A, BC, DE
gorilla_init_info:: 
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	
	;; Gorilla INFO 
	ld b, GORILLA_NUM_ENTITIES
	.info_loop:
		ld a, BYTE_ACTIVE
		ld [hl+], a 		; Active = 1

		ld a, TYPE_BOSS
		ld [hl+], a 	 	; Type = 1

		ld a, [hl]                     ; carga el byte actual
	    or FLAG_CAN_TAKE_DAMAGE | FLAG_CAN_DEAL_DAMAGE
	    ld [hl+], a                     ; guarda el nuevo valor

	   	ld a, GORILLA_NUM_ENTITIES
	    ld [hl+], a 	; Número sprites

	    dec b 
	    jr nz, .info_loop 
	
	ret

