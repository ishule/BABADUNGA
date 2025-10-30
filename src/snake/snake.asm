INCLUDE "snake/snake_consts.inc"

SECTION "Snake Inicialization", ROM0

snake_spawn_definition::
    ; Empty gap
    DB SNAKE_SPAWN_POINT_Y                , SNAKE_ENTER_POINT_X                 , EMPTY_TILE_ID     , SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 0, 0

    ; Head edge
    DB SNAKE_SPAWN_POINT_Y                , SNAKE_ENTER_POINT_X + SPRITE_WIDTH, SNAKE_HEAD_EDGE_TILE_ID     , SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 0, 0

    ; Body 0
    DB SNAKE_SPAWN_POINT_Y + SPRITE_HEIGHT, SNAKE_ENTER_POINT_X                 , SNAKE_BODY_TILE_ID     , SPRITE_ATTR_PRIORITY | SPRITE_ATTR_FLIP_X_MASK; Sprite 0: Columna 1, Fila 1
    DB 5, 0, 11, 8

    ; Body 1
    DB SNAKE_SPAWN_POINT_Y + SPRITE_HEIGHT, SNAKE_ENTER_POINT_X + SPRITE_WIDTH  , SNAKE_BODY_TILE_ID     , SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 5, 0, 11, 8

    ; Head
    DB SNAKE_SPAWN_POINT_Y                , SNAKE_ENTER_POINT_X + SPRITE_WIDTH*2, SNAKE_HEAD_TILE_ID     , SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 16, 8

    ; Mouth
    DB SNAKE_SPAWN_POINT_Y                , SNAKE_ENTER_POINT_X + SPRITE_WIDTH*3, SNAKE_HEAD_TILE_ID + 2 , SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 12, 6

    ; Neck left
    DB SNAKE_SPAWN_POINT_Y + SPRITE_HEIGHT, SNAKE_ENTER_POINT_X + SPRITE_WIDTH*2, SNAKE_IDLE_NECK_TILE_ID     , SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 16, 8

    ; Neck right
    DB SNAKE_SPAWN_POINT_Y + SPRITE_HEIGHT, SNAKE_ENTER_POINT_X + SPRITE_WIDTH*3, SNAKE_IDLE_NECK_TILE_ID + 2, SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 16, 8

    ; Tail
    DB SNAKE_SPAWN_POINT_Y + SPRITE_HEIGHT, SNAKE_ENTER_POINT_X - SPRITE_WIDTH, SNAKE_TAIL_UP_TILE_ID + 2  , SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 0, 0


init_snake::
	call init_snake_tiles

    ld hl, snake_spawn_definition
    ld c, SNAKE_NUM_ENTITIES
    call spawn_group_entity

    ld hl, boss_state
    ld [hl], SNAKE_ENTER_STATE

    ld hl, boss_animation_counter
    ld [hl], SNAKE_WALK_ANIM_TIME

    ld hl, boss_looking_dir
    ld [hl], 0

    ld hl, boss_stage
    ld [hl], 0

    ld hl, boss_dead
    ld [hl], 0

    ld hl, boss_health
    ld [hl], SNAKE_HEALTH

    call rotate_snake

    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld d, SNAKE_NUM_ENTITIES
    ld bc, SPIDER_ENTER_VEL
    call change_entity_group_vel_x

	ret

init_snake_tiles:

    ld hl, snake_tiles
    ld de, VRAM_TILE_DATA_START + (ENEMY_START_TILE_ID * VRAM_TILE_SIZE)
    ld b, 0
    call memcpy_256

    ld b, 218
    call memcpy_256

    ret