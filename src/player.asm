INCLUDE "consts.inc"

SECTION "Player Code", ROM0


player_sprites:
	DB $8A, $12, $06, %10000000	;; Izquierdo, personaje
	DB $8A, $1A, $08, %10000000	;; Derecho, cerbatana

init_player::
	call init_player_tiles
	call init_player_entity
	ret

init_player_tiles::
	;; Load Tiles
	call wait_vblank

	;; Cargar Player_stand en tiles $06-$07
	ld hl, Player_stand
	ld de, VRAM_TILE_DATA_START + ($06 * VRAM_TILE_SIZE)
	ld b, 2 * VRAM_TILE_SIZE
	call memcpy_256

	;; Cargar Player_blowgun en tiles $08-$09
	ld hl, Player_blowgun
	ld de, VRAM_TILE_DATA_START + ($08 * VRAM_TILE_SIZE)
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

	call man_entity_alloc
	;; HL = $C004
	ld d, h 
	ld e, l 
	ld hl, player_sprites + 4
	ld b, SPRITE_SIZE
	call memcpy_256

	call wait_vblank
	call man_entity_draw
	ret

