INCLUDE "gorilla/gorilla_consts.inc"

SECTION "Gorilla Initialization", ROM0

scenario_stalactites_spawn_definition:
	; ===== GROUP 1 =====
	DB 5 + ROOF_Y_POS + 18, WALL_LEFT_X + 3 , STALACTITE_0_START_TILE_ID, 0 ; Stalactite 1
	DL STALACTITE_0_COLLISIONS

	DB 5 + ROOF_Y_POS + 5, WALL_LEFT_X + 30, STALACTITE_2_START_TILE_ID, 0; Stalactite 4
	DL STALACTITE_2_COLLISIONS

	DB 5 + ROOF_Y_POS - 3, WALL_LEFT_X + 56, STALACTITE_0_START_TILE_ID, 0; Stalactite 7
	DL STALACTITE_0_COLLISIONS

	DB 5 + ROOF_Y_POS    , WALL_LEFT_X + 95, STALACTITE_3_START_TILE_ID, 0; Stalactite 10
	DL STALACTITE_3_COLLISIONS

	DB 5 + ROOF_Y_POS + 14, WALL_LEFT_X + 120, STALACTITE_3_START_TILE_ID, 0; Stalactite 13
	DL STALACTITE_3_COLLISIONS

	; ===== GROUP 2 =====
	DB 5 + ROOF_Y_POS + 15, WALL_LEFT_X + 9 , STALACTITE_2_START_TILE_ID, 0; Stalactite 2
	DL STALACTITE_2_COLLISIONS

	DB 5 + ROOF_Y_POS + 2 , WALL_LEFT_X + 43, STALACTITE_3_START_TILE_ID, 0; Stalactite 5
	DL STALACTITE_3_COLLISIONS

	DB 5 + ROOF_Y_POS - 5, WALL_LEFT_X + 70, STALACTITE_1_START_TILE_ID, 0; Stalactite 8
	DL STALACTITE_1_COLLISIONS

	DB 5 + ROOF_Y_POS + 5, WALL_LEFT_X + 102, STALACTITE_2_START_TILE_ID, 0; Stalactite 11
	DL STALACTITE_2_COLLISIONS

	DB 5 + ROOF_Y_POS + 16, WALL_LEFT_X + 128 , STALACTITE_0_START_TILE_ID, 0; Stalactite 14
	DL STALACTITE_0_COLLISIONS


	; ===== GROUP 3 =====
	DB 5 + ROOF_Y_POS     , WALL_LEFT_X + 49, STALACTITE_1_START_TILE_ID, 0; Stalactite 6
	DL STALACTITE_1_COLLISIONS

	DB 5 + ROOF_Y_POS + 12, WALL_LEFT_X + 16, STALACTITE_1_START_TILE_ID, 0; Stalactite 3
	DL STALACTITE_1_COLLISIONS

	DB 5 + ROOF_Y_POS - 3, WALL_LEFT_X + 82, STALACTITE_2_START_TILE_ID, 0; Stalactite 9
	DL STALACTITE_2_COLLISIONS

	DB 5 + ROOF_Y_POS + 7, WALL_LEFT_X + 110, STALACTITE_0_START_TILE_ID, 0; Stalactite 12
	DL STALACTITE_0_COLLISIONS

	DB 5 + ROOF_Y_POS + 19, WALL_LEFT_X + 136, STALACTITE_1_START_TILE_ID, 0; Stalactite 15
	DL STALACTITE_1_COLLISIONS

gorilla_spawn_definition::
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

gorilla_stand_collisions::
    ; Sprite 0: Columna 1, Fila 1
    DB 11, 3, 5, 5

    ; Sprite 1: Columna 2, Fila 1
    DB 4, 0, 12, 8

    ; Sprite 2: Columna 1, Fila 2
    DB 0, 2, 16, 6

    ; Sprite 3: Columna 2, Fila 2
    DB 0, 0, 16, 8

    ; Sprite 4: Columna 3, Fila 1
    DB 3, 0, 13, 8

    ; Sprite 5: Columna 4, Fila 1
    DB 11, 0, 3, 1

    ; Sprite 6: Columna 3, Fila 2
    DB 0, 0, 16, 6

    ; Sprite 7: Columna 4, Fila 2
    DB 0, 0, 0, 0

gorilla_jump_collisions::
    ; Sprite 0: Columna 1, Fila 1
    DB 3, 4, 5, 10

    ; Sprite 1: Columna 2, Fila 1
    DB 0, 0, 16, 8

    ; Sprite 2: Columna 1, Fila 2
    DB 0, 2, 14, 6

    ; Sprite 3: Columna 2, Fila 2
    DB 0, 0, 16, 8

    ; Sprite 4: Columna 3, Fila 1
    DB 4, 0, 12, 8

    ; Sprite 5: Columna 4, Fila 1
    DB 0, 0, 16, 8

    ; Sprite 6: Columna 3, Fila 2
    DB 0, 0, 6, 8

    ; Sprite 7: Columna 4, Fila 2
    DB 0, 0, 2, 4

gorilla_up_strike_collisions::
    ; Sprite 0: Columna 1, Fila 1
    DB 1, 3, 13, 5

    ; Sprite 1: Columna 2, Fila 1
    DB 0, 0, 16, 8

    ; Sprite 2: Columna 1, Fila 2
    DB 0, 4, 2, 4

    ; Sprite 3: Columna 2, Fila 2
    DB 0, 0, 16, 8

    ; Sprite 4: Columna 4, Fila 1
    DB 1, 3, 13, 5

    ; Sprite 5: Columna 3, Fila 1
    DB 0, 0, 16, 8

    ; Sprite 6: Columna 4, Fila 2
    DB 0, 4, 2, 4

    ; Sprite 7: Columna 3, Fila 2
    DB 0, 0, 16, 8

gorilla_down_strike_collisions::
    ; Sprite 0: Columna 1, Fila 1
    DB 11, 2, 5, 6

    ; Sprite 1: Columna 2, Fila 1
    DB 3, 0, 13, 8

    ; Sprite 2: Columna 1, Fila 2
    DB 0, 0, 16, 6

    ; Sprite 3: Columna 2, Fila 2
    DB 0, 0, 16, 8

    ; Sprite 4: Columna 4, Fila 1
    DB 11, 2, 5, 6

    ; Sprite 5: Columna 3, Fila 1
    DB 3, 0, 13, 8

    ; Sprite 6: Columna 4, Fila 2
    DB 0, 0, 16, 6

    ; Sprite 7: Columna 3, Fila 2
    DB 0, 0, 16, 8

;;============================================================
;; init_gorilla 
;; Inicialización completa del gorila
;;
;; MODIFICA: A, BC, DE, HL
init_gorilla::
	call init_gorilla_tiles

	ld hl, gorilla_spawn_definition
	ld c, GORILLA_NUM_ENTITIES
	call spawn_group_entity
	
	ld hl, boss_dead
	ld [hl], 0

	ld hl, boss_state
	ld [hl], 0

	ld hl, boss_stage
	ld [hl], 0

	ld hl, boss_looking_dir
	ld [hl], 0

	ld hl, boss_state_counter
	ld [hl], STAND_TIME

	ld c, GORILLA_NUM_ENTITIES
	call rotate_boss_x

	; Init life
	ld hl, boss_health
	ld [hl], GORILLA_LIFE

	

	; Enter jump
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld a, GORILLA_NUM_ENTITIES
	ld bc, ENTER_JUMP_SPEED_Y
	ld de, ENTER_JUMP_SPEED_X
	call change_entity_group_vel

	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld d, GORILLA_NUM_ENTITIES
	ld bc, ENTER_GRAVITY
	call change_entity_group_acc_y

	ld b, SWAP_MASK_SPRITE_STAND_JUMP
    ld c, GORILLA_NUM_ENTITIES
    ld a, ENEMY_START_ENTITY_ID
    call swap_sprite_by_mask

	ret


init_stalactites::
	ld hl, scenario_stalactites_spawn_definition
	ld c, NUMBER_OF_SCENARIO_STALACTITES
	call spawn_group_entity
	call init_stalactite_flags
	ret

init_stalactite_flags:
	ld a, STALACTITES_START_ENTITY_ID
	call man_entity_locate_v2
	ld c, NUMBER_OF_SCENARIO_STALACTITES

	.loop:
	ld [hl], BYTE_ACTIVE
	inc l
	ld [hl], TYPE_BULLET
	inc l
	ld [hl], FLAG_CAN_DEAL_DAMAGE | FLAG_DESTROY_ON_HIT | FLAG_STILL_BULLET
	inc l
	inc h
	inc h
	ld [hl], STALACTITE_DAMAGE
	dec h
	dec h
	inc l

	dec c
	jr nz, .loop

	ret


;;============================================================
;; init_gorilla_tiles
;; Carga los gráficos del gorila en VRAM
;;
;; Tiles cargados: $10-$1F (16 tiles para 8 sprites 8x16)
;;
;; MODIFICA: A, BC, DE, HL
init_gorilla_tiles::
	
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
	ld b, 144
	call memcpy_256

	ret




