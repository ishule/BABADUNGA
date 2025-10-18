INCLUDE "consts.inc"

SECTION "Gorilla Movement Vars", WRAM0
gorilla_jumping_flag: DS 1 ; 1 = está en el suelo  0 = en el aire

SECTION "Snake Movement Vars",WRAM0
snake_flags:: DS 1 ;; Bit 0, 0=Derecha, 1=Izquierda (Flip y disparo)
                   ;; Bit 1 y 2, 00=INIT, 01=SHOOT, 10=MOVE, 11==TURN
                   ;; Bit 3 y 4, 00=2 disparos, 01=1 disparo, 00=0 disparos
                   ;; Bit 5 = 0 No colisión. Bit 5 = 1 Colisión con muro
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





sys_snake_movement::
    ld a, [snake_flags]
    and MASK_STATE
    cp STATE_INIT
    jr z, .init_state
    cp STATE_SHOOT
    jr z, .shoot_state
    cp STATE_MOVE
    jr z, .move_state
    cp STATE_TURN
    jr z, .turn_state
    ret

.init_state:
    jr .turn_state

.shoot_state:
    ld a,[snake_flags]
    bit 0,a
    ld d,1
    jr nz ,.disparar
    ld d,0
    .disparar:
    ;call shot_bullet_for_snake
    ld a, STATE_MOVE
    ld [snake_flags], a
    ret

.move_state:
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld a, [snake_flags]
    bit 0, a
    jr nz, .left
    
    ; Movimiento a la derecha
    ld bc, SNAKE_SPEED_NEGATIVE
    jr .apply_velocity
    ret
.left:
    ld bc, SNAKE_SPEED
    
.apply_velocity:
    ld d,$04
    call change_entity_group_vel_x
    ; Comentado para que no cambie estado automáticamente
    ; ld a, STATE_TURN
    ; ld [snake_flags], a
    ret

.turn_state:
    ld a, [snake_flags]
    bit 0, a
    jr z, .turn_left
    
.turn_right:
    call snake_unflip
    jr .finish_turn
    
.turn_left:
    call snake_flip
    
.finish_turn:
    ; Establecer el siguiente estado y toggle del bit de dirección
    ld a, [snake_flags]
    xor %00000001        ; Invertir bit de dirección
    and %11111001        ; Limpiar bits de estado (bits 1-2)
    or STATE_SHOOT       ; Establecer nuevo estado
    ld [snake_flags], a
    ret