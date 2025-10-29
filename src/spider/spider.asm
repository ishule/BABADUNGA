INCLUDE "consts.inc"
INCLUDE "spider/spider_consts.inc"

SECTION "Spider Inicialization", ROM0

; TODO: Definir colisiones bien
spider_spawn_definition::
    DB SPIDER_SPAWN_POINT_Y                , SPIDER_SPAWN_POINT_X                 , ENEMY_START_TILE_ID        , SPRITE_ATTR_PRIORITY_MASK                           ; Sprite 0: Columna 1, Fila 1
    DB 4, 5, 12, 3

    DB SPIDER_SPAWN_POINT_Y                , SPIDER_SPAWN_POINT_X + SPRITE_WIDTH  , ENEMY_START_TILE_ID + 2    , SPRITE_ATTR_PRIORITY_MASK                           ; Sprite 1: Columna 2, Fila 1
    DB 0, 0, 16, 16

    DB SPIDER_SPAWN_POINT_Y + SPRITE_HEIGHT, SPIDER_SPAWN_POINT_X                 , ENEMY_START_TILE_ID + 4    , SPRITE_ATTR_PRIORITY_MASK                           ; Sprite 2: Columna 1, Fila 2
    DB 0, 6, 2, 2

    DB SPIDER_SPAWN_POINT_Y + SPRITE_HEIGHT, SPIDER_SPAWN_POINT_X + SPRITE_WIDTH  , ENEMY_START_TILE_ID + 6    , SPRITE_ATTR_PRIORITY_MASK                           ; Sprite 3: Columna 2, Fila 2
    DB 8, 2, 6, 6

    DB SPIDER_SPAWN_POINT_Y                , SPIDER_SPAWN_POINT_X + SPRITE_WIDTH*3, ENEMY_START_TILE_ID        , SPRITE_ATTR_PRIORITY_MASK | SPRITE_ATTR_FLIP_X_MASK ; Sprite 4: Columna 4, Fila 1
    DB 4, 5, 12, 3

    DB SPIDER_SPAWN_POINT_Y                , SPIDER_SPAWN_POINT_X + SPRITE_WIDTH*2, ENEMY_START_TILE_ID + 2    , SPRITE_ATTR_PRIORITY_MASK | SPRITE_ATTR_FLIP_X_MASK ; Sprite 5: Columna 3, Fila 1
    DB 0, 0, 16, 16

    DB SPIDER_SPAWN_POINT_Y + SPRITE_HEIGHT, SPIDER_SPAWN_POINT_X + SPRITE_WIDTH*3, ENEMY_START_TILE_ID + 4    , SPRITE_ATTR_PRIORITY_MASK | SPRITE_ATTR_FLIP_X_MASK ; Sprite 7: Columna 4, Fila 2
    DB 0, 6, 2, 2

    DB SPIDER_SPAWN_POINT_Y + SPRITE_HEIGHT, SPIDER_SPAWN_POINT_X + SPRITE_WIDTH*2, ENEMY_START_TILE_ID + 6    , SPRITE_ATTR_PRIORITY_MASK | SPRITE_ATTR_FLIP_X_MASK ; Sprite 6: Columna 3, Fila 2
    DB 8, 2, 6, 6

    DB SPIDER_SPAWN_POINT_Y - SPRITE_HEIGHT, SPIDER_SPAWN_POINT_X + SPRITE_WIDTH  , SPIDER_WEB_HOOK_TILE_ID    , SPRITE_ATTR_PRIORITY_MASK                           ; Sprite 8: Columna 2, Fila 0
    DB 0, 0, 0, 0

    DB SPIDER_SPAWN_POINT_Y - SPRITE_HEIGHT, SPIDER_SPAWN_POINT_X + SPRITE_WIDTH*2, SPIDER_WEB_HOOK_TILE_ID + 2,  SPRITE_ATTR_PRIORITY_MASK                          ; Sprite 9: Columna 3, Fila 0
    DB 0, 0, 0, 0

spider_roof_collisions::
    DB 4, 5, 12, 3
    DB 0, 0, 16, 16
    DB 0, 6, 2, 2
    DB 8, 2, 6, 6
    DB 4, 5, 12, 3
    DB 0, 0, 16, 16
    DB 0, 6, 2, 2
    DB 8, 2, 6, 6

spider_stand_collisions:
	; Sprite 0: Columna 1, Fila 1
    DB 13, 3, 3, 5

    ; Sprite 1: Columna 2, Fila 1
    DB 13, 0, 3, 7

    ; Sprite 2: Columna 1, Fila 2
    DB 0, 1, 10, 7

    ; Sprite 3: Columna 2, Fila 2
    DB 0, 0, 10, 8

    ; Sprite 4: Columna 3, Fila 1
    DB 0, 0, 0, 0

    ; Sprite 5: Columna 4, Fila 1
    DB 0, 0, 0, 0

    ; Sprite 6: Columna 3, Fila 2
    DB 1, 0, 7, 8

    ; Sprite 7: Columna 4, Fila 2
    DB 0, 0, 7, 8

spider_jump_collisions:
	; Sprite 0: Columna 1, Fila 1
    DB 13, 3, 3, 5

    ; Sprite 1: Columna 2, Fila 1
    DB 13, 0, 3, 7

    ; Sprite 2: Columna 1, Fila 2
    DB 0, 1, 10, 7

    ; Sprite 3: Columna 2, Fila 2
    DB 0, 0, 16, 8

    ; Sprite 4: Columna 3, Fila 1
    DB 13, 0, 3, 8

    ; Sprite 5: Columna 4, Fila 1
    DB 8, 0, 8, 8

    ; Sprite 6: Columna 3, Fila 2
    DB 0, 0, 7, 8

    ; Sprite 7: Columna 4, Fila 2
    DB 0, 0, 0, 0

init_spider::
	call init_spider_tiles
	call init_spider_variables

	ld hl, spider_spawn_definition
	ld c, SPIDER_ROOF_NUM_ENTITIES
	call spawn_group_entity

    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld bc, ENTER_ANIMATION_SPEED
    ld d, SPIDER_ROOF_NUM_ENTITIES
    call change_entity_group_vel_y

    ld hl, boss_dead
    ld [hl], 0

	ret

init_spider_variables:

	ld hl, spider_shot_cooldown
	ld [hl], SPIDER_ROOF_STATE_SHOT_COOLDOWN

	ld hl, boss_animation_counter
	ld [hl], SPIDER_ROOF_STATE_WALK_ANIM_TIME

    ld hl, boss_health
    ld [hl], SPIDER_HEALTH

    ld hl, damaged_times
    ld [hl], DAMAGED_TIMES_TO_FALL

    ld hl, boss_state
    ld [hl], SPIDER_ENTER_STATE

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
