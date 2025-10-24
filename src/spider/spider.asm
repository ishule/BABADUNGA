INCLUDE "consts.inc"
INCLUDE "spider/spider_consts.inc"

SECTION "Spider Variables", WRAM0
spider_state::             DS 1 ; 0:roof | 1:falling | 2:stunned | 3:jump_to_stand | 4:stand | 5:jumping | 6:going_up
spider_shot_cooldown::     DS 1
spider_state_counter::     DS 1
spider_looking_dir::       DS 1 ; 0:rigth | 1:left
spider_animation_counter:: DS 1 
spider_stage::             DS 1 ; 0:fase 0 | 1:fase 1

SECTION "Spider Inicialization", ROM0

init_spider::
	call init_spider_tiles
	call init_spider_roof_entity_sprites
	call init_spider_entity_web_hook
	
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

init_spider_roof_entity_sprites:
	ld b, SPIDER_SPAWN_POINT_Y
	ld c, SPIDER_SPAWN_POINT_X

	; upper legs
	call man_entity_alloc
	inc h
	ld [hl], b
	inc l
	ld [hl], c
	inc l 
	ld [hl], ENEMY_START_TILE_ID
	inc l
	ld [hl], SPRITE_ATTR_NO_FLIP


	call man_entity_alloc
	inc h
	

	ld [hl], b

	ld a, c
	add SPRITE_WIDTH
	ld c, a
	inc l
	ld [hl], c
	
	inc l 
	ld [hl], ENEMY_START_TILE_ID + 2
	
	inc l
	ld [hl], SPRITE_ATTR_NO_FLIP


	ld b, SPIDER_SPAWN_POINT_Y+SPRITE_HEIGHT
	ld c, SPIDER_SPAWN_POINT_X

	; lower legs
	call man_entity_alloc
	inc h
	ld [hl], b
	inc l
	ld [hl], c
	inc l 
	ld [hl], ENEMY_START_TILE_ID + 4
	inc l
	ld [hl], SPRITE_ATTR_NO_FLIP


	call man_entity_alloc
	inc h
	

	ld [hl], b

	ld a, c
	add SPRITE_WIDTH
	ld c, a
	inc l
	ld [hl], c
	
	inc l 
	ld [hl], ENEMY_START_TILE_ID + 6
	
	inc l
	ld [hl], SPRITE_ATTR_NO_FLIP

	; ======== RIGHT PART ========
	ld b, SPIDER_SPAWN_POINT_Y
	ld c, SPIDER_SPAWN_POINT_X + SPRITE_WIDTH * 2

	; upper legs
	call man_entity_alloc
	inc h
	ld [hl], b
	inc l
	ld [hl], c
	inc l 
	ld [hl], ENEMY_START_TILE_ID + 2
	inc l
	ld [hl], SPRITE_ATTR_FLIP_X


	call man_entity_alloc
	inc h
	

	ld [hl], b

	ld a, c
	add SPRITE_WIDTH
	ld c, a
	inc l
	ld [hl], c
	
	inc l 
	ld [hl], ENEMY_START_TILE_ID
	
	inc l
	ld [hl], SPRITE_ATTR_FLIP_X


	ld b, SPIDER_SPAWN_POINT_Y + SPRITE_HEIGHT
	ld c, SPIDER_SPAWN_POINT_X + SPRITE_WIDTH * 2

	; lower legs
	call man_entity_alloc
	inc h
	ld [hl], b
	inc l
	ld [hl], c
	inc l 
	ld [hl], ENEMY_START_TILE_ID + 6
	inc l
	ld [hl], SPRITE_ATTR_FLIP_X


	call man_entity_alloc
	inc h
	

	ld [hl], b

	ld a, c
	add SPRITE_WIDTH
	ld c, a
	inc l
	ld [hl], c
	
	inc l 
	ld [hl], ENEMY_START_TILE_ID + 4
	
	inc l
	ld [hl], SPRITE_ATTR_FLIP_X



	ret

init_spider_entity_web_hook:

	ld b, SPIDER_SPAWN_POINT_Y - SPRITE_HEIGHT
	ld c, SPIDER_SPAWN_POINT_X + SPRITE_WIDTH

	call man_entity_alloc
	inc h
	ld [hl], b
	inc l
	ld [hl], c
	inc l 
	ld [hl], SPIDER_WEB_HOOK_TILE_ID
	inc l
	ld [hl], SPRITE_ATTR_NO_FLIP

	call man_entity_alloc
	inc h
	ld [hl], b
	inc l

	ld a, c
	add SPRITE_WIDTH
	ld c, a
	ld [hl], c
	inc l 
	ld [hl], SPIDER_WEB_HOOK_TILE_ID + 2
	inc l
	ld [hl], SPRITE_ATTR_NO_FLIP

	ret
