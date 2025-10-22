INCLUDE "consts.inc"

SECTION "Gorilla Movement Vars", WRAM0
gorilla_on_ground_flag: DS 1 ; 1 = está en el suelo  0 = en el aire

;boss_flags:  Información;; Bit 0, 0=Derecha, 1=Izquierda (Flip)
                   ;; Bit 1,2 00=INIT,, 10=MOVE, 11==TURN, 01=IDLE

;; Constantes de máscara
def MASK_DIRECTION equ %00000001
def MASK_STATE equ %00001110
def MASK_SHOT_COUNT equ %00110000

DEF GORILLA_LEFT_LIMIT  equ 16     ; Límite izquierdo (posición X mínima)
DEF GORILLA_RIGHT_LIMIT equ 128    ; Límite derecho (160 - 32 de ancho)

; Estados del Gorila 
def STATE_INIT_GORILLA equ 0
def STATE_IDLE_GORILLA equ 2
def STATE_MOVE_GORILLA equ 4  ; Este estado cubre el salto y el movimiento en el aire
def STATE_TURN_GORILLA equ 6
SECTION "Gorilla Movement Code", ROM0
;; En check_collision_ground se usa el gorilla_on_ground_flag en tener colisiones hay que eliminar eso
;;NOTAS: SNAKE_FLAGS Y SNAKE_COUNTER SE DEBEN DE INICIALIZAR EN BOSS.ASM PARA REUTILIZARLO PARA CADA BOSS

; -----------------------
; sys_gorilla_movement
; Máquina de estados principal del gorila.
; -----------------------
sys_gorilla_movement::
    ; --- 1. FÍSICA VERTICAL Y ATERRIZAJE ---
    ld a, [snake_flags]
    and MASK_STATE
    cp STATE_INIT_GORILLA
    jp z, .run_fsm ; Si estamos en INIT, saltamos la física

    ld a, [gorilla_on_ground_flag]
    cp 1
    jr z, .check_wall_collisions ; Si está en el suelo, saltar gravedad

.in_air:
    ; Está en el aire, aplicar gravedad
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld bc, GORILLA_GRAVITY
    ld d, GORILLA_SPRITES_SIZE
    call change_entity_group_acc_y

    ; =================================================================
    ; --- INICIO DE LA COMPROBACIÓN DE SUELO (EN LÍNEA) ---
    ; =================================================================
    ;
    ; 1. Obtener la PosY del primer sprite de la FILA INFERIOR
    ;    (El grupo empieza en ID 1, la fila inferior empieza en 1 + 4 = 5)
    ld a, ENEMY_START_ENTITY_ID
    add 4 ; Apuntar al 5º sprite (índice 4), que es el inicio de la fila inferior
    call man_entity_locate_v2 ; HL = $C0xx + offset
    ld h, CMP_SPRITES_H       ; HL = $C1xx + offset
    ld a, [hl]                ; A = PosY del sprite (fila inferior)
    
    ; 2. Comparar con la posición del suelo
    cp GROUND_Y
    jr c, .no_ground_collision ; Si PosY < GROUND_Y, sigue en el aire

    ; =================================================================
    ; --- FIN DE LA COMPROBACIÓN DE SUELO (EN LÍNEA) ---
    ; =================================================================

    ; Si PosY >= GROUND_Y, ha aterrizado.
.landed:
    ; ¡Acaba de aterrizar!
    ld a, 1
    ld [gorilla_on_ground_flag], a ; Marcar como "en el suelo"

    ; Forzar la PosY a GROUND_Y para que no se hunda
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld b, GROUND_Y - 16 ; PosY de la fila SUPERIOR (asumiendo 16px de altura)
    ld c, $00 ; No cambiar X
    call change_entity_group_pos_y_32x32 ; <-- Función de 32x32

    ; Parar todo el movimiento (X e Y)
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld bc, $0000 ; Vel Y = 0
    ld de,$0000
    ld a, GORILLA_SPRITES_SIZE
    call change_entity_group_vel ; <-- CORRECCIÓN: Usar vel, no vel_x
    
    ; Parar también la aceleración
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld d, GORILLA_SPRITES_SIZE
    call change_entity_group_acc_y

    ; Forzar estado a "TURN"
    ld a,[snake_flags]
    and MASK_STATE
    cp STATE_TURN_GORILLA
    jp z,.run_fsm

    ld a, [snake_flags]
    and %11110001
    or STATE_IDLE_GORILLA
    ld [snake_flags], a
    jp .run_fsm ; Saltar a la FSM (que ejecutará TURN)

.no_ground_collision:
    ; Aún está en el aire, comprobar colisiones con paredes
    ; (cae a la siguiente sección)


    ; --- 2. COLISIONES CON PAREDES (sólo en el aire) ---
.check_wall_collisions:
    ld a, [gorilla_on_ground_flag]
    cp 1
    jp z, .run_fsm ; Si está en el suelo, no choca con paredes (está en IDLE o TURN)
    
    ; Comprobar posición X de la entidad principal
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld h, CMP_SPRITES_H
    inc hl
    ld a, [hl] ; OAM_X

    ; Determinar qué borde comprobar
    ld hl, snake_flags
    bit 0, [hl]
    jr nz, .check_left_border

.check_right_border:
    cp GORILLA_RIGHT_LIMIT
    jr c, .run_fsm ; No hay colisión
    jp .hit_wall
.check_left_border:
    cp GORILLA_LEFT_LIMIT
    jr nc, .run_fsm ; No hay colisión

.hit_wall:
    ; Chocó con una pared en el aire. Parar movimiento X.
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld bc, $0000
    ld d, GORILLA_SPRITES_SIZE
    call change_entity_group_vel_x

    ; No cambiamos de estado, dejamos que aterrice.
    ; La lógica de .landed se encargará de ir a TURN.
    ld a, [snake_flags]
    and %11110001
    or STATE_TURN_GORILLA
    ld [snake_flags], a


    ; --- 3. MÁQUINA DE ESTADOS (FSM) ---
.run_fsm:
    ld a, [snake_flags]
    and MASK_STATE
    cp STATE_INIT_GORILLA
    jr z, .init_state
    cp STATE_IDLE_GORILLA
    jr z, .idle_state
    cp STATE_MOVE_GORILLA
    jr z, .move_state
    cp STATE_TURN_GORILLA
    jr z, .turn_state
    ret

.init_state:
    xor a
    ld [snake_counter], a
    ld a, 1
    ld [gorilla_on_ground_flag], a ; Empezar en el suelo

    ; Inicializar: empezar mirando a la derecha (sin flip), ir a IDLE
    ld a, [snake_flags]
    and %11110000      ; Limpiar dirección y estado
    or STATE_IDLE_GORILLA ; Empezar en IDLE (Cambiado de MOVE)
    ld [snake_flags], a
    
    ; Asegurarse de que empieza sin flip (mirando derecha)
    ;call gorilla_unflip
    ret

.idle_state:
    ; No hacer nada si está en el aire (esperar a aterrizar)
    ld a, [gorilla_on_ground_flag]
    cp 0
    ret z
    ; Está en el suelo, correr temporizador
    ld a, [snake_counter]
    add %00000100 ; Aumentar contador (ajusta esta velocidad si espera mucho/poco)
    jr c, .fin_idle
    ld [snake_counter], a
    ret
.fin_idle:
    ; Se acabó el tiempo de espera, ir a MOVE (saltar)
    xor a
    ld [snake_counter], a
    ld a, [snake_flags]
    and %11110001
    or STATE_MOVE_GORILLA
    ld [snake_flags], a
    ret

.move_state:
    ; Este estado es el "INICIO DEL SALTO"
    ; Si ya está en el aire, la física de arriba se encarga.
    ld a, [gorilla_on_ground_flag]
    cp 0
    ret z ; Ya está en el aire, no hacer nada

    ; Está en el suelo y en estado MOVE, ¡ASÍ QUE SALTA!
    ld a, 0
    ld [gorilla_on_ground_flag], a ; Marcar como "en el aire"
    ; Aplicar velocidad Y (salto) y velocidad X (dirección)
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    
    ld bc, GORILLA_JUMP_SPEED ; Velocidad Y (negativa)
    
    ; Comprobar dirección para velocidad X
    ld a, [snake_flags]
    bit 0, a
    jr nz, .jump_left

.jump_right:
    ld de, GORILLA_SPEED
    jr .apply_jump
.jump_left:
    ld de, GORILLA_SPEED_NEGATIVE
    
.apply_jump:
    ld a, GORILLA_SPRITES_SIZE  ; 
    call change_entity_group_vel ; Aplica Vel-Y (bc) y Vel-X (de)
    ret


.turn_state:
    ; No girar si está en el aire (esperar a aterrizar)
    ld a, [gorilla_on_ground_flag]
    cp 0
    ret z 

    ; Está en el suelo, así que gira
    ld a, [snake_flags]
    bit 0, a
    jr nz, .turn_to_right

.turn_to_left:
    ; Estaba mirando derecha (0), ahora mira izquierda (1)
    ;call gorilla_flip
    jr .finish_turn

.turn_to_right:
    ; Estaba mirando izquierda (1), ahora mira derecha (0)
    ;call gorilla_unflip

.finish_turn:
    ; Invertir el bit de dirección
    ld a, [snake_flags]
    xor MASK_DIRECTION
    
    ; Cambiar estado a IDLE
    and %11110001
    or STATE_IDLE_GORILLA ; <-- CORREGIDO: ir a IDLE después de girar
    ld [snake_flags], a
    ret