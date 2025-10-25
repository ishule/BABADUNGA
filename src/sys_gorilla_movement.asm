INCLUDE "gorilla_consts.inc"

SECTION "Gorilla Variables", WRAM0 
gorilla_on_ground_flag:: DS 1 ; 1 = está en el suelo  0 = en el aire
gorilla_looking_dir::    DS 1  ; 0 = derecha, 1 = izquierda
gorilla_state::          DS 1
gorilla_state_counter::  DS 1

SECTION "Gorilla Movement Code", ROM0
;; En check_collision_ground se usa el gorilla_on_ground_flag en tener colisiones hay que eliminar eso
;;NOTAS: SNAKE_FLAGS Y SNAKE_COUNTER SE DEBEN DE INICIALIZAR EN BOSS.ASM PARA REUTILIZARLO PARA CADA BOSS

; -----------------------
; sys_gorilla_movement
; Máquina de estados principal del gorila.
; -----------------------
sys_gorilla_movement::
    ld a, [gorilla_state]

    cp GORILLA_STAND_0_STATE
    jr z, .stand_0_state

    cp GORILLA_JUMP_0_STATE
    jr z, .jump_0_state

    cp GORILLA_STRIKE_STATE
    jr z, .strike_state

    cp GORILLA_STAND_0_STATE
    jr z, .stand_0_state

    cp GORILLA_JUMP_0_STATE
    jr z, .jump_0_state

    .stand_0_state:
        call manage_stand_0_state
        ret

    .jump_0_state:
        call manage_jump_0_state
        ret

    .strike_state:
        call manage_strike_state
        ret

    .stand_1_state:
        call manage_stand_1_state
        ret

    .jump_1_state:
        call manage_jump_1_state

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
    ld bc, JUMP_SPEED_Y
    ld de, JUMP_SPEED_X
    ld a, GORILLA_NUM_ENTITIES
    call change_entity_group_vel

    call swap_sprite_stand_jump

    ret


manage_jump_0_state:
    call check_ground
    ret c

    call reset_vel
    call reset_gravity

    ld hl, gorilla_state
    ld [hl], GORILLA_STAND_0_STATE

    ld hl, gorilla_state_counter
    ld [hl], STAND_TIME

    call swap_sprite_stand_jump

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
swap_sprite_stand_jump:
    ld c, GORILLA_NUM_ENTITIES
    ld de, CMP_SIZE

    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc h
    inc l
    inc l
    .loop:
        ld a, [hl]
        xor MASK_SPRITE_STAND_JUMP
        ld [hl], a

        add hl, de
        dec c
        jr nz, .loop

    ret


