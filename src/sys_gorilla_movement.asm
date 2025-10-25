INCLUDE "gorilla_consts.inc"

SECTION "Gorilla Variables", WRAM0 
gorilla_looking_dir::    DS 1  ; 0 = derecha, 1 = izquierda
gorilla_state::          DS 1
gorilla_state_counter::  DS 1
gorilla_stage::          DS 1

SECTION "Gorilla Movement Code", ROM0
; -----------------------
; sys_gorilla_movement
; Máquina de estados principal del gorila.
; -----------------------
sys_gorilla_movement::
    ; Check stage change
    ; TODO: Comprobar vida y cambiar fase
    ld a, [gorilla_stage]
    or a
    jr nz .switch_state
    
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc h
    inc h
    inc l
    inc l
    ld a, [hl]
    cp STAGE_CHANGE_LIFE

    .switch_state:
    ld a, [gorilla_state]

    cp GORILLA_STAND_STATE
    jr z, .stand_state

    cp GORILLA_JUMP_STATE
    jr z, .jump_state

    cp GORILLA_STRIKE_STATE
    jr z, .strike_state

    .stand_state:
        ld a, [gorilla_stage]
        or a
        jr nz, .stage_1_stand
        .stage_0_stand:
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

    .strike_state:
        call manage_strike_state

    ret


manage_stand_0_state:
    ld a, [gorilla_state_counter]
    dec a
    ld [gorilla_state_counter], a
    ret nz

    ; Do jump
    ld hl, gorilla_state
    ld [hl], GORILLA_JUMP_0_STATE

    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld bc, JUMP_GRAVITY
    ld d, GORILLA_NUM_ENTITIES
    call change_entity_group_acc_y

    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld bc, JUMP_IMPULSE_Y
    ld de, JUMP_IMPULSE_X

    ld a, [gorilla_looking_dir]
    or a
    call nz, positive_to_negative_DE
    ld a, GORILLA_NUM_ENTITIES
    call change_entity_group_vel

    ld b, SWAP_MASK_SPRITE_STAND_JUMP
    call swap_sprite_by_mask

    ret


manage_jump_0_state:
    call check_wall
    jr c, .no_wall_collision
    .wall_collision:
        call reset_vel_x

        ld a, [gorilla_looking_dir]
        xor 1
        ld [gorilla_looking_dir], a

        call flip_gorilla_x
        call swap_x_gorilla_entity


    .no_wall_collision:
    call check_ground
    ret c

    call reset_vel
    call reset_gravity

    ld hl, gorilla_state
    ld [hl], GORILLA_STAND_0_STATE

    ld hl, gorilla_state_counter
    ld [hl], STAND_TIME

    ld b, SWAP_MASK_SPRITE_STAND_JUMP
    call swap_sprite_by_mask

    ret

manage_strike_state:
    ret

manage_stand_1_state:
    ret

manage_jump_1_state:
    ret

; ====== UTILS ========
check_ground:
    ld a, ENEMY_START_ENTITY_ID + 2
    call man_entity_locate_v2
    inc h
    ld a, [hl]
    cp GROUND_Y
    ret

check_wall:
    ld a, ENEMY_START_ENTITY_ID + 5
    call man_entity_locate_v2
    inc h
    inc l
    ld c, [hl]
    ld a, [gorilla_looking_dir]
    or a
    jr nz, .looking_left
    .looking_right:
        ld a, c
        add SPRITE_WIDTH
        ld c, WALL_LEFT_Y
        cp c
        ret

    .looking_left:
        ld a, WALL_LEFT_X
        cp c
        ret


reset_vel_x:
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld bc, 0
    ld d, GORILLA_NUM_ENTITIES
    call change_entity_group_vel_x
    ret

reset_vel:
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld bc, 0
    ld de, 0
    ld a, GORILLA_NUM_ENTITIES
    call change_entity_group_vel
    ret

reset_gravity:
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld bc, 0
    ld de, 0
    ld a, GORILLA_NUM_ENTITIES
    call change_entity_group_acc_y
    ret


; ======= ANIMATIONS =========
; INPUT
;  b -> swap_mask
swap_sprite_by_mask:
    ld c, GORILLA_NUM_ENTITIES
    ld de, CMP_SIZE

    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc h
    inc l
    inc l
    .loop:
        ld a, [hl]
        xor b
        ld [hl], a

        add hl, de
        dec c
        jr nz, .loop

    ret


rotate_gorilla_x::
    call flip_gorilla_x
    call swap_x_gorilla_entity
    ret

flip_gorilla_x:
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc h
    inc l
    inc l
    inc l
    ld c, GORILLA_NUM_ENTITIES
    
    .loop:
        ld a, [hl]
        xor SPRITE_ATTR_FLIP_X_MASK
        ld [hl], a       
         
        ld de, CMP_SIZE
        add hl, de

        dec c
        jr nz, .loop

    ret

swap_x_gorilla_entity:
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