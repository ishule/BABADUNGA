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
def MASK_COLLISION equ %00100000
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
; Máquina de estados: INIT → MOVE → (al tocar borde) → TURN → SHOOT → MOVE
; -----------------------
sys_snake_movement::
    ld a, [snake_flags]
    and MASK_STATE
    cp STATE_INIT
    jr z, .init_state
    cp STATE_SHOOT
    jp z, .shoot_state
    cp STATE_MOVE
    jp z, .move_state
    cp STATE_TURN
    jp z, .turn_state
    ret

.init_state:
    ; Inicializar: empezar mirando a la derecha, ir a MOVE
    ld a, [snake_flags]
    and %11111000          ; Limpiar dirección y estado
    or STATE_TURN          ; Estado = MOVE, Dirección = RIGHT (0)
    ld [snake_flags], a
    ret

; -------------------------
; MOVE STATE: Mover serpiente y detectar colisiones con bordes
; -------------------------
.move_state:
    ; Localizar entidad
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2

    ; Determinar dirección y aplicar velocidad
    ld a, [snake_flags]
    bit 0, a
    jr nz, .move_left

.move_right:
    ld bc, SNAKE_SPEED_NEGATIVE
    ld d, $04
    call change_entity_group_vel_x
    
    ; Comprobar colisión con borde derecho
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc hl
    ld a, [hl]              ; OAM_X
    cp SNAKE_RIGHT_LIMIT
    jr nc, .hit_right_border
    ret

.move_left:
    ld bc, SNAKE_SPEED
    ld d, $04
    call change_entity_group_vel_x
    
    ; Comprobar colisión con borde izquierdo
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc hl
    ld a, [hl]              ; OAM_X
    cp SNAKE_LEFT_LIMIT
    jr c, .hit_left_border
    ret

; ----------------------------
; Colisión detectada: clamp posición, parar, ir a TURN
; ----------------------------
.hit_left_border:
    ; Clamp posición
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc hl
    ld [hl], SNAKE_LEFT_LIMIT
    
    ; Detener velocidad
    ld bc, 0
    ld d, $04
    call change_entity_group_vel_x
    
    ; Marcar colisión y cambiar a TURN
    ld a, [snake_flags]
    or MASK_COLLISION       ; Bit 5 = 1
    and %11111001           ; Limpiar estado
    or STATE_TURN
    ld [snake_flags], a
    ret

.hit_right_border:
    ; Clamp posición
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc hl
    ld [hl], SNAKE_RIGHT_LIMIT
    
    ; Detener velocidad
    ld bc, 0
    ld d, $04
    call change_entity_group_vel_x
    
    ; Marcar colisión y cambiar a TURN
    ld a, [snake_flags]
    or MASK_COLLISION       ; Bit 5 = 1
    and %11111001           ; Limpiar estado
    or STATE_TURN
    ld [snake_flags], a
    ret

; -------------------------
; SHOOT STATE: Dispara hasta 2 veces
; -------------------------
.shoot_state:
    ; Preparar dirección de disparo según bit 0
    ld a, [snake_flags]
    bit 0, a
    jr nz, .shoot_left

.shoot_right:
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc hl
    ld b, [hl]              ; X
    inc hl
    ld c, [hl]              ; Y
    ld d, 0                 ; Dirección: derecha
    ld de, snake_bullet_preset
    ;call shot_bullet_for_preset
    jr .post_shoot

.shoot_left:
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc hl
    ld b, [hl]
    inc hl
    ld c, [hl]
    ld d, 1                 ; Dirección: izquierda
    ld de, snake_bullet_preset
    call shot_bullet_for_preset

.post_shoot:
    ; Incrementar contador de disparos (bits 3-4)
    ld a, [snake_flags]
    and MASK_SHOT_COUNT     ; Aislar contador actual
    add a, %00001000        ; Incrementar
    ld b, a
    
    ; Actualizar flags
    ld a, [snake_flags]
    and %11100111           ; Limpiar contador
    or b                    ; Aplicar nuevo contador
    ld [snake_flags], a
    
    ; Comprobar si hemos disparado 2 veces (bits 3-4 = 10 = %00010000)
    ld a, b
    cp %00010000
    jr c, .stay_shoot       ; Si < 2 disparos, quedarse en SHOOT
    
    ; Ya disparamos 2 veces → ir a MOVE
    ld a, [snake_flags]
    and %11100111           ; Limpiar contador de disparos
    and %11111001           ; Limpiar estado
    or STATE_MOVE
    ld [snake_flags], a
    ret

.stay_shoot:
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
