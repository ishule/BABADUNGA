INCLUDE "snake/snake_consts.inc"

SECTION "Snake Inicialization", ROM0

snake_spawn_definition::
    DB SNAKE_SPAWN_POINT_Y                , SNAKE_SPAWN_POINT_X                 , EMPTY_TILE_ID     , SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 0, 0

    DB SNAKE_SPAWN_POINT_Y                , SNAKE_SPAWN_POINT_X + SPRITE_WIDTH, SNAKE_HEAD_EDGE_TILE_ID     , SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 0, 0

    DB SNAKE_SPAWN_POINT_Y + SPRITE_HEIGHT, SNAKE_SPAWN_POINT_X                 , SNAKE_BODY_TILE_ID     , SPRITE_ATTR_PRIORITY | SPRITE_ATTR_FLIP_X_MASK; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 0, 0

    DB SNAKE_SPAWN_POINT_Y + SPRITE_HEIGHT, SNAKE_SPAWN_POINT_X + SPRITE_WIDTH  , SNAKE_BODY_TILE_ID     , SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 0, 0

    DB SNAKE_SPAWN_POINT_Y                , SNAKE_SPAWN_POINT_X + SPRITE_WIDTH*2, SNAKE_HEAD_TILE_ID     , SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 0, 0

    DB SNAKE_SPAWN_POINT_Y                , SNAKE_SPAWN_POINT_X + SPRITE_WIDTH*3, SNAKE_HEAD_TILE_ID + 2 , SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 0, 0

    DB SNAKE_SPAWN_POINT_Y + SPRITE_HEIGHT, SNAKE_SPAWN_POINT_X + SPRITE_WIDTH*2, SNAKE_IDLE_NECK_TILE_ID     , SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 0, 0

    DB SNAKE_SPAWN_POINT_Y + SPRITE_HEIGHT, SNAKE_SPAWN_POINT_X + SPRITE_WIDTH*3, SNAKE_IDLE_NECK_TILE_ID + 2, SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 0, 0

    DB SNAKE_SPAWN_POINT_Y + SPRITE_HEIGHT, SNAKE_SPAWN_POINT_X - SPRITE_WIDTH, SNAKE_TAIL_UP_TILE_ID + 2  , SPRITE_ATTR_PRIORITY   ; Sprite 0: Columna 1, Fila 1
    DB 0, 0, 0, 0


init_snake::
	call init_snake_tiles

    ld hl, snake_spawn_definition
    ld c, SNAKE_NUM_ENTITIES
    call spawn_group_entity

	ret

init_snake_tiles:
    call turn_screen_off

    ld hl, snake_tiles
    ld de, VRAM_TILE_DATA_START + (ENEMY_START_TILE_ID * VRAM_TILE_SIZE)
    ld b, 0
    call memcpy_256

    ld b, 218
    call memcpy_256

    call turn_screen_on
    ret