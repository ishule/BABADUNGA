include "consts.inc"
SECTION "Snake Movement Vars",WRAM0
snake_flags:: DS 1 ;; Bit 0, 0=Derecha, 1=Izquierda (Flip y disparo)
                   ;; Bit 1,2,3, 00=INIT, 01=SHOOT, 10=MOVE, 11==TURN
                   ;; Bit 4 y 5, 00=2 disparos, 01=1 disparo, 00=0 disparos
snake_counter:: DS 1
;; Constantes de máscara
def MASK_DIRECTION equ %00000001
def MASK_STATE equ %00001110
def MASK_SHOT_COUNT equ %00110000
;; Valores de estado
def STATE_INIT equ 0
def STATE_SHOOT equ 2
def STATE_MOVE equ 4
def STATE_TURN equ 6
def STATE_IDLE equ 8

SECTION "Snake Logic",ROM0

; -----------------------
; sys_snake_movement
; Máquina de estados: INIT → MOVE → (al tocar borde) → TURN → SHOOT → MOVE
; -----------------------
sys_snake_movement::
    ld a, [snake_flags]
    and MASK_STATE
    cp STATE_INIT
    jr z, .init_state
    cp STATE_IDLE
    jr z,.idle_state
    cp STATE_SHOOT
    jp z, .shoot_state
    cp STATE_MOVE
    jp z, .move_state
    cp STATE_TURN
    jp z, .turn_state
    ret
.idle_state:
    ld a,[snake_counter]
    add %00000100
    jr c,.fin_idle
    ld [snake_counter],a
    ret
.fin_idle:
    xor a
    ld [snake_counter],a
    ld a,[snake_flags]
    and %11110001            ; clear state bits
    or STATE_SHOOT           ; Ir a SHOOT después de girar
    ld [snake_flags], a
    ret

.init_state:
    xor a
    ld [snake_counter],a
    ; Inicializar: empezar mirando a la derecha (sin flip), ir a MOVE
    ld a, [snake_flags]
    and %11110000          ; Limpiar dirección y estado
    or STATE_TURN          ; Estado = MOVE, Dirección = RIGHT (0)
    ld [snake_flags], a
    
    ; Asegurarse de que empieza sin flip (mirando derecha)
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
    ; A la derecha, la velocidad X debe ser POSITIVA
    ld bc, SNAKE_SPEED          ; << ¡ESTA ES LA CORRECCIÓN IMPORTANTE!
    ld d, $04
    call change_entity_group_acc_x
    
    ; Comprobar colisión con borde derecho
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld h,CMP_SPRITES_H
    inc hl
    ld a, [hl]                  ; OAM_X
    cp SNAKE_RIGHT_LIMIT
    jr c, .no_collision_right   ; Si A < LIMIT, continúa
    jp .hit_right_border

.no_collision_right:
    ret

.move_left:
    ; A la izquierda, la velocidad X debe ser NEGATIVA
    ld bc, SNAKE_SPEED_NEGATIVE ; << ¡ESTA ES LA CORRECCIÓN IMPORTANTE!
    ld d, $04
    call change_entity_group_acc_x
    
    ; Comprobar colisión con borde izquierdo
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld h,CMP_SPRITES_H
    inc hl
    ld a, [hl]                  ; OAM_X
    cp SNAKE_LEFT_LIMIT         ; Usando la constante
    jr nc, .no_collision_left   ; Si A >= LIMIT, continúa
    jp .hit_left_border

.no_collision_left:
    ret
; ----------------------------
; Colisión detectada: clamp posición, parar, ir a TURN
; ----------------------------
.hit_left_border:
    ; Clamp posición
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    
    ; Detener velocidad
    ld bc, 0
    ld d, $04
    call change_entity_group_vel_x
    call change_entity_group_acc_x
    
    ; cambiar a TURN
    ld a, [snake_flags]
    and %11110001      ; Limpiar estado (Bits 1,2,3)
    or STATE_TURN      ; <-- IR A TURN
    ld [snake_flags], a
    ret

.hit_right_border:
    ; Clamp posición
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    
    ; Detener velocidad
    ld bc, 0
    ld d, $04
    call change_entity_group_vel_x
    call change_entity_group_acc_x
    
    ; Marcar colisión y cambiar a TURN
    ld a, [snake_flags]      ; <-- DESCOMENTADO
    and %11110001            ; <-- MÁSCARA CORREGIDA
    or STATE_TURN            ; <-- IR A TURN
    ld [snake_flags], a      ; <-- DESCOMENTADO
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
    call man_entity_locate_v2  ; HL = $C0xx (Info)
    ld h, CMP_SPRITES_H        ; <-- ¡LA LÍNEA QUE FALTA! (Ahora HL = $C1xx)
    
    ; Leer coordenadas correctas
    ld b, [hl]                 ; C = PosY
    inc hl
    ld c, [hl]                 ; B = PosX
    
    ld a, 1                    ; A = Dirección: derecha
    ld de, snake_bullet_preset
    ;call shot_bullet_for_preset
    jr .post_shoot

.shoot_left:
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2  ; HL = $C0xx (Info)
    ld h, CMP_SPRITES_H        ; <-- ¡LA LÍNEA QUE FALTA! (Ahora HL = $C1xx)

    ; Leer coordenadas correctas
    ld b, [hl]                 ; C = PosY
    inc hl
    ld c, [hl]                 ; B = PosX

    ld a, 0                    ; A = Dirección: izquierda
    ld de, snake_bullet_preset
    ;call shot_bullet_for_preset
    ; (cae a .post_shoot)
.post_shoot:
    ; Incrementar contador de disparos (bits 4 y 5)
    ld a, [snake_flags]
    and MASK_SHOT_COUNT     ; Aislar bits 4 y 5
    add a, %00010000        ; <-- CORREGIDO: Sumar 16 (incrementar Bit 4)
    ld b, a
    
    ; Actualizar flags
    ld a, [snake_flags]
    and %11001111           ; Limpiar bits 4 y 5
    or b                    ; Aplicar nuevo contador
    ld [snake_flags], a
    
    ; Comprobar si hemos disparado 2 veces (bits 4-5 = 10 = %00100000)
    ld a, b
    cp %00100000            ; <-- CORREGIDO: Comprobar Bit 5 (valor 32)
    jr c, .stay_shoot       ; Si < 2 disparos, saltar
    
    ; Ya disparamos 2 veces → ir a MOVE
    ld a, [snake_flags]
    and %11001111           ; Limpiar contador de disparos (bits 4 y 5)
    and %11110001           ; Limpiar estado (bits 1,2,3)
    or STATE_MOVE
    ld [snake_flags], a
    ret

.stay_shoot:
    ; Disparó una vez, volver a IDLE para la pausa
    ld a,[snake_flags]
    and %11110001
    or STATE_IDLE
    ld [snake_flags],a
    ret

; -------------------------
; TURN STATE
; -------------------------
.turn_state:
    ld a, [snake_flags]
    bit 0, a
    jr nz, .turn_to_right

.turn_to_left:
    ; Estaba mirando derecha, ahora mira izquierda
    call snake_flip
    jr .finish_turn

.turn_to_right:
    ; Estaba mirando izquierda, ahora mira derecha
    call snake_unflip

.finish_turn:
    ; Toggle direction bit and set next state to SHOOT (and zero shot count)
    ld a, [snake_flags]
    xor %00000001            ; flip direction bit
    and %11001111            ; clear shot count
    and %11110001            ; clear state bits
    or STATE_IDLE           ; Ir a SHOOT después de girar
    ld [snake_flags], a
    ret