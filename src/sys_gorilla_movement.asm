INCLUDE "consts.inc"

SECTION "Gorilla Movement Vars", WRAM0
gorilla_jumping_flag: DS 1 ; 1 = está en el suelo  0 = en el aire

SECTION "Gorilla Movement Code", ROM0



sys_gorilla_movement::
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld bc, GORILLA_SPEED_NEGATIVE
    ld d, $08
    call change_entity_group_vel_x
    ret

sys_gorilla_movement_v2::

    ; Comprobamos si está en el aire
    ld a, [gorilla_jumping_flag]
    cp 1
    jr z, .apply_gravity   ; si ya está saltando, solo gravedad

    ; Si no está saltando, aplica el impulso inicial
    ld a, $01
    call man_entity_locate_v2 
    ld bc, GORILLA_JUMP_SPEED
    ld de, GORILLA_SPEED_NEGATIVE
    ld a, $08
    call change_entity_group_vel

    ld a, 0
    ld [gorilla_jumping_flag], a  ; marcar que ya está en el aire

.apply_gravity:
    ld a, $01
    call man_entity_locate_v2
    ld bc, GORILLA_GRAVITY
    ld de, $0000
    ld a, $08
    call change_entity_group_acc

    ld d, $08
    ld e, $01 
    call check_ground_collision

    ret
