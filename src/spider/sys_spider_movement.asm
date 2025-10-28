INCLUDE "consts.inc"
INCLUDE "spider/spider_consts.inc"

SECTION "Spider Variables", WRAM0
spider_state::             DS 1 ; 0:roof | 1:falling | 2:stunned | 3:jump_to_stand | 4:stand | 5:jumping | 6:going_up
spider_shot_cooldown::     DS 1
spider_state_counter::     DS 1
spider_animation_counter:: DS 1 
spider_stage::             DS 1 ; 0:fase 0 | 1:fase 1

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

	cp SPIDER_WAIT_STATE
	jr z, .wait_state

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
		call manage_stand_state
		ret
	
	.jump_state:
		call manage_jump_state
		ret

	.wait_state:
		call manage_wait_state
		ret

	.go_up_state:
		call manage_go_up_state

	ret

manage_roof_state:
	ld a, [spider_stage]
	or a
	jr z, .stage_0
	.stage_1:
	call spider_shot_roof_state_logic_for_stage_1
	jr .end_if

	.stage_0:
	call spider_shot_roof_state_logic
	
	.end_if:

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
	
	call reset_walk_anim
	call reset_mouth_anim
	
	ld a, SPIDER_WEB_HOOK_ENTITY_ID
	ld b, SWAP_MASK_SPRITE_WEB_HOOK
	ld c, 2
	call swap_sprite_by_mask

	ld a, SPIDER_WEB_HOOK_ENTITY_ID
	call man_entity_locate_v2
    ld bc, 0
	ld d, 2
    call change_entity_group_vel_x

	ld a, ENEMY_START_ENTITY_ID
	ld b, SWAP_MASK_SPRITE_ROOF_LEFT_JUMP
	ld c, SPIDER_NUM_ENTITIES/2
	call swap_sprite_by_mask

	ld a, ENEMY_START_ENTITY_ID + SPIDER_NUM_ENTITIES/2
	ld b, SWAP_MASK_SPRITE_ROOF_RIGHT_JUMP
	ld c, SPIDER_NUM_ENTITIES/2
	call swap_sprite_by_mask

	ld c, SPIDER_NUM_ENTITIES/2
    ld a, ENEMY_START_ENTITY_ID + SPIDER_NUM_ENTITIES/2
    call flip_boss_x
    call swap_x_right_half_boss_entity
	
	ld c, SPIDER_NUM_ENTITIES
	call rotate_boss_y

	; TODO: Hacer que vaya en función de la vida
	ld hl, spider_stage
	ld [hl], $01

	ret


reset_walk_anim:
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	inc l
	ld a, [hl]
	cp ENEMY_START_TILE_ID
	ret z
	call animate_legs_roof
	ret

reset_mouth_anim:
	ld a, ENEMY_START_ENTITY_ID + 3
	call man_entity_locate_v2
	inc h
	inc l
	inc l
	ld a, [hl]
	cp ENEMY_START_TILE_ID + 6
	ret z
	call anim_shut_spider_mouth
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

	ld a, ENEMY_START_ENTITY_ID
	ld b, SWAP_MASK_SPRITE_JUMP_STAND
	ld c, SPIDER_NUM_ENTITIES
	call swap_sprite_by_mask

	ld c, SPIDER_NUM_ENTITIES
	call rotate_boss_y

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

	ld hl, boss_looking_dir
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

		ld a, ENEMY_START_ENTITY_ID
		ld c, SPIDER_NUM_ENTITIES
		ld b, SWAP_MASK_SPRITE_JUMP_STAND
		call swap_sprite_by_mask

		; Do jump
		ld a, ENEMY_START_ENTITY_ID
		call man_entity_locate_v2


		ld de, SPIDER_JUMP_IMPULSE_X
		ld a, [boss_looking_dir]
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
		ld a, [boss_looking_dir]
		or a
		ret z
		jr .stop_x_vel

	.player_to_the_left:
		ld a, [boss_looking_dir]
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
	ld a, ENEMY_START_ENTITY_ID
	ld c, SPIDER_NUM_ENTITIES
	ld b, SWAP_MASK_SPRITE_JUMP_STAND
	call swap_sprite_by_mask

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
		ld a, [boss_looking_dir]
		or a
		jr nz, .do_jump
		push de
		push bc
		ld c, SPIDER_NUM_ENTITIES
		call rotate_boss_x
		pop bc
		pop de
		jr .do_jump

	.jump_right:
		ld a, [boss_looking_dir]
		or a
		jr z, .do_jump
		push de
		push bc
		ld c, SPIDER_NUM_ENTITIES
		call rotate_boss_x
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

	ld a, ENEMY_START_ENTITY_ID
	ld b, SWAP_MASK_SPRITE_JUMP_STAND
	ld c, SPIDER_NUM_ENTITIES
	call swap_sprite_by_mask

	ret

manage_go_up_state:
	; Check roof
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc h
	ld a, [hl]
	cp SPIDER_SPAWN_POINT_Y
	ret nc

	; Swap if looking left
	ld a, [boss_looking_dir]
	or a
	jr z, .skip_rotation
	.rotate_x:
	ld c, SPIDER_NUM_ENTITIES
	call rotate_boss_x
	.skip_rotation:
	
	ld d, SPIDER_NUM_ENTITIES
	call reset_group_vel

	ld d, SPIDER_NUM_ENTITIES
	call reset_group_acc_y

	ld a, ENEMY_START_ENTITY_ID
	ld b, SWAP_MASK_SPRITE_ROOF_LEFT_JUMP
	ld c, SPIDER_NUM_ENTITIES/2
	call swap_sprite_by_mask

	ld a, ENEMY_START_ENTITY_ID + SPIDER_NUM_ENTITIES/2
	ld b, SWAP_MASK_SPRITE_ROOF_RIGHT_JUMP
	ld c, SPIDER_NUM_ENTITIES/2
	call swap_sprite_by_mask

	ld c, SPIDER_NUM_ENTITIES/2
    ld a, ENEMY_START_ENTITY_ID + SPIDER_NUM_ENTITIES/2
    call flip_boss_x
    call swap_x_right_half_boss_entity

	ld hl, spider_state
	ld [hl], SPIDER_ROOF_STATE

	ld hl, spider_shot_cooldown
	ld [hl], SPIDER_ROOF_STATE_SHOT_COOLDOWN

	ld a, SPIDER_WEB_HOOK_ENTITY_ID
	ld b, SWAP_MASK_SPRITE_WEB_HOOK
	ld c, 2
	call swap_sprite_by_mask


	ld a, ENEMY_START_ENTITY_ID + 1
	call man_entity_locate_v2
	inc h
	ld b, [hl]
	inc l
	ld c, [hl]

	ld a, SPIDER_WEB_HOOK_ENTITY_ID
	call man_entity_locate_v2
	ld d, 2
	ld a, b
	sub SPRITE_HEIGHT
	ld b, a
	call change_entity_group_pos

	; === DEBUG ===
	;Reset flag
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc l
	inc l
	res 3, [hl]

	ret

manage_roof_animation:
	ld a, [spider_animation_counter]
	dec a
	ld [spider_animation_counter], a
	ret nz

	call animate_legs_roof

	ld hl, spider_animation_counter
	ld [hl], SPIDER_ROOF_STATE_WALK_ANIM_TIME
	ret

animate_legs_roof:
	ld bc, CMP_SIZE*2 ; offset entre patas del mismo lado

	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	inc l
	
	ld a, [hl]
	xor SPIDER_ROOF_ANIM_MASK_UPPER_LEGS
	ld [hl], a

	add hl, bc

	ld a, [hl]
	xor SPIDER_ROOF_ANIM_MASK_LOWER_LEGS
	ld [hl], a

	add hl, bc

	ld a, [hl]
	xor SPIDER_ROOF_ANIM_MASK_UPPER_LEGS
	ld [hl], a

	add hl, bc

	ld a, [hl]
	xor SPIDER_ROOF_ANIM_MASK_LOWER_LEGS
	ld [hl], a

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
		ld a, [boss_looking_dir]
		cp 0
		ret z
		jr .change_dir

	.player_to_the_left:
		ld a, [boss_looking_dir]
		cp 1
		ret z

	.change_dir:
	ld c, SPIDER_NUM_ENTITIES
	call rotate_boss_x

	ret



transition_roof_to_fall:

	; Reset X vel and apply knockback
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, SPIDER_FALLING_IMPULSE
	ld de, $00
	ld a, SPIDER_NUM_ENTITIES
	call change_entity_group_vel

	; Apply gravity
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, SPIDER_FALLING_GRAVITY
	ld d, SPIDER_NUM_ENTITIES
	call change_entity_group_acc_y

	ret

anim_open_spider_mouth:
	ld a, ENEMY_START_ENTITY_ID + 3
	call man_entity_locate_v2
	inc h
	inc l
	inc l
	ld [hl], SPIDER_OPEN_MOUTH_TILE_ID

	ld a, ENEMY_START_ENTITY_ID + 7
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

	ld a, ENEMY_START_ENTITY_ID + 7
	call man_entity_locate_v2
	inc h
	inc l
	inc l
	ld [hl], SPIDER_OPEN_MOUTH_TILE_ID-2

	ret

spider_shot_roof_state_logic_for_stage_1:
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
		ld a, ENEMY_START_ENTITY_ID + 1
		call man_entity_locate_v2
		inc h
		ld b, [hl]
		inc l
		ld c, [hl]

		ld a, b
		add SPRITE_HEIGHT
		ld b, a

		; === SPAWN BULLET ===
		ld de, spider_big_bullet_0_preset
		ld a, DOWN_SHOT_DIRECTION

		push af
		call sys_sound_spit_effect
		pop af
		push bc
		call shot_bullet_for_preset
		pop bc
		ld a, c
		add SPRITE_WIDTH
		ld c, a
		ld de, spider_big_bullet_1_preset
		ld a, DOWN_SHOT_DIRECTION

		push af
		call sys_sound_spit_effect
		pop af
		call shot_bullet_for_preset

		; === SET COOLDOWN ===
		ld hl, spider_shot_cooldown
		ld [hl], SPIDER_ROOF_STATE_SHOT_COOLDOWN

		call anim_shut_spider_mouth
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

		push af
		call sys_sound_spit_effect
		pop af
		call shot_bullet_for_preset
		inc h
		inc l
		inc l
		ld [hl], SPIDER_GROUND_STATE_BULLET_GRAVITY

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

	ld b, SWAP_MASK_SPRITE_JUMP_STAND
	ld a, ENEMY_START_ENTITY_ID
	ld c, SPIDER_NUM_ENTITIES
	call swap_sprite_by_mask

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
		ld a, [boss_looking_dir]
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

		push af
		call sys_sound_spit_effect
		pop af
		call shot_bullet_for_preset
		inc h
		inc l
		ld [hl], SPIDER_GROUND_STATE_BULLET_GRAVITY

		ld b, SWAP_MASK_SPRITE_JUMP_STAND
        ld c, SPIDER_NUM_ENTITIES
        ld a, ENEMY_START_ENTITY_ID
        call swap_sprite_by_mask

	ret


move_spider_towards_player:
	; === READ PLAYER POS ===
	; Read body pos
	ld a, PLAYER_BODY_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	ld a, [hl]
	add SPRITE_WIDTH/2
	ld b, a
	; B = PLAYER_POS_MID

	; === READ SPIDER POS ===
	ld a, ENEMY_START_ENTITY_ID + 5
	call man_entity_locate_v2
	inc h
	inc l
	ld a, [hl]

	; A = SPIDER_POS_MID

	; === CHECK IF SAME POS ===
	cp b
	jr nz, .move
	.not_move:
	ld bc, 0
	jr .skip_conversion
	.move:

	call manage_roof_animation

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