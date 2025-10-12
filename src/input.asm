INCLUDE "consts.inc"

SECTION "Player Vars", WRAM0
player_anim_counter:: ds 1

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
    ld b, a     ; Guardar estado del joypad en B


    ; Comprobar DERECHA
    bit JOYPAD_RIGHT, a 
    jr z, .check_left			; Si es 0, sabemos que no es derecha

    ld a, $00
    call man_entity_locate 

    ld b, $00
    ld c, PLAYER_SPEED          ; VX = velocidad positiva
    ld d, $02
    call change_entity_group_vel

    call flip_right				; Orientar a la derecha
    call choose_stand_or_walk	; Alternar animación
    jr .check_jump
    
.check_left:
	; Comprobar IZQUIERDA
    bit JOYPAD_LEFT, a 
    jr z, .no_horizontal_input
    
    ld a, $00
    call man_entity_locate

    ld b, $00
    ld c, PLAYER_SPEED_NEGATIVE     
    ld d, $02
    call change_entity_group_vel

    call flip_left				; Orientar a la izquierda
    call choose_stand_or_walk	; Alternar animación 
    jr .check_jump

.no_horizontal_input:
    ; Ho hay input horizontal, así que detenemos velocidad X 
    ld a, $00 
    call man_entity_locate
    ld bc, $0000 
    ld d, $02 
    call change_entity_group_vel

.check_jump:
    ld a, [joypad_input]    ; Recargamos estado del joypad

    ; Comprobar SALTO
    bit JOYPAD_B, a 
    jr z, .end

    ; Verificar si está en el suelo antes de saltar 
    ld a, [CMP_SPRITES_ADDRESS]
    cp GROUND_Y
    jr nz, .end     ; Si no está en el suelo no puede saltar 
    


    ; Aplicamos el impulso de salto
    ld a, $00
    call man_entity_locate 
    ld b, PLAYER_JUMP_SPEED
    ld c, $00   
    ld d, $02
    call change_entity_group_vel

    ; Aplicamos gravedad
    ld a, $00
    call man_entity_locate
    ld b, PLAYER_GRAVITY
    ld c, $00   
    ld d, $02
    call change_entity_group_acc

    ret

.end:
    ret
