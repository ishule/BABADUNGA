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

	cp SPIDER_WAIT_STATE
	jr z, .wait_state

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
		call manage_stand_state
		ret
	
	.jump_state:
		call manage_jump_state
		ret

	.go_up_state:
		call manage_go_up_state
		ret

	.wait_state:
		call manage_wait_state
		ret

	ret

manage_roof_state:
	call spider_shot_roof_state_logic
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

	ld hl, spider_state_counter
	ld [hl], SPIDER_STUN_TIME
	ret

manage_stun_state:
	ld a, [spider_state_counter]
	dec a
	ld [spider_state_counter], a
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

	ld hl, spider_looking_dir
	ld [hl], SPIDER_LOOKING_RIGHT

	ret

manage_jump_to_stand_state:
	call make_sure_spider_looks_at_player

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

	ld hl, spider_shot_cooldown
	ld [hl], SPIDER_GROUND_STATE_SHOT_COOLDOWN

	ld hl, spider_state_counter
	ld [hl], SPIDER_STAND_TIME

	ret

manage_stand_state:
	ld a, [spider_state_counter]
	dec a
	ld [spider_state_counter], a
	jr z, .go_to_jump_state

	call spider_shot_ground_state_logic
	call make_sure_spider_looks_at_player
	ret
	
	.go_to_jump_state:
		ld a, SPIDER_JUMP_STATE
		ld [spider_state], a

		call change_spider_sprites_from_ground_to_jump

		; Do jump
		ld a, ENEMY_START_ENTITY_ID
		call man_entity_locate_v2


		ld de, SPIDER_JUMP_IMPULSE_X
		ld a, [spider_looking_dir]
		or a
		jr z, .jump_right
		.jump_left:
			call positive_to_negative_DE
		.jump_right:

		ld bc, SPIDER_JUMP_IMPULSE_Y
		ld a, SPIDER_NUM_ENTITIES
		call change_entity_group_vel


		ld a, ENEMY_START_ENTITY_ID
		call man_entity_locate_v2
		ld bc, SPIDER_JUMP_GRAVITY
		ld d, SPIDER_NUM_ENTITIES
		call change_entity_group_acc_y

	ret 

manage_jump_state:
	; Check Ground
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc h
	ld a, [hl]
	cp GROUND_Y - SPRITE_HEIGHT
	jr nc, .on_ground

	ld a, ENEMY_START_ENTITY_ID + 6
	call man_entity_locate_v2
	inc h
	inc l
	ld b, [hl] ; B = SPIDER_POS_X

	ld a, PLAYER_BODY_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	ld a, [hl] ; A = PLAYER_POS_X

	; CHECK DIRECTION
	cp b
	jr c, .player_to_the_left
	.player_to_the_right:
		ld a, [spider_looking_dir]
		or a
		ret z
		jr .stop_x_vel

	.player_to_the_left:
		ld a, [spider_looking_dir]
		or a
		ret nz

	.stop_x_vel:
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, 0
	ld d, SPIDER_NUM_ENTITIES
	call change_entity_group_vel_x
	ret

	.on_ground:
	call change_spider_sprites_from_jump_to_ground

	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, 0
	ld de, 0
	ld a, SPIDER_NUM_ENTITIES
	call change_entity_group_vel

	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, 0
	ld d, SPIDER_NUM_ENTITIES
	call change_entity_group_acc_y

	ld hl, spider_state
	ld [hl], SPIDER_WAIT_STATE

	ld hl, spider_state_counter
	ld [hl], SPIDER_GO_UP_WAIT_TIME

	ret

manage_wait_state:
	ld a, [spider_state_counter]
	dec a
	ld [spider_state_counter], a
	ret nz

	ld hl, spider_state
	ld [hl], SPIDER_GO_UP_STATE

	ld bc, SPIDER_GO_UP_IMPULSE_Y
	ld de, SPIDER_GO_UP_IMPULSE_X

	;Check spider pos. If on left half jump right else jump left
	ld a, ENEMY_START_ENTITY_ID + 1
	call man_entity_locate_v2
	inc h
	inc l
	ld a, [hl-]
	cp SCREEN_PIXEL_WIDTH/2
	jr c, .jump_right
	.jump_left:
		call positive_to_negative_DE
		ld a, [spider_looking_dir]
		or a
		jr nz, .do_jump
		push de
		push bc
		call change_spider_looking_dir
		pop bc
		pop de
		jr .do_jump

	.jump_right:
		ld a, [spider_looking_dir]
		or a
		jr z, .do_jump
		push de
		push bc
		call change_spider_looking_dir
		pop bc
		pop de


	.do_jump:
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld a, SPIDER_NUM_ENTITIES
	call change_entity_group_vel


	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, SPIDER_GO_UP_GRAVITY
	ld d, SPIDER_NUM_ENTITIES
	call change_entity_group_acc_y
	call change_spider_sprites_from_ground_to_jump

	ret

manage_go_up_state:
	; Check roof
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc h
	ld a, [hl]
	cp SPIDER_SPAWN_POINT_Y
	ret nc

	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, 0
	ld de, 0
	ld a, SPIDER_ROOF_NUM_ENTITIES
	call change_entity_group_vel

	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, 0
	ld d, SPIDER_ROOF_NUM_ENTITIES
	call change_entity_group_acc_y

	call set_spider_roof_sprites

	; Swap if looking left
	ld a, [spider_looking_dir]
	or a
	jr z, .do_not_swap
	.swap_x:
		call swap_x_spider_entity
	.do_not_swap:

	ld hl, spider_state
	ld [hl], SPIDER_ROOF_STATE

	ld hl, spider_shot_cooldown
	ld [hl], SPIDER_ROOF_STATE_SHOT_COOLDOWN

	;DEBUG: reset damage
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc l
	inc l
	ld [hl], 0

	call set_web_hook_entities

	ret

set_web_hook_entities:
	ld a, ENEMY_START_ENTITY_ID + 1
	call man_entity_locate_v2
	inc h	
	inc l

	ld d, SPIDER_SPAWN_POINT_Y - SPRITE_HEIGHT
	ld e, [hl]

	ld a, SPIDER_WEB_HOOK_ENTITY_ID
	call man_entity_locate_v2
	inc h
	ld [hl], d
	inc l
	ld [hl], e
	inc l
	ld [hl], SPIDER_WEB_HOOK_TILE_ID
	inc l
	ld [hl], SPRITE_ATTR_NO_FLIP

	ld a, e
	add SPRITE_WIDTH
	ld e, a

	inc l
	ld [hl], d
	inc l
	ld [hl], e
	inc l
	ld [hl], SPIDER_WEB_HOOK_TILE_ID + 2
	inc l
	ld [hl], SPRITE_ATTR_NO_FLIP

	ret

set_spider_roof_sprites:
	ld de, CMP_SIZE
	ld b, SPIDER_SPAWN_POINT_Y
	ld c, SPIDER_SPAWN_POINT_Y + SPRITE_HEIGHT
	
	; upper legs
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc h

	ld [hl], b
	inc l
	inc l 
	ld [hl], ENEMY_START_TILE_ID
	inc l
	ld [hl], SPRITE_ATTR_NO_FLIP

	add hl, de

	ld [hl], SPRITE_ATTR_NO_FLIP
	dec l
	ld [hl], ENEMY_START_TILE_ID + 2
	dec l 
	dec l
	ld [hl], b

	add hl, de

	ld [hl], c
	inc l
	inc l 
	ld [hl], ENEMY_START_TILE_ID + 4
	inc l
	ld [hl], SPRITE_ATTR_NO_FLIP

	add hl, de

	ld [hl], SPRITE_ATTR_NO_FLIP
	dec l
	ld [hl], ENEMY_START_TILE_ID + 6
	dec l 
	dec l
	ld [hl], c

	; === RIGHT PART ===

	add hl, de

	ld [hl], b
	inc l
	inc l 
	ld [hl], ENEMY_START_TILE_ID + 2
	inc l
	ld [hl], SPRITE_ATTR_FLIP_X

	add hl, de

	ld [hl], SPRITE_ATTR_FLIP_X
	dec l
	ld [hl], ENEMY_START_TILE_ID
	dec l 
	dec l
	ld [hl], b

	add hl, de

	ld [hl], c
	inc l
	inc l 
	ld [hl], ENEMY_START_TILE_ID + 6
	inc l
	ld [hl], SPRITE_ATTR_FLIP_X

	add hl, de

	ld [hl], SPRITE_ATTR_FLIP_X
	dec l
	ld [hl], ENEMY_START_TILE_ID + 4
	dec l 
	dec l
	ld [hl], c

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

change_spider_sprites_from_ground_to_jump:
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
		add c
		ld [hl], a

		inc d
		dec b
		jr nz, .loop

	ret

change_spider_sprites_from_jump_to_ground:
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
		ld [hl], a

		inc d
		dec b
		jr nz, .loop
	ret

make_sure_spider_looks_at_player:
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	ld b, [hl] ; B = SPIDER_POS_X

	ld a, PLAYER_BODY_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	ld a, [hl] ; A = PLAYER_POS_X

	; CHECK DIRECTION
	cp b
	jr c, .player_to_the_left
	.player_to_the_right:
		ld a, [spider_looking_dir]
		cp 0
		ret z
		jr .change_dir

	.player_to_the_left:
		ld a, [spider_looking_dir]
		cp 1
		ret z

	.change_dir:
	call change_spider_looking_dir

	ret

change_spider_looking_dir:
	call swap_x_spider_entity
	call flip_spider_x
	; Invertir el bit
	ld a, [spider_looking_dir]
	xor 1
	ld [spider_looking_dir], a

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

swap_x_spider_entity:
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld d, h
	ld e, l

	ld a, ENEMY_START_ENTITY_ID + 5
	call man_entity_locate_v2

	call swap_2_entities_positions

	ld a, ENEMY_START_ENTITY_ID + 1
	call man_entity_locate_v2
	ld d, h
	ld e, l

	ld a, ENEMY_START_ENTITY_ID + 4
	call man_entity_locate_v2

	call swap_2_entities_positions 

	ld a, ENEMY_START_ENTITY_ID + 2
	call man_entity_locate_v2
	ld d, h
	ld e, l

	ld a, ENEMY_START_ENTITY_ID + 7
	call man_entity_locate_v2

	call swap_2_entities_positions 

	ld a, ENEMY_START_ENTITY_ID + 3
	call man_entity_locate_v2
	ld d, h
	ld e, l

	ld a, ENEMY_START_ENTITY_ID + 6
	call man_entity_locate_v2

	call swap_2_entities_positions 

	ret

flip_spider_x:
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	inc l
	inc l
	ld c, SPIDER_NUM_ENTITIES
	bit SPRITE_ATTR_FLIP_X_BIT, [hl]
	jr z, .set_flip_x
	.reset_flip_x:
		ld a, 0
		jr .loop
	.set_flip_x:
		ld a, 1
	
	.loop:
		or a
		jr nz, .set
		.reset:
			res SPRITE_ATTR_FLIP_X_BIT, [hl]
			jr .next_entity
		.set:
			set SPRITE_ATTR_FLIP_X_BIT, [hl]

		.next_entity:
		ld de, CMP_SIZE
		add hl, de

		dec c
		jr nz, .loop

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


	ld a, SPIDER_WEB_HOOK_ENTITY_ID 
	call man_entity_locate_v2
	inc h
	ld b, CMP_SIZE*2
	call memreset_256

	ret

anim_open_spider_mouth:
	ld a, ENEMY_START_ENTITY_ID + 3
	call man_entity_locate_v2
	inc h
	inc l
	inc l
	ld [hl], SPIDER_OPEN_MOUTH_TILE_ID

	ld a, ENEMY_START_ENTITY_ID + 6
	call man_entity_locate_v2
	inc h
	inc l
	inc l
	ld [hl], SPIDER_OPEN_MOUTH_TILE_ID

	ret


anim_shut_spider_mouth:
	ld a, ENEMY_START_ENTITY_ID + 3
	call man_entity_locate_v2
	inc h
	inc l
	inc l
	ld [hl], SPIDER_OPEN_MOUTH_TILE_ID-2

	ld a, ENEMY_START_ENTITY_ID + 6
	call man_entity_locate_v2
	inc h
	inc l
	inc l
	ld [hl], SPIDER_OPEN_MOUTH_TILE_ID-2

	ret

spider_shot_roof_state_logic:
	; === Check shot cooldown ===
	ld a, [spider_shot_cooldown]
	cp 0
	jr z, .shot
	.decrease_cooldown:
	dec a
	ld [spider_shot_cooldown], a
	cp SPIDER_ROOF_STATE_SHOT_ANIM_TIME
	ret nz
	call anim_open_spider_mouth
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

		call anim_shut_spider_mouth
	ret


spider_shot_ground_state_logic:
	; === Check shot cooldown ===
	ld a, [spider_shot_cooldown]
	cp 0
	jr z, .shot
	.decrease_cooldown:
	dec a
	ld [spider_shot_cooldown], a

	cp SPIDER_GROUND_STATE_SHOT_ANIM_TIME
	ret nz

	call change_spider_sprites_from_ground_to_jump

	ret

	.shot:
		; === COMPUTE BULLET POS ===
		ld a, ENEMY_START_ENTITY_ID + 5
		call man_entity_locate_v2
		inc h
		ld b, [hl]
		inc l
		ld c, [hl]

		; === SPAWN BULLET ===
		ld a, [spider_looking_dir]
		or a
		jr z, .shot_right
		.shot_left:
			ld a, LEFT_SHOT_DIRECTION
			jr .spawn_bullet

		.shot_right:
			ld a, RIGHT_SHOT_DIRECTION

		.spawn_bullet:
		ld de, spider_bullet_preset

		ld hl, spider_shot_cooldown
		ld [hl], SPIDER_GROUND_STATE_SHOT_COOLDOWN

		call shot_bullet_for_preset
		call change_spider_sprites_from_jump_to_ground

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