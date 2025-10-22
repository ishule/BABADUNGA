INCLUDE "consts.inc"
INCLUDE "spider/spider_consts.inc"

SECTION "Spider Code", ROM0

spider_logic::
	; === Check state ==
	ld a, [spider_state]
	
	cp SPIDER_ROOF_STATE
	jr z, .roof_state
	
	cp SPIDER_FALL_STATE
	jr z, .fall_state

	cp SPIDER_STUN_STATE
	jr z, .stun_state

	cp SPIDER_JUMP_TO_STAND_STATE
	jr z, .jump_to_stand_state

	cp SPIDER_STAND_STATE
	jr z, .stand_state

	cp SPIDER_JUMP_STATE
	jr z, .jump_state

	cp SPIDER_GO_UP_STATE
	jr z, .go_up_state	

	.roof_state:
		call manage_roof_state
		ret

	.fall_state:
		call manage_fall_state
		ret


	.stun_state:
		call manage_stun_state
		ret

	.jump_to_stand_state:
		call manage_jump_to_stand_state
		ret

	.stand_state:
	
	.jump_state:

	.go_up_state:


	ret

manage_roof_state:
	call spider_shot_logic
	call move_spider_towards_player
	
	; Check state change
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc l
	inc l
	ld a, FLAG_ENTITY_GOT_DAMAGE
	and [hl]
	ret z
	ld a, SPIDER_FALL_STATE
	ld [spider_state], a

	call transition_roof_to_fall
	call set_spider_fall_sprites
	ret

manage_fall_state:
	; GROUND CHECK
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc h
	ld a, [hl]
	cp GROUND_Y + SPRITE_HEIGHT/2
	ret c

	; Reset vel and acc
	dec h
	ld bc, 0
	ld d, SPIDER_NUM_ENTITIES
	call change_entity_group_acc_y

	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, 0
	ld d, SPIDER_NUM_ENTITIES
	call change_entity_group_vel_y

	; Change state
	ld a, SPIDER_STUN_STATE
	ld [spider_state], a

	ld hl, spider_stunned_counter
	ld [hl], SPIDER_STUN_TIME
	ret

manage_stun_state:
	ld a, [spider_stunned_counter]
	dec a
	ld [spider_stunned_counter], a
	ret nz

	ld a, SPIDER_JUMP_TO_STAND_STATE
	ld [spider_state], a

	call change_spider_sprites_from_fall_to_ground

	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, SPIDER_JUMP_TO_STAND_IMPULSE
	ld d, SPIDER_NUM_ENTITIES
	call change_entity_group_vel_y

 	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, SPIDER_FALLING_GRAVITY
	ld d, SPIDER_NUM_ENTITIES
	call change_entity_group_acc_y
	ret

manage_jump_to_stand_state:
	; CHECK IF FALLING DOWN
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc h
	inc h
	ld a, [hl]
	bit 7, a
	ret nz

	; GROUND CHECK
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc h
	ld a, [hl]
	cp GROUND_Y - SPRITE_HEIGHT
	ret c

	; Reset vel and acc
	ld a, ENEMY_START_ENTITY_ID
	ld bc, 0
	ld d, SPIDER_NUM_ENTITIES
	call change_entity_group_acc_y

	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, 0
	ld d, SPIDER_NUM_ENTITIES
	call change_entity_group_vel_y

	; Change state
	ld a, SPIDER_STAND_STATE
	ld [spider_state], a
	ret

manage_stand_state:
	
	ret 

manage_jump_state:
	
	ret

manage_go_up_state:
	
	ret

set_spider_fall_sprites:
	ld c, SPIDER_JUMP_STATE_TILE_ID
	ld b, SPIDER_NUM_ENTITIES

	ld d, ENEMY_START_ENTITY_ID
	.loop:
		ld a, d
		call man_entity_locate_v2

		; Go to tile compoent
		inc h
		inc l
		inc l
		ld [hl], c

		; Go to ATTR
		inc l
		ld [hl], %11000000
		
		; Go to next tile ID
		inc c
		inc c

		inc d

		dec b
		jr nz, .loop

	call swap_y_spider_entity
	ret


change_spider_sprites_from_fall_to_ground:
	ld c, 16 ; gap between entity tiles
	ld b, SPIDER_NUM_ENTITIES

	ld d, ENEMY_START_ENTITY_ID
	.loop:
		ld a, d
		call man_entity_locate_v2

		; Go to tile compoent
		inc h
		inc l
		inc l
		ld a, [hl]
		sub c
		ld [hl+], a
		ld [hl], %10000000

		inc d

		dec b
		jr nz, .loop

	call swap_y_spider_entity
	ret


swap_y_spider_entity:
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld d, h
	ld e, l

	ld a, ENEMY_START_ENTITY_ID + 2
	call man_entity_locate_v2

	call swap_2_entities_positions 

	ld a, ENEMY_START_ENTITY_ID + 1
	call man_entity_locate_v2
	ld d, h
	ld e, l

	ld a, ENEMY_START_ENTITY_ID + 3
	call man_entity_locate_v2

	call swap_2_entities_positions 

	ld a, ENEMY_START_ENTITY_ID + 4
	call man_entity_locate_v2
	ld d, h
	ld e, l

	ld a, ENEMY_START_ENTITY_ID + 6
	call man_entity_locate_v2

	call swap_2_entities_positions 

	ld a, ENEMY_START_ENTITY_ID + 5
	call man_entity_locate_v2
	ld d, h
	ld e, l

	ld a, ENEMY_START_ENTITY_ID + 7
	call man_entity_locate_v2

	call swap_2_entities_positions 

	ret

transition_roof_to_fall:
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2

	ld bc, SPIDER_FALLING_IMPULSE
	ld de, $00
	ld a, SPIDER_NUM_ENTITIES

	call change_entity_group_vel


	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2

	ld bc, SPIDER_FALLING_GRAVITY
	ld d, SPIDER_NUM_ENTITIES

	call change_entity_group_acc_y


	ld a, SPIDER_WEB_HOOK_ENTITY_ID + 1 
	call man_entity_delete

	ld a, SPIDER_WEB_HOOK_ENTITY_ID
	call man_entity_delete

	ret


spider_shot_logic:
	; === Check shot cooldown ===
	ld a, [spider_shot_cooldown]
	cp 0
	jr z, .shot
	.decrease_cooldown:
	dec a
	ld [spider_shot_cooldown], a
	ret

	.shot:
		; === COMPUTE BULLET POS ===
		ld a, ENEMY_START_ENTITY_ID
		call man_entity_locate_v2
		inc h
		ld b, [hl]
		inc l
		ld c, [hl]

		ld a, b
		add SPRITE_HEIGHT
		ld b, a

		ld a, c
		add SPRITE_WIDTH + SPRITE_WIDTH/2
		ld c, a

		; === SPAWN BULLET ===
		ld de, spider_bullet_preset
		ld a, DOWN_SHOT_DIRECTION
		call shot_bullet_for_preset

		; === SET COOLDOWN ===
		ld hl, spider_shot_cooldown
		ld [hl], SPIDER_ROOF_STATE_SHOT_COOLDOWN
	ret


move_spider_towards_player:
	; === READ PLAYER POS ===
	; Read body pos
	ld a, PLAYER_BODY_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	ld b, [hl]

	; Read gun pos
	ld a, PLAYER_GUN_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	ld a, [hl]

	; Compare to use middle
	cp b
	jr c, .use_player_body_pos

	.use_player_gun_pos:
		ld b, a

	.use_player_body_pos:

	; B = PLAYER_POS_MID

	; === READ SPIDER POS ===
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	ld a, [hl]
	add SPRITE_WIDTH*2 ; Calculate middle

	; A = SPIDER_POS_MID

	; === CHECK IF SAME POS ===
	cp b
	jr nz, .move
	.not_move:
	ld bc, 0
	jr .skip_conversion
	.move:

	; === CALCULATE DIRECTION ===
	ld bc, SPIDER_ROOF_SPEED
	; Player_pos < Spider_pos
	jr c, .skip_conversion
	call positive_to_negative_BC
	.skip_conversion:

	; MOVE TOWARDS PLAYER
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2

	ld d, SPIDER_ROOF_NUM_ENTITIES
	call change_entity_group_vel_x
	ret