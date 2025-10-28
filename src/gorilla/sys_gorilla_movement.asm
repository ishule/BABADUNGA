INCLUDE "gorilla/gorilla_consts.inc"

SECTION "Gorilla Variables", WRAM0 
gorilla_state::          DS 1
gorilla_state_counter::  DS 1
gorilla_stage::          DS 1
gorilla_strikes_to_do::  DS 1

SECTION "Gorilla Movement Code", ROM0
; -----------------------
; sys_gorilla_movement
; Máquina de estados principal del gorila.
; -----------------------
sys_gorilla_movement::
    ld a, [gorilla_state]

    cp GORILLA_STAND_STATE
    jr z, .stand_state

    cp GORILLA_JUMP_STATE
    jr z, .jump_state

    cp GORILLA_JUMP_TO_STRIKE_STATE
    jr z, .jump_to_strike_state

    cp GORILLA_WAIT_STRIKE_STATE
    jr z, .wait_strike_state

    cp GORILLA_STRIKE_STATE
    jr z, .strike_state

    .stand_state:
        ld a, [gorilla_stage]
        or a
        jr nz, .stage_1_stand
        .stage_0_stand:
            call check_stage_change
            ret c

            call manage_stand_0_state
            ret
        .stage_1_stand:
            call manage_stand_1_state
            ret

    .jump_state:
        ld a, [gorilla_stage]
        or a
        jr nz, .stage_1_jump
        .stage_0_jump:
            call manage_jump_0_state
            ret
        .stage_1_jump:
            call manage_jump_1_state
            ret

    .jump_to_strike_state:
        call manage_jump_to_strike_state
        ret

    .wait_strike_state:
        push af 
        push hl
        ld a, ENEMY_START_ENTITY_ID 
        call man_entity_locate_v2
        inc l 
        inc l 
        res 0, [hl] ; Set flag to 0
        pop hl 
        pop af
        call manage_wait_strike_state
        ret

    .strike_state:
        push af 
        push hl
        ld a, ENEMY_START_ENTITY_ID 
        call man_entity_locate_v2
        inc l 
        inc l 
        res 0, [hl] ; Set flag to 0
        pop hl 
        pop af
        call shake_screen
        call manage_strike_state

    ret

check_stage_change:
    ld a, [boss_health]
    cp STAGE_CHANGE_LIFE
    ret nc

    .change_stage:
        call make_gorilla_eyes_white

        ld hl, gorilla_stage
        ld [hl], SECOND_STAGE

        ld hl, gorilla_state
        ld [hl], GORILLA_JUMP_TO_STRIKE_STATE

        ld bc, JUMP_STAGE_CHANGE_IMPULSE_Y
        ld de, JUMP_STAGE_CHANGE_IMPULSE_X

        ; Check is left or right
        call take_mid_boss_entity        
        call man_entity_locate_v2
        inc h
        inc l
        ld a, [hl]
        cp SCREEN_PIXEL_WIDTH/2
        jr c, .jump_right
        .jump_left:
            call positive_to_negative_DE
            ld a, [boss_looking_dir]
            or a
            jr nz, .do_jump
            jr .x_rotation

        .jump_right:
            ld a, [boss_looking_dir]
            or a
            jr z, .do_jump
            jr .x_rotation

        .x_rotation:
            push de
            push bc
            ld c, GORILLA_NUM_ENTITIES
            call rotate_boss_x
            pop bc
            pop de

        .do_jump:
        ld a, ENEMY_START_ENTITY_ID
        call man_entity_locate_v2
        ld a, GORILLA_NUM_ENTITIES
        call change_entity_group_vel


        ld a, ENEMY_START_ENTITY_ID
        call man_entity_locate_v2
        ld bc, JUMP_GRAVITY
        ld d, GORILLA_NUM_ENTITIES
        call change_entity_group_acc_y
        
        ld b, SWAP_MASK_SPRITE_STAND_JUMP
        ld c, GORILLA_NUM_ENTITIES
        ld a, ENEMY_START_ENTITY_ID
        call swap_sprite_by_mask

    ret

manage_stand_0_state:
    ld a, [gorilla_state_counter]
    dec a
    ld [gorilla_state_counter], a
    ret nz

    ; Do jump
    ld hl, gorilla_state
    ld [hl], GORILLA_JUMP_STATE

    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld bc, JUMP_GRAVITY
    ld d, GORILLA_NUM_ENTITIES
    call change_entity_group_acc_y

    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld bc, JUMP_IMPULSE_Y
    ld de, JUMP_IMPULSE_X

    ld a, [boss_looking_dir]
    or a
    call nz, positive_to_negative_DE
    ld a, GORILLA_NUM_ENTITIES
    call change_entity_group_vel

    ld b, SWAP_MASK_SPRITE_STAND_JUMP
    ld c, GORILLA_NUM_ENTITIES
    ld a, ENEMY_START_ENTITY_ID
    call swap_sprite_by_mask

    ld hl, gorilla_jump_collisions
    ld c, GORILLA_NUM_ENTITIES
    call change_boss_collisions

    ret


manage_jump_0_state:
    call take_mid_boss_entity
    call check_wall_for_boss
    jr c, .no_wall_collision
    .wall_collision:
        ld d, GORILLA_NUM_ENTITIES
        call reset_group_vel_x
        ld c, GORILLA_NUM_ENTITIES
        call rotate_boss_x


    .no_wall_collision:
    call check_ground_for_boss
    ret c

    ld d, GORILLA_NUM_ENTITIES
    call reset_group_vel
    ld d, GORILLA_NUM_ENTITIES
    call reset_group_acc_y

    ld hl, gorilla_state
    ld [hl], GORILLA_STAND_STATE

    ld hl, gorilla_state_counter
    ld [hl], STAND_TIME

    ld b, SWAP_MASK_SPRITE_STAND_JUMP
    ld c, GORILLA_NUM_ENTITIES
    ld a, ENEMY_START_ENTITY_ID
    call swap_sprite_by_mask

    ld hl, gorilla_stand_collisions
    ld c, GORILLA_NUM_ENTITIES
    call change_boss_collisions

    ret

manage_jump_to_strike_state:
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc h
    inc h
    inc h
    inc l
    ld a, [hl]
    or a
    jr z, .at_mid

    ; Check mid screen
    call take_mid_boss_entity
    call man_entity_locate_v2
    inc h
    inc l
    ld c, [hl]
    ld a, [boss_looking_dir]
    or a
    jr nz, .looking_left
    .looking_right:
        ld a, c
        ld c, SCREEN_PIXEL_WIDTH/2
        cp c
        ret c
        jr .reached_mid

    .looking_left:
        ld a, SCREEN_PIXEL_WIDTH/2
        cp c
        ret c

    .reached_mid:
    ld d, GORILLA_NUM_ENTITIES
    call reset_group_vel
    ret

    .at_mid:
    call check_ground_for_boss
    ret c

    ld d, GORILLA_NUM_ENTITIES
    call reset_group_vel_y
    ld d, GORILLA_NUM_ENTITIES
    call reset_group_acc_y

    ld hl, gorilla_state
    ld [hl], GORILLA_WAIT_STRIKE_STATE

    ld hl, gorilla_state_counter
    ld [hl], WAIT_STRIKE_TIME

    ld hl, gorilla_strikes_to_do
    ld [hl], NUMBER_OF_STRIKES

    ld b, SWAP_MASK_SPRITE_JUMP_UP_STRIKE_LEFT
    ld c, GORILLA_NUM_ENTITIES/2
    ld a, ENEMY_START_ENTITY_ID
    call swap_sprite_by_mask

    ld b, SWAP_MASK_SPRITE_JUMP_UP_STRIKE_RIGHT
    ld c, GORILLA_NUM_ENTITIES/2
    ld a, ENEMY_START_ENTITY_ID + GORILLA_NUM_ENTITIES/2
    call swap_sprite_by_mask

    ld a, [boss_looking_dir]
    or a
    jr z, .do_not_rotate
    .make_rotation:
        ld c, GORILLA_NUM_ENTITIES
        call rotate_boss_x
    .do_not_rotate:
    ld c, GORILLA_NUM_ENTITIES/2
    ld a, ENEMY_START_ENTITY_ID + GORILLA_NUM_ENTITIES/2
    call flip_boss_x
    call swap_x_right_half_boss_entity

    ld hl, gorilla_up_strike_collisions
    ld c, GORILLA_NUM_ENTITIES
    call change_boss_collisions

    ret

manage_wait_strike_state:
    ld a, [gorilla_state_counter]
    dec a
    ld [gorilla_state_counter], a
    ret nz

    ld hl, gorilla_state
    ld [hl], GORILLA_STRIKE_STATE

    ld hl, gorilla_state_counter
    ld [hl], TIME_BETWEEN_STRIKES

    ld b, SWAP_MASK_SPRITE_STRIKE
    ld c, GORILLA_NUM_ENTITIES
    ld a, ENEMY_START_ENTITY_ID
    call swap_sprite_by_mask

    ld hl, gorilla_down_strike_collisions
    ld c, GORILLA_NUM_ENTITIES
    call change_boss_collisions

    ret

manage_strike_state:
    ld a, [gorilla_state_counter]
    dec a
    ld [gorilla_state_counter], a
    ret nz

    ld a, [gorilla_strikes_to_do]
    dec a
    ld [gorilla_strikes_to_do], a
    bit 0, a
    jr nz, .first_strike
    .second_strike:
        ld hl, gorilla_state_counter
        ld [hl], WAIT_STRIKE_TIME
        call drop_stalactites
        jr .end_of_strike
        

    .first_strike:
        ld hl, gorilla_state_counter
        ld [hl], TIME_BETWEEN_STRIKES

    .end_of_strike:
    ld a, [gorilla_strikes_to_do]
    or a
    jr nz, .continue_striking

    .finished_striking:
        ld hl, gorilla_state
        ld [hl], GORILLA_STAND_STATE

        ld hl, gorilla_state_counter
        ld [hl], STAND_TIME_STAGE_1

        ; Change Skin
        ld b, SWAP_MASK_SPRITE_DOWN_STRIKE_LEFT_STAND
        ld c, GORILLA_NUM_ENTITIES/2
        ld a, ENEMY_START_ENTITY_ID
        call swap_sprite_by_mask

        ld b, SWAP_MASK_SPRITE_DOWN_STRIKE_RIGHT_STAND
        ld c, GORILLA_NUM_ENTITIES/2
        ld a, ENEMY_START_ENTITY_ID + GORILLA_NUM_ENTITIES/2
        call swap_sprite_by_mask

        ld c, GORILLA_NUM_ENTITIES/2
        ld a, ENEMY_START_ENTITY_ID + GORILLA_NUM_ENTITIES/2
        call flip_boss_x
        call swap_x_right_half_boss_entity

        ld hl, gorilla_stand_collisions
        ld c, GORILLA_NUM_ENTITIES
        call change_boss_collisions

        ret

    .continue_striking:
        ld hl, gorilla_state
        ld [hl], GORILLA_WAIT_STRIKE_STATE

        ld b, SWAP_MASK_SPRITE_STRIKE
        ld c, GORILLA_NUM_ENTITIES
        ld a, ENEMY_START_ENTITY_ID
        call swap_sprite_by_mask

        ld hl, gorilla_up_strike_collisions
        ld c, GORILLA_NUM_ENTITIES
        call change_boss_collisions

        ret

manage_stand_1_state:
    ld a, [gorilla_state_counter]
    dec a
    ld [gorilla_state_counter], a
    ret nz

    ; Do jump
    ld hl, gorilla_state
    ld [hl], GORILLA_JUMP_STATE

    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld bc, JUMP_GRAVITY_STAGE_1
    ld d, GORILLA_NUM_ENTITIES
    call change_entity_group_acc_y

    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld bc, JUMP_IMPULSE_STAGE_1_Y
    ld de, JUMP_IMPULSE_STAGE_1_X

    ld a, [boss_looking_dir]
    or a
    call nz, positive_to_negative_DE
    ld a, GORILLA_NUM_ENTITIES
    call change_entity_group_vel

    ld b, SWAP_MASK_SPRITE_STAND_JUMP
    ld c, GORILLA_NUM_ENTITIES
    ld a, ENEMY_START_ENTITY_ID
    call swap_sprite_by_mask

    ld hl, gorilla_jump_collisions
    ld c, GORILLA_NUM_ENTITIES
    call change_boss_collisions
    ret

manage_jump_1_state:
    call take_mid_boss_entity
    call check_wall_for_boss
    jr c, .no_wall_collision
    .wall_collision:
        ld d, GORILLA_NUM_ENTITIES
        call reset_group_vel_x
        ld c, GORILLA_NUM_ENTITIES
        call rotate_boss_x


    .no_wall_collision:
    call check_ground_for_boss
    ret c

    call throw_rocks

    ld d, GORILLA_NUM_ENTITIES
    call reset_group_vel
    ld d, GORILLA_NUM_ENTITIES
    call reset_group_acc_y

    ld hl, gorilla_state
    ld [hl], GORILLA_STAND_STATE

    ld hl, gorilla_state_counter
    ld [hl], STAND_TIME_STAGE_1

    ld b, SWAP_MASK_SPRITE_STAND_JUMP
    ld c, GORILLA_NUM_ENTITIES
    ld a, ENEMY_START_ENTITY_ID
    call swap_sprite_by_mask

    ld hl, gorilla_stand_collisions
    ld c, GORILLA_NUM_ENTITIES
    call change_boss_collisions
    ret

; ====== UTILS ========

throw_rocks:
    ;spawn rocks
    call take_mid_boss_entity
    call man_entity_locate_v2
    inc h
    ld a, [hl+]
    add SPRITE_HEIGHT
    ld b, a
    
    ld a, [hl]
    sub SPRITE_WIDTH/2
    ld c, a

    ld de, gorilla_bullet_0_preset
    ld a, LEFT_SHOT_DIRECTION
    push bc
    call shot_bullet_for_preset
    pop bc

    ld de, gorilla_bullet_0_preset
    ld a, RIGHT_SHOT_DIRECTION
    push bc
    call shot_bullet_for_preset
    pop bc

    ld a, [num_entities_alive]
    dec a
    dec a
    call man_entity_locate_v2
    ld bc, ROCK_IMPULSE_Y
    ld d, 2
    call change_entity_group_vel_y

    ld a, [num_entities_alive]
    dec a
    dec a
    call man_entity_locate_v2
    ld bc, ROCK_GRAVITY
    ld d, 2
    call change_entity_group_acc_y


    ret


drop_stalactites:
    ld a, [gorilla_strikes_to_do]
    or a
    jr z, .third_fall
    cp 2
    jr z, .second_fall
    .first_fall:
        ld a, STALACTITES_START_ENTITY_ID + 10
        jr .locate_group
    .second_fall:
        ld a, STALACTITES_START_ENTITY_ID + 5
        jr .locate_group
    .third_fall:
        ld a, STALACTITES_START_ENTITY_ID

    .locate_group:
    call man_entity_locate_v2

    ld bc, STALACTITES_GRAVITY
    ld d, NUMBER_OF_STALACTITES_PER_STRIKE

    ;; Desactivar flag STILL BULLET
    push hl 
    .loop:
        inc l 
        inc l 
        res 5, [hl]
        inc l
        inc l
        dec d
        jr nz, .loop  


    ld d, NUMBER_OF_STALACTITES_PER_STRIKE
    pop hl


    call change_entity_group_acc_y

    ret


make_gorilla_eyes_white:
    call wait_vblank
    ld hl, GORILLA_HEAD_STAND_TILE_ADDRESS
    ld de, GORILLA_EYES_STAND_OFFSET
    add hl, de
    ld a, [hl]
    xor GORILLA_EYES_TO_WHITE_MASK
    ld [hl], a

    ret