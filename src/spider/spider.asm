INCLUDE "consts.inc"
INCLUDE "spider/spider_consts.inc"

SECTION "Spider Inicialization", ROM0

; TODO: Definir colisiones bien
spider_spawn_definition::
    DB SPIDER_SPAWN_POINT_Y                , SPIDER_SPAWN_POINT_X                 , ENEMY_START_TILE_ID     , SPRITE_ATTR_PRIORITY_MASK  ; Sprite 0: Columna 1, Fila 1
    DB 11, 3, 5, 5

    DB SPIDER_SPAWN_POINT_Y                , SPIDER_SPAWN_POINT_X + SPRITE_WIDTH  , ENEMY_START_TILE_ID + 2 , SPRITE_ATTR_PRIORITY_MASK   ; Sprite 1: Columna 2, Fila 1
    DB 4, 0, 12, 8

    DB SPIDER_SPAWN_POINT_Y + SPRITE_HEIGHT, SPIDER_SPAWN_POINT_X                 , ENEMY_START_TILE_ID + 4 , SPRITE_ATTR_PRIORITY_MASK   ; Sprite 2: Columna 1, Fila 2
    DB 0, 2, 16, 6

    DB SPIDER_SPAWN_POINT_Y + SPRITE_HEIGHT, SPIDER_SPAWN_POINT_X + SPRITE_WIDTH  , ENEMY_START_TILE_ID + 6 , SPRITE_ATTR_PRIORITY_MASK   ; Sprite 3: Columna 2, Fila 2
    DB 0, 0, 16, 8

    DB SPIDER_SPAWN_POINT_Y                , SPIDER_SPAWN_POINT_X + SPRITE_WIDTH*2, ENEMY_START_TILE_ID + 2 , SPRITE_ATTR_PRIORITY_MASK | SPRITE_ATTR_FLIP_X_MASK   ; Sprite 4: Columna 3, Fila 1
    DB 3, 0, 13, 8

    DB SPIDER_SPAWN_POINT_Y                , SPIDER_SPAWN_POINT_X + SPRITE_WIDTH*3, ENEMY_START_TILE_ID + 0,  SPRITE_ATTR_PRIORITY_MASK | SPRITE_ATTR_FLIP_X_MASK   ; Sprite 5: Columna 4, Fila 1
    DB 11, 0, 3, 1

    DB SPIDER_SPAWN_POINT_Y + SPRITE_HEIGHT, SPIDER_SPAWN_POINT_X + SPRITE_WIDTH*2, ENEMY_START_TILE_ID + 6,  SPRITE_ATTR_PRIORITY_MASK | SPRITE_ATTR_FLIP_X_MASK   ; Sprite 6: Columna 3, Fila 2
    DB 0, 0, 16, 6

    DB SPIDER_SPAWN_POINT_Y + SPRITE_HEIGHT, SPIDER_SPAWN_POINT_X + SPRITE_WIDTH*3, ENEMY_START_TILE_ID + 4,  SPRITE_ATTR_PRIORITY_MASK | SPRITE_ATTR_FLIP_X_MASK   ; Sprite 7: Columna 4, Fila 2
    DB 0, 0, 0, 0

    ; TODO: Definir bien la telaraña
    DB SPIDER_SPAWN_POINT_Y + SPRITE_HEIGHT, SPIDER_SPAWN_POINT_X + SPRITE_WIDTH*2, ENEMY_START_TILE_ID + 6,  SPRITE_ATTR_PRIORITY_MASK | SPRITE_ATTR_FLIP_X_MASK   ; Sprite 6: Columna 3, Fila 2
    DB 0, 0, 16, 6

    DB SPIDER_SPAWN_POINT_Y + SPRITE_HEIGHT, SPIDER_SPAWN_POINT_X + SPRITE_WIDTH*3, ENEMY_START_TILE_ID + 4,  SPRITE_ATTR_PRIORITY_MASK | SPRITE_ATTR_FLIP_X_MASK   ; Sprite 7: Columna 4, Fila 2
    DB 0, 0, 0, 0

init_spider::
	call init_spider_tiles
	
	ld hl, spider_spawn_definition
	ld c, SPIDER_ROOF_NUM_ENTITIES
	call spawn_group_entity

	ld hl, spider_state
	ld [hl], SPIDER_ROOF_STATE

	ld hl, spider_shot_cooldown
	ld [hl], SPIDER_ROOF_STATE_SHOT_COOLDOWN

	ld hl, spider_animation_counter
	ld [hl], SPIDER_ROOF_STATE_WALK_ANIM_TIME

	ld hl, spider_stage
	ld [hl], $00

	ret

init_spider_tiles:
	call turn_screen_off

	; Load roof stage tiles
	ld hl, spider_roof
	ld de, VRAM_TILE_DATA_START + (ENEMY_START_TILE_ID * VRAM_TILE_SIZE)
	ld b, 0
	call memcpy_256

	; Load ground stage tiles
	ld hl, spider_ground_base
	ld b, 0
	call memcpy_256

	; Load jump stage tiles
	ld hl, spider_ground_jump
	ld b, 0
	call memcpy_256

	; Load web props
	ld hl, spider_web_props
	ld b, 0
	call memcpy_256

	call turn_screen_on

	ret
