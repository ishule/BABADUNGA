INCLUDE "consts.inc"

SECTION "Player Code", ROM0

player_tiles:
	DB $00,$00,$3E,$3E,$F8,$BE,$F2,$BE
	DB $A0,$BF,$81,$BF,$80,$9C,$2C,$13
	DB $00,$3C,$00,$3C,$00,$3C,$2C,$10
	DB $18,$24,$18,$24,$00,$24,$00,$36

player_sprites:
	DB $50, $36, $05, %00000000

init_player::
	call init_player_tiles
	call init_player_entity
	ret

init_player_tiles::
	;; Load Tiles
	call wait_vblank
	ld hl, player_tiles
	ld de, VRAM_TILE_DATA_START + ($40 + VRAM_TILE_SIZE)
	ld b, 2 * VRAM_TILE_SIZE
	call memcpy_256
	ret


init_player_entity::
	call man_entity_init
	call man_entity_alloc
	;; HL = $C000
	ld d, h 
	ld e, l 
	ld hl, player_sprites
	ld b, SPRITE_SIZE
	call memcpy_256

	call wait_vblank
	call man_entity_draw
	ret

