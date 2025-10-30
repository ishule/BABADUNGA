INCLUDE "consts.inc"
INCLUDE "spider/spider_consts.inc"

SECTION "Spider Variables", WRAM0
spider_shot_cooldown:: ds 1
damaged_times::        ds 1

SECTION "Spider Code", ROM0

set_dead_skin:
	ld de, CMP_SIZE
	ld c, SPIDER_NUM_ENTITIES
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld a, SPIDER_JUMP_STATE_TILE_ID
	inc h
	inc l
	inc l
	.loop:
		ld [hl], a
		add hl, de

		add 2
		dec c
		jr nz, .loop

	ld a, [boss_state]
	cp SPIDER_ROOF_STATE
	ret nz

	; Clean web hook
	ld a, SPIDER_WEB_HOOK_ENTITY_ID
	ld b, SWAP_MASK_SPRITE_WEB_HOOK
	ld c, 2
	call swap_sprite_by_mask

	ld c, SPIDER_NUM_ENTITIES/2
    ld a, ENEMY_START_ENTITY_ID + SPIDER_NUM_ENTITIES/2
    call flip_boss_x
    call swap_x_right_half_boss_entity

	ret

check_spider_dead:
	

	ld e, DEAD_ANIM_TIME
	ld d, SPIDER_ROOF_NUM_ENTITIES
	call check_dead_state
	ret nc
	.has_died:
		ld a, ENEMY_START_ENTITY_ID
		call man_entity_locate_v2
		ld bc, SPIDER_FALLING_IMPULSE
		ld d, SPIDER_NUM_ENTITIES
		call change_entity_group_vel_y

		ld a, ENEMY_START_ENTITY_ID
		call man_entity_locate_v2
		ld bc, SPIDER_FALLING_GRAVITY
		ld d, SPIDER_NUM_ENTITIES
		call change_entity_group_acc_y

		ld a, [boss_state]
		cp SPIDER_STUN_STATE
		jr z, .skip_rotation

		ld c, SPIDER_NUM_ENTITIES
		call rotate_boss_y

		.skip_rotation:
		call set_dead_skin

		ld hl, boss_state
    	ld [hl], SPIDER_DEAD_STATE

    ret

spider_logic::
	ld a, [boss_dead]
	or a
	ret nz

	call check_spider_dead	

	; === Check state ==
	ld a, [boss_state]
	
	cp SPIDER_ENTER_STATE
	jr z, .enter_state

	cp SPIDER_ENTER_YELL_STATE
	jr z, .enter_yell_state

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

	cp SPIDER_DEAD_STATE
	jr z, .dead_state

	cp SPIDER_STAGE_TRANSITION_STATE
	jr z, .stage_transition_state

	.enter_state:
		call manage_enter_state
		ret

	.enter_yell_state:
		call manage_enter_yell_state
		ret

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

	.dead_state:
		call manage_spider_dead_state
		ret

	.stage_transition_state:
		call manage_stage_stransition_state
		ret

	ret

manage_enter_state:
	call manage_roof_animation
	call check_spider_roof
	ret nz

	ld hl, boss_state_counter
	ld [hl], SPIDER_ENTER_ANIM_TIME

	ld hl, boss_animation_counter
	ld [hl], SPIDER_YELL_ANIM_TIME

	ld hl, boss_state
	ld [hl], SPIDER_ENTER_YELL_STATE

	ld d, SPIDER_ROOF_NUM_ENTITIES
	call reset_group_vel

	call animate_spider_mouth

	;TODO: Llamar a sonido de grito
	call sys_sound_boss_scream_effect

	ret

manage_enter_yell_state:
	ld a, [boss_animation_counter]
	dec a
	ld [boss_animation_counter], a
	jr nz, .no_anim
	call animate_spider_mouth

	.no_anim:
	ld a, [boss_state_counter]
	dec a
	ld [boss_state_counter], a
	ret nz

	ld d, SPIDER_ROOF_NUM_ENTITIES
    ld e, SPIDER_DAMAGE
    call init_boss_info

    ld hl, boss_state
	ld [hl], SPIDER_ROOF_STATE

	ld hl, boss_animation_counter
	ld [hl], SPIDER_ROOF_STATE_WALK_ANIM_TIME

	ret

manage_roof_state:
	ld a, [boss_stage]
	or a
	jr nz, .stage_1
	
	ld a, [boss_health]
	cp SPIDER_STAGE_CHANGE_HEALTH
	jr nc, .stage_0
	.change_stage:
		ld hl, boss_stage
		inc [hl]

		ld hl, boss_state
		ld [hl], SPIDER_STAGE_TRANSITION_STATE

		call animate_spider_mouth

		ld hl, boss_state_counter
		ld [hl], SPIDER_STAGE_TRANSITION_TIME

		ld hl, boss_animation_counter
		ld [hl], SPIDER_YELL_ANIM_TIME

		; TODO: SONIDO GRITO
		call sys_sound_boss_scream_effect

		ret

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

	; Check times damaged
	ld a, [damaged_times]
	dec a
	ld [damaged_times], a
	ret nz

	.state_changed:
	ld hl, damaged_times
	ld [hl], DAMAGED_TIMES_TO_FALL

	ld a, SPIDER_FALL_STATE
	ld [boss_state], a

	; Apply knockback
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, SPIDER_FALLING_IMPULSE
	ld d, SPIDER_NUM_ENTITIES
	call change_entity_group_vel_y
	
	; Reset x vel
	ld d, SPIDER_ROOF_NUM_ENTITIES
	call reset_group_vel_x

	; Apply gravity
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, SPIDER_FALLING_GRAVITY
	ld d, SPIDER_NUM_ENTITIES
	call change_entity_group_acc_y
	
	; Clean animations
	call reset_walk_anim
	call reset_mouth_anim
	
	; Clean web hook
	ld a, SPIDER_WEB_HOOK_ENTITY_ID
	ld b, SWAP_MASK_SPRITE_WEB_HOOK
	ld c, 2
	call swap_sprite_by_mask

    ; Change sprite
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
	
	; Fall
	ld c, SPIDER_NUM_ENTITIES
	call rotate_boss_y

	; Change collider
	ld hl, spider_jump_collisions
	ld c, SPIDER_NUM_ENTITIES
	call change_boss_collisions

	ret

manage_fall_state:
	; SPECIAL GROUND CHECK
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc h
	ld a, [hl]
	cp GROUND_Y + SPRITE_HEIGHT/2
	ret c

	; Reset vel and acc
	
	ld d, SPIDER_NUM_ENTITIES
	call reset_group_acc_y

	ld d, SPIDER_NUM_ENTITIES
	call reset_group_vel_y

	; Change state
	ld a, SPIDER_STUN_STATE
	ld [boss_state], a

	; Set counter
	ld hl, boss_state_counter
	ld [hl], SPIDER_STUN_TIME
	ret

manage_stun_state:
	ld a, [boss_state_counter]
	dec a
	ld [boss_state_counter], a
	ret nz

	; Change state
	ld a, SPIDER_JUMP_TO_STAND_STATE
	ld [boss_state], a


	; Rotate to jump
	ld c, SPIDER_NUM_ENTITIES
	call rotate_boss_y

	; Make jump
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

	; Init looking direction
	ld hl, boss_looking_dir
	ld [hl], SPIDER_LOOKING_RIGHT

	ret

manage_jump_to_stand_state:
	call make_sure_spider_looks_at_player

	call check_ground_for_boss
	ret c

	; Reset vel and acc
	ld d, SPIDER_NUM_ENTITIES
	call reset_group_acc_y

	ld d, SPIDER_NUM_ENTITIES
	call reset_group_vel_y

	; Change Sprite to stand
	ld a, ENEMY_START_ENTITY_ID
	ld b, SWAP_MASK_SPRITE_JUMP_STAND
	ld c, SPIDER_NUM_ENTITIES
	call swap_sprite_by_mask

	; Set collider
	ld hl, spider_stand_collisions
	ld c, SPIDER_NUM_ENTITIES
	call change_boss_collisions

	; Change state
	ld a, SPIDER_STAND_STATE
	ld [boss_state], a

	ld hl, spider_shot_cooldown
	ld [hl], SPIDER_GROUND_STATE_SHOT_COOLDOWN

	ld hl, boss_state_counter
	ld [hl], SPIDER_STAND_TIME

	ret

manage_stand_state:
	call spider_shot_ground_state_logic
	call make_sure_spider_looks_at_player
	
	ld a, [boss_state_counter]
	dec a
	ld [boss_state_counter], a
	ret nz
	
	; Change state
	ld a, SPIDER_JUMP_STATE
	ld [boss_state], a

	; Change sprite
	ld a, ENEMY_START_ENTITY_ID
	ld c, SPIDER_NUM_ENTITIES
	ld b, SWAP_MASK_SPRITE_JUMP_STAND
	call swap_sprite_by_mask

	; Set collider
	ld hl, spider_jump_collisions
	ld c, SPIDER_NUM_ENTITIES
	call change_boss_collisions

	; Do jump
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld de, SPIDER_JUMP_IMPULSE_X
	ld a, [boss_looking_dir]
	or a
	jr z, .skip_conversion
		call positive_to_negative_DE
	.skip_conversion:
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
	call check_ground_for_boss
	jr nc, .ground_reached

	; Check player reached
	call take_mid_boss_entity
	call man_entity_locate_v2
	inc h
	inc l
	ld b, [hl] ; B = SPIDER_POS_X

	ld a, PLAYER_BODY_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	ld a, [hl] ; A = PLAYER_POS_X
	add SPRITE_WIDTH/2

	; CHECK DIRECTION
	cp b
	jr c, .player_to_the_left
	.player_to_the_right:
		ld a, [boss_looking_dir]
		or a
		ret z
		jr .player_reached

	.player_to_the_left:
		ld a, [boss_looking_dir]
		or a
		ret nz

	.player_reached:
	ld d, SPIDER_NUM_ENTITIES
	call reset_group_vel_x

	; Fall faster
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, SPIDER_GRAVITY_AUMENTED
	ld d, SPIDER_NUM_ENTITIES
	call change_entity_group_acc_y
	
	ret	

	.ground_reached:
	; Change sprite
	ld a, ENEMY_START_ENTITY_ID
	ld c, SPIDER_NUM_ENTITIES
	ld b, SWAP_MASK_SPRITE_JUMP_STAND
	call swap_sprite_by_mask

	; Set collisions
	ld hl, spider_stand_collisions
	ld c, SPIDER_NUM_ENTITIES
	call change_boss_collisions

	; Reset physics
	ld d, SPIDER_NUM_ENTITIES
	call reset_group_vel
	ld d, SPIDER_NUM_ENTITIES
	call reset_group_acc_y

	; Change state
	ld hl, boss_state
	ld [hl], SPIDER_WAIT_STATE

	ld hl, boss_state_counter
	ld [hl], SPIDER_GO_UP_WAIT_TIME

	ret

manage_wait_state:
	ld a, [boss_state_counter]
	dec a
	ld [boss_state_counter], a
	ret nz

	; State changed
	ld hl, boss_state
	ld [hl], SPIDER_GO_UP_STATE

	; Make jump
	ld bc, SPIDER_GO_UP_IMPULSE_Y
	ld de, SPIDER_GO_UP_IMPULSE_X

	; Check spider pos. 
	; If on left half jump right else jump left
	call take_mid_boss_entity
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
		jr .rotate_to_jump

	.jump_right:
		ld a, [boss_looking_dir]
		or a
		jr z, .do_jump

	.rotate_to_jump:
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

	; Change sprite
	ld a, ENEMY_START_ENTITY_ID
	ld b, SWAP_MASK_SPRITE_JUMP_STAND
	ld c, SPIDER_NUM_ENTITIES
	call swap_sprite_by_mask

	; Set collisions
	ld hl, spider_jump_collisions
	ld c, SPIDER_NUM_ENTITIES
	call change_boss_collisions

	ret

manage_go_up_state:
	; Check roof
	call check_spider_roof
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

	; Change sprite
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

    ld hl, spider_roof_collisions
    ld c, SPIDER_NUM_ENTITIES
    call change_boss_collisions

	ld hl, boss_state
	ld [hl], SPIDER_ROOF_STATE

	ld hl, spider_shot_cooldown
	ld [hl], SPIDER_ROOF_STATE_SHOT_COOLDOWN

	; Set web hook sprites
	ld a, SPIDER_WEB_HOOK_ENTITY_ID
	ld b, SWAP_MASK_SPRITE_WEB_HOOK
	ld c, 2
	call swap_sprite_by_mask

	; Set web hook pos
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

	ret

manage_spider_dead_state:
	call check_ground_for_boss
	ret c

	ld d, SPIDER_ROOF_NUM_ENTITIES
	call reset_group_acc_y

	ld d, SPIDER_ROOF_NUM_ENTITIES
	call reset_group_vel

	call sys_sound_boss_death_effect
	call open_door
	ld hl, boss_dead
	ld [hl], 1

	ret

manage_stage_stransition_state:
	ld a, [boss_animation_counter]
	dec a
	ld [boss_animation_counter], a
	jr nz, .no_anim

	call animate_spider_mouth

	.no_anim:
	ld a, [boss_state_counter]
	dec a
	ld [boss_state_counter], a
	ret nz

	ld hl, boss_state
	ld [hl], SPIDER_ROOF_STATE

	ld hl, damaged_times
	ld [hl], DAMAGED_TIMES_TO_FALL

	ld hl, spider_shot_cooldown
	ld [hl], SPIDER_ROOF_STATE_SHOT_COOLDOWN

	ld hl, boss_animation_counter
	ld [hl], SPIDER_ROOF_STATE_WALK_ANIM_TIME

	ret

manage_roof_animation:
	ld a, [boss_animation_counter]
	dec a
	ld [boss_animation_counter], a
	ret nz

	call animate_legs_roof

	ld hl, boss_animation_counter
	ld [hl], SPIDER_ROOF_STATE_WALK_ANIM_TIME
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
	call animate_spider_mouth
	ret

animate_spider_mouth:
	ld a, ENEMY_START_ENTITY_ID + 3
	ld b, SPIDER_MOUTH_ANIM_MASK
	ld c, 1
	call swap_sprite_by_mask

	ld a, ENEMY_START_ENTITY_ID + 7
	ld b, SPIDER_MOUTH_ANIM_MASK
	ld c, 1
	call swap_sprite_by_mask

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

make_sure_spider_looks_at_player:
	call take_mid_boss_entity
	call man_entity_locate_v2
	inc h
	inc l
	ld b, [hl] ; B = SPIDER_POS_X

	ld a, PLAYER_BODY_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	ld a, [hl] ; A = PLAYER_POS_X
	add SPRITE_WIDTH/2

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
	call animate_spider_mouth
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

		call animate_spider_mouth
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
	call animate_spider_mouth
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

		call animate_spider_mouth
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

	; Change sprite
	ld b, SWAP_MASK_SPRITE_JUMP_STAND
	ld a, ENEMY_START_ENTITY_ID
	ld c, SPIDER_NUM_ENTITIES
	call swap_sprite_by_mask

	; Change collisions
	ld hl, spider_jump_collisions
	ld c, SPIDER_NUM_ENTITIES
	call change_boss_collisions

	ret

	.shot:
		; === COMPUTE BULLET POS ===
		ld a, ENEMY_START_ENTITY_ID + 7
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

		; Change sprite
		ld b, SWAP_MASK_SPRITE_JUMP_STAND
        ld c, SPIDER_NUM_ENTITIES
        ld a, ENEMY_START_ENTITY_ID
        call swap_sprite_by_mask

        ; Change collisions
        ld hl, spider_stand_collisions
        ld c, SPIDER_NUM_ENTITIES
        call change_boss_collisions

	ret

check_spider_roof:
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc h
	ld a, [hl]
	cp SPIDER_ROOF_Y
	ret