INCLUDE "consts.inc"

SECTION "Gorilla Movement Vars", WRAM0
gorilla_jumping_flag: DS 1 ; 0 = está en el suelo  1 = en el aire

SECTION "Gorilla Movement Code", ROM0


sys_gorilla_movement::

    ; Comprobamos si está en el aire
    ld a, [gorilla_jumping_flag]
    cp 1
    jr z, .apply_gravity   ; si ya está saltando, solo gravedad

    ; Si no está saltando, aplica el impulso inicial
    ld a, $01
    call man_entity_locate 
    ld b, GORILLA_JUMP_SPEED
    ld c, GORILLA_SPEED_NEGATIVE
    ld d, $08
    call change_entity_group_vel

    ld a, 1
    ld [gorilla_jumping_flag], a  ; marcar que ya está en el aire

.apply_gravity:
    ld a, $01
    call man_entity_locate
    ld b, GORILLA_GRAVITY
    ld c, $00
    ld d, $08
    call change_entity_group_acc

    ld d, $08
    ld e, $01 
    call check_ground_collision

    ret

