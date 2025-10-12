INCLUDE "consts.inc"


SECTION "Gorilla Movement Code", ROM0

sys_gorilla_movement::

    ; Aplicamos el impulso de salto
    ld a, $01
    call man_entity_locate 
    ld b, PLAYER_JUMP_SPEED
    ld c, GORILLA_SPEED_NEGATIVE   
    ld d, $08
    call change_entity_group_vel

    ; Aplicamos gravedad
    ld a, $01
    call man_entity_locate
    ld b, PLAYER_GRAVITY
    ld c, $00   
    ld d, $08
    call change_entity_group_acc

    ret
