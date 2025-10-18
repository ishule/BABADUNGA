INCLUDE "consts.inc"

SECTION "Gorilla Movement Vars", WRAM0
gorilla_jumping_flag: DS 1 ; 1 = está en el suelo  0 = en el aire

SECTION "Snake Movement Vars",WRAM0
snake_flags:: DS 1 ;; Bit 0, 0=Derecha, 1=Izquierda (Flip y disparo)
                   ;; Bit 1 y 2, 00=INIT, 01=SHOOT, 10=MOVE, 11==TURN
                   ;; Bit 3 y 4, 00=2 disparos, 01=1 disparo, 00=0 disparos
snake_target_x:: DS 1 ;;Provisional hasta que haya colisiones
;; Constantes de máscara
def MASK_DIRECTION equ %00000001
def MASK_STATE equ %00000110
def MASK_SHOT_COUNT equ %00011000
;; Valores de estado
def STATE_INIT equ 0
def STATE_SHOOT equ 2
def STATE_MOVE equ 4
def STATE_TURN equ 6
SECTION "Gorilla Movement Code", ROM0


flip_sprite::


sys_gorilla_movement::
    ld a, $01
    call man_entity_locate 
    ld b, $00
    ld c, GORILLA_SPEED
    ld d, $08
    call change_entity_group_vel
    ret

sys_gorilla_movement_v2::

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

    ld a, 0
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

sys_snake_movement::
    ld a,[snake_flags]
    and MASK_STATE

    cp STATE_INIT
    jr z,.init_state

    cp STATE_SHOOT
    jr z,.shoot_state

    cp STATE_MOVE
    jr z,.move_state

    cp STATE_TURN
    jr z,.turn_state
    ret

.init_state: ;; Pasa a shoot state
    
    ld a,STATE_SHOOT
    ld [snake_flags],a
    ret
.shoot_state: ;; Pasa a move state
    
    ld a,STATE_MOVE
    ld [snake_flags],a
    ret
.move_state: ;; Se mueve hasta colisión o centinela en caso de que no hayan colisiones,pasa a turn state
    ld a, $01
    call man_entity_locate 
    ld b, $00
    ld a,[snake_flags]
    bit 0,a
    ld c, SNAKE_SPEED
    jr nz,.left
    ld c,-SNAKE_SPEED ;;right
    .left
    ld d, $04
    call change_entity_group_vel
    ld a,STATE_TURN
    ld [snake_flags],a
    ret
.turn_state: ;; Gira el muñeco y pasa a shoot state
    ld a,[snake_flags]
    bit 0,a
    ld a,SPRITE_ATTR_NO_FLIP
    jr z,.setup_flip_x
    ld a,SPRITE_ATTR_FLIP_X
.setup_flip_x
    ;push af
    ;ld a,$01
    ;call man_entity_locate
    ;ld h,CMP_SPRITES_H
    ;ld d,4
.flip_loop:
    ;push de
    ;push hl
    ;pop af

    ;ld l,3
    ;add a,l
    ;ld l,a

    ;pop af

    ;ld [hl],a

    ;pop hl
    ;ld l,4
    ;add hl,de
    ;ld h,$C1
    ;pop de
    ;dec d
    ;jr nz,.flip_loop
    ;pop af
    
    ;ld a,STATE_SHOOT
    ;ld [snake_flags],a
    ret
