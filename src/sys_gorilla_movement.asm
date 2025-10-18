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

; -----------------------
; sys_snake_movement
; Usa:
;   snake_flags (bits: 0 dir, 1-2 state, 3-4 shot count)
; Constantes esperadas: MASK_STATE, MASK_DIRECTION, MASK_SHOT_COUNT,
;                      STATE_INIT, STATE_SHOOT, STATE_MOVE, STATE_TURN
; -----------------------

sys_snake_movement::
    ld a, [snake_flags]
    and MASK_STATE
    cp STATE_INIT
    jp z, .init_state
    cp STATE_SHOOT
    jp z, .shoot_state
    cp STATE_MOVE
    jp z, .move_state
    cp STATE_TURN
    jp z, .turn_state
    ret

.init_state:
    ; Al iniciar, vamos a movernos
    jr .move_state

; -------------------------
; SHOOT STATE: dispara hasta 2 veces (bits 3-4)
; -------------------------
.shoot_state:
    ; Limpia contador de disparos al entrar en estado SHOOT (asegura 0)
    ld a, [snake_flags]
    and %11100111           ; limpia bits 3-4
    ld [snake_flags], a

    ; Preparar dirección de disparo: bit0 = 1 -> left, 0 -> right
    ld a, [snake_flags]
    bit 0, a
    jr nz, .shoot_left
    ; ---> disparo a la derecha
.shoot_right:
    ; Obtener la posición de la entidad (para pasar coords a la rutina de disparo)
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc h
    ld b, [hl]      ; X
    inc l
    ld c, [hl]      ; Y
    ; d = 0 => hacia la derecha (convención tuya)
    ld d, 0
    ld de, snake_bullet_preset
    call shot_bullet_for_preset
    jr .post_shoot

.shoot_left:
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc h
    ld b, [hl]
    inc l
    ld c, [hl]
    ; d = 1 => hacia la izquierda
    ld d, 1 ;; MAGIC
    ld de, snake_bullet_preset
    call shot_bullet_for_preset

.post_shoot:
    ; Incrementar contador de disparos (bits 3-4) sin tocar resto de bits
    ld a, [snake_flags]
    and MASK_SHOT_COUNT    ; b = current shot bits (8/16/24/0)
    add a, %00001000       ; b = b + 8 (incrementar)
    and MASK_SHOT_COUNT    ; mantener solo bits de contador
    ld b,a

    ; limpiar bits en flags y setear los nuevos
    ld a, [snake_flags]
    and %11100111          ; limpiar bits 3-4
    or b
    ld [snake_flags], a

    ; Si b >= %00010000 (es decir hemos alcanzado 2 disparos o más) -> cambiar a MOVE
    ld a, b
    and %00010000
    jr z, .stay_shoot      ; si no alcanzado, seguimos en shoot

    ; Hemos alcanzado 2 disparos -> pasar a MOVE y limpiar contador de disparos
    ld a, [snake_flags]
    and %11100111          ; limpiar contador de disparos
    and %11111001          ; limpiamos bits de estado (1-2)
    or STATE_MOVE
    ld [snake_flags], a
    ret

.stay_shoot:
    ; Quedarse en shoot_state (se llamará de nuevo en el siguiente frame)
    ret

; -------------------------
; MOVE STATE
; -------------------------
.move_state:
    ; Localizar entidad
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2

    ; Comprobar dirección y aplicar velocidad
    ld a, [snake_flags]
    bit 0, a
    jr nz, .move_left

    ; Mover a la derecha
    ld bc, SNAKE_SPEED_NEGATIVE
    jr .apply_velocity

.move_left:
    ld bc, SNAKE_SPEED
    jr .apply_velocity

.apply_velocity:
    ld d, $04
    call change_entity_group_vel_x
    ; Tras aplicar velocidad, comprobar colisión con paredes
    ; Re-localizamos entidad y leemos OAM_X (offset +1)
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc hl
    ld a, [hl]          ; OAM_X
    ; Si venimos por derecha, comprobamos límite derecho (136)
    ld e, a             ; guardar OAM_X en e temporario
    ; Determinar si estamos en modo left o right (re-uso flag)
    ld a, [snake_flags]
    bit 0, a
    jr nz, .check_left_collision
    ; right-moving: check right limit
    ld a, e
    cp 136
    jr c, .no_turn
    ; handle right hit
    jr .handle_hit_right

.check_left_collision:
    ld a, e
    cp 8
    jr nc, .no_turn
    ; handle left hit
    jr .handle_hit_left

.no_turn:
    ret

; ----------------------------
; On hit: clamp position, zero velocity, set TURN state
; ----------------------------
.handle_hit_left:
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc hl
    ld [hl], 8           ; set OAM_X = 8 (clamp)
    ; detener velocidad
    ld bc, 0
    ld d, $04
    call change_entity_group_vel_x
    ; marcar colisión (bit5)
    ld a, [snake_flags]
    or %00100000
    ld [snake_flags], a
    ; transición MOVE -> TURN
    ld a, [snake_flags]
    and %11111001
    or STATE_TURN
    ld [snake_flags], a
    ; girar sprite
    call snake_flip
    ret

.handle_hit_right:
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc hl
    ld [hl], 136         ; set OAM_X = 136 (clamp)
    ld bc, 0
    ld d, $04
    call change_entity_group_vel_x
    ld a, [snake_flags]
    or %00100000
    ld [snake_flags], a
    ld a, [snake_flags]
    and %11111001
    or STATE_TURN
    ld [snake_flags], a
    call snake_unflip
    ret

; -------------------------
; TURN STATE
; -------------------------
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
    ; Toggle direction bit and set next state to SHOOT (and zero shot count)
    ld a, [snake_flags]
    xor %00000001            ; flip direction bit
    and %11100111            ; clear shot count
    and %11111001            ; clear state bits
    or STATE_MOVE
    ld [snake_flags], a
    ret
