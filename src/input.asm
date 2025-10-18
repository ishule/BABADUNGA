INCLUDE "consts.inc"

SECTION "Player Vars", WRAM0
player_anim_counter:: ds 1
player_on_ground_flag:: ds 1   ; 1 = en el suelo, 0 = en el aire

SECTION "Input Code", ROM0

;;=================================================
;; player_update_movement
;; Actualiza el movimiento del jugador
;;
;; Cada frame hace lo siguiente:
;;		1. Lectura de input del joypad (en este caso detecta si es 1 por como está configurado joypad.asm)
;;		2. Movimiento horizontal (izquierda/derecha)
;;		3. Salto (solo si está en el suelo)
;;		4. Aplicación de gravedad
;;		5. Límite de velocidad de caída
;;		6. Detección de suelo
;;		7. Actualización de posición de sprites
;;		
;; MODIFICA: A, BC, DE, HL
process_input::
    call joypad_read
    ld a, [joypad_input]
    ld b, a

    ; ==== SALTO PRIMERO ====
    bit JOYPAD_B, a
    jr z, .check_horizontal

    ; Verificar si está en el suelo mediante la flag
    ld a, [player_on_ground_flag]
    or a
    jr z, .check_horizontal   ; Si está en el aire, no puede saltar

.do_jump:
    
    ld a, $00
    call man_entity_locate_v2
    ld bc, PLAYER_JUMP_SPEED
    ld d, $02
    call change_entity_group_vel_y

    ld a, $00
    call man_entity_locate_v2
    ld bc, PLAYER_GRAVITY
    ld d, $02
    call change_entity_group_acc_y

    call player_set_walk_sprite
    jr .end

; ==== MOVIMIENTO LUEGO ====
.check_horizontal:
    ld a, b
    bit JOYPAD_RIGHT, a
    jr z, .check_left

    ld a, $00
    call man_entity_locate_v2

    ld bc, PLAYER_SPEED
    ld d, $02
    call change_entity_group_vel_x
    call flip_right
    call choose_stand_or_walk
    jr .end

.check_left:
    bit JOYPAD_LEFT, a
    jr z, .no_horizontal_input
    ld a, $00
    call man_entity_locate_v2

    ld bc, PLAYER_SPEED_NEGATIVE
    ld d, $02
    call change_entity_group_vel_x
    call flip_left
    call choose_stand_or_walk
    jr .end

.no_horizontal_input:
    ld a, $00
    call man_entity_locate_v2
    ld bc, $0000
    ld d, $02
    call change_entity_group_vel_x

.end:
    ret
