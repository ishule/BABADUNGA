INCLUDE "snake/snake_consts.inc"

SECTION "Snake Variables", WRAM0

snake_shot_cooldown::     DS 1
shots_counter::           DS 1 

SECTION "Snake Code", ROM0

check_snake_dead:
	ld e, DEAD_ANIM_TIME
	ld d, SNAKE_NUM_ENTITIES
	call check_dead_state
	ret nc 

	call animate_snake_mouth
	call sys_sound_boss_scream_effect
	

	; TODO: deactivate collisions

	ld hl, boss_state
	ld [hl], SNAKE_DEAD_STATE

	ret

sys_snake_movement::
	ld a, [boss_dead]
	or a
	ret nz

	call check_snake_dead

	; === Check state ==
	ld a, [boss_state]

	cp SNAKE_ENTER_STATE
	jr z, .enter_state

	cp SNAKE_YELL_STATE
	jr z, .yell_state

	cp SNAKE_STAND_STATE
	jr z, .stand_state

	cp SNAKE_WALK_STATE
	jr z, .walk_state

	cp SNAKE_STAGE_TRANSITION_STATE
	jr z, .stage_transition_state

	cp SNAKE_DEAD_STATE
	jr z, .snake_dead_state

	.enter_state:
		call manage_snake_enter_state
		ret

	.yell_state:
		call manage_yell_state
		ret

	.stand_state:
		call manage_snake_stand_state
		ret

	.walk_state:
		call manage_walk_state
		ret

	.stage_transition_state:
		call manage_stage_transition
		ret

	.snake_dead_state:
		call manage_dead_state
		
	ret

manage_snake_enter_state:
	call manage_walk_animation

	.skip_animation:
	ld a, MOUTH_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	ld a,  SNAKE_SPAWN_POINT_X
	cp [hl]
	ret c

	ld d, SNAKE_NUM_ENTITIES
	call reset_group_vel_x

	ld hl, boss_state_counter
	ld [hl], ENTER_YELL_TIME

	ld hl, boss_animation_counter
	ld [hl], SNAKE_YELL_ANIM_TIME

	call animate_snake_mouth

	call sys_sound_boss_scream_effect

	ld hl, boss_state
	ld [hl], SNAKE_YELL_STATE

	ret

manage_yell_state:
	ld a, [boss_animation_counter]
	dec a
	ld [boss_animation_counter], a
	jr nz, .skip_animation

	call animate_snake_mouth

	.skip_animation:
	ld a, [boss_state_counter]
	dec a
	ld [boss_state_counter], a
	ret nz

	ld d, SNAKE_NUM_ENTITIES
    ld e, SNAKE_DAMAGE
    call init_boss_info

    ld hl, boss_state
    ld [hl], SNAKE_STAND_STATE

    ld hl, boss_state_counter
    ld [hl], 10

	ret

manage_snake_stand_state:
	ld a, [boss_stage]
	or a
	jr nz, .stage_1
	
	ld a, [boss_health]
	cp SNAKE_STAGE_CHANGE_HEALTH
	jr nc, .stage_0
	.change_stage:
		ld hl, boss_stage
		ld [hl], 1
		ld hl, boss_state
		ld [hl], SNAKE_STAGE_TRANSITION_STATE

		call animate_snake_mouth
		
		ld hl, boss_state_counter
		ld [hl], STAGE_TRANSITION_TIME

		ld hl, boss_animation_counter
		ld [hl], SNAKE_YELL_ANIM_TIME

		call sys_sound_boss_scream_effect

		ret


	.stage_1:
		call manage_snake_shot
	.stage_0:

	ld a, [boss_state_counter]
	dec a
	ld [boss_state_counter], a
	ret nz

	; STATE CHANGED
	ld hl, boss_state
	ld [hl], SNAKE_WALK_STATE

	ld hl, boss_animation_counter
	ld [hl], SNAKE_WALK_ANIM_TIME

	; APPLY movement
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld d, SNAKE_NUM_ENTITIES
	ld bc, SPIDER_MOVE_ACCELERATION
	ld a, [boss_looking_dir]
	or a
	jr z, .skip_conversion
		call positive_to_negative_BC
	.skip_conversion:
	call change_entity_group_acc_x
	ret

manage_walk_state:
	; CHECK WALL
	ld a, [boss_looking_dir]
    or a
    jr nz, .looking_left
    .looking_right:
        ld a, ENEMY_START_ENTITY_ID + 5
        jr .endif
    .looking_left:
        ld a, ENEMY_START_ENTITY_ID + 4

    .endif:
    call check_wall_for_boss
    jr nc, .stage_change

	; ANIMATE
	call manage_walk_animation	
	ret

	.stage_change:

	ld hl, boss_state
    ld [hl], SNAKE_STAND_STATE

    ld hl, boss_state_counter
    ld [hl], STAND_TIME

    ld hl, snake_shot_cooldown
    ld [hl], SNAKE_SHOT_COOLDOWN

    ld d, SNAKE_NUM_ENTITIES
    call reset_group_acc_x

    ld d, SNAKE_NUM_ENTITIES
    call reset_group_vel_x

    call rotate_snake

    ld hl, shots_counter
    ld [hl], 0

	ret

manage_stage_transition:
	ld a, [boss_animation_counter]
	dec a
	ld [boss_animation_counter], a
	jr nz, .skip_animation
	.shut_mouth:
		call animate_snake_mouth
	.skip_animation:
	ld a, [boss_state_counter]
	dec a
	ld [boss_state_counter], a
	ret nz

	ld hl, boss_state_counter
	ld [hl], STAND_TIME

	ld hl, boss_state
	ld [hl], SNAKE_STAND_STATE

	ret

manage_dead_state:

	ld a, [boss_state_counter]
	or a
	jr z, .run
	dec a
	ld [boss_state_counter], a
	ret nz
	call animate_snake_mouth

	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld bc, SNAKE_SCAPE_SPEED
	ld d, SNAKE_NUM_ENTITIES
	call change_entity_group_vel_x

	.run:
	call manage_walk_animation

	ld a, MOUTH_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	ld a,  SNAKE_ENTER_POINT_X
	cp [hl]
	ret nc

	ld d, SNAKE_NUM_ENTITIES
	call reset_group_vel_x

	ld hl, boss_dead
	ld [hl], 1
	
	call open_door

	ret



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UTILS
animate_snake_mouth:
	ld a, TAIL_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	inc l
	ld a, [hl]
	cp SNAKE_TAIL_UP_TILE_ID
	jr z, .skip_animation
	call animate_snake_walk
	.skip_animation:

	ld a, HEAD_ENTITY_ID
	ld c, 1
	ld b, SWAP_MASK_HEAD
	call swap_sprite_by_mask

	ld a, MOUTH_ENTITY_ID
	ld c, 1
	ld b, SWAP_MASK_MOUTH
	call swap_sprite_by_mask

	ld a, NECK_ENTITY_ID
	ld c, 1
	ld b, SWAP_MASK_NECK_L
	call swap_sprite_by_mask

	ld a, NECK_ENTITY_ID + 1
	ld c, 1
	ld b, SWAP_MASK_NECK_R
	call swap_sprite_by_mask

	ld a, BODY_ENTITY_ID + 1
	ld c, 1
	ld b, SWAP_MASK_BODY_NECK
	call swap_sprite_by_mask
	ld a, BODY_ENTITY_ID + 1
	ld c, 1
	call flip_boss_x

	ret

animate_snake_walk:
	ld a, TAIL_ENTITY_ID
	ld c, 1
	ld b, SWAP_MASK_TAILS
	call swap_sprite_by_mask

	ld a, NECK_ENTITY_ID
	ld c, 2
	ld b, SWAP_MASK_IDLE_WALK
	call swap_sprite_by_mask

	ld a, BODY_ENTITY_ID
	ld c, 2
	call flip_boss_x

	ret

manage_walk_animation:
	ld a, [boss_animation_counter]
	dec a
	ld [boss_animation_counter], a
	ret nz

	call animate_snake_walk

	ld hl, boss_animation_counter
    ld [hl], SNAKE_WALK_ANIM_TIME

	ret

rotate_snake::
	ld c, SNAKE_NUM_ENTITIES
    call rotate_boss_x
    ld a, TAIL_ENTITY_ID
    call man_entity_locate_v2
    inc h
    inc l
    ld c, [hl]
    dec l
    dec h

    ld a, [boss_looking_dir]
    or a
    jr z, .looking_right
    .looking_left:
    	ld a, c
	    add SPRITE_WIDTH*5
	    ld c, a
	    jr .move_tail
    .looking_right:
    	ld a, c
    	sub SPRITE_WIDTH*5
    	ld c, a
    .move_tail:
    call change_entity_pos_x
	
	ret

manage_snake_shot:
	ld a, [snake_shot_cooldown]
	dec a
	ld [snake_shot_cooldown], a
	jr z, .skip_animation

	cp SHOT_ANIM_TIME
	ret nz

	ld a, [shots_counter]
	cp 3
	ret z

	call animate_snake_mouth
	ret


	.skip_animation:
	ld a, [shots_counter]
	inc a
	ld [shots_counter], a

	ld a, MOUTH_ENTITY_ID
	call man_entity_locate_v2
	inc h
	ld b, [hl]
	inc l
	ld c, [hl]

	ld a, [boss_looking_dir]
	or a
	jr z, .looking_right
	.looking_left:
		ld a, LEFT_SHOT_DIRECTION
		jr .shot_bullet
	.looking_right:
		ld a, RIGHT_SHOT_DIRECTION

	.shot_bullet:
	ld de, snake_bullet_preset
	push af
	call sys_sound_spit_effect
	pop af
	call shot_bullet_for_preset

	ld a, [num_entities_alive]
	dec a
	call man_entity_locate_v2
	
	ld a, [shots_counter]
	cp 1
	jr z, .first_shot
	cp 2
	jr z, .second_shot
	cp 3
	jr z, .third_shot

	.first_shot:
		ld bc, SNAKE_SHOT_1_V_Y
		ld de, SNAKE_SHOT_1_V_X
		jr .end_switch
	.second_shot:
		ld bc, SNAKE_SHOT_2_V_Y
		ld de, SNAKE_SHOT_2_V_X
		jr .end_switch
	.third_shot:
		ld bc, SNAKE_SHOT_3_V_Y
		ld de, SNAKE_SHOT_3_V_X

	.end_switch:
	ld a, [boss_looking_dir]
	or a
	jr z, .skip_conversion
		call positive_to_negative_DE
	.skip_conversion:
	call change_entity_vel
	
	dec l
	dec l
	dec l

	ld bc, BULLETS_GRAVITY
	call change_entity_acc_y

	ld hl, snake_shot_cooldown
	ld [hl], SNAKE_SHOT_COOLDOWN

	call animate_snake_mouth

	ret 