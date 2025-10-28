INCLUDE "snake/snake_consts.inc"

SECTION "Snake Variables", WRAM0
snake_state::             DS 1 ; 0:stand | 1:walk
snake_shot_cooldown::     DS 1
snake_state_counter::     DS 1
snake_animation_counter:: DS 1 
snake_stage::             DS 1 ; 0:fase 0 | 1:fase 1

SECTION "Snake Code", ROM0

sys_snake_movement::
	; === Check state ==
	ld a, [snake_state]

	cp SNAKE_STAND_STATE
	jr z, .stand_state

	cp SNAKE_WALK_STATE
	jr z, .walk_state

	.stand_state:
		call manage_snake_stand_state
		ret

	.walk_state:
		call manage_walk_state
		
	ret

manage_snake_stand_state:
	ld a, [snake_state_counter]
	dec a
	ld [snake_state_counter], a
	ret nz

	; STATE CHANGED
	ld hl, snake_state
	ld [hl], SNAKE_WALK_STATE

	ld hl, snake_animation_counter
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

	ld hl, snake_state
    ld [hl], SNAKE_STAND_STATE

    ld hl, snake_state_counter
    ld [hl], STAND_TIME

    ld hl, snake_shot_cooldown
    ld [hl], SNAKE_SHOT_COOLDOWN

    ld d, SNAKE_NUM_ENTITIES
    call reset_group_acc_x

    ld d, SNAKE_NUM_ENTITIES
    call reset_group_vel_x

    call rotate_snake

	ret

manage_walk_animation:
	ld a, [snake_animation_counter]
	dec a
	ld [snake_animation_counter], a
	ret nz

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

	ld hl, snake_animation_counter
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