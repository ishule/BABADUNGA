INCLUDE "consts.inc"

SECTION "Player Vars", WRAM0
player_anim_counter:: ds 1

SECTION "Input Code", ROM0

;;===========================================================
;; flip_right
;; Orienta el jugador hacia la derecha
;; Acciones: 
;;		- Quita el flip si lo hubiese
;;		- Actualiza player_orientation = 0
;;
;; MODIFICA: A, DE
flip_right::
	; Flipear sprite 1 (jugador) a la derecha == Sin flip
    ld de, component_sprite
    inc de ; Saltar Y
    inc de ; Saltar X
    inc de ; Saltar tiles y apuntar a atributos
    ld a, SPRITE_ATTR_NO_FLIP
    ld [de], a

    ; Flipear sprite 2 (cerbatana) a la derecha == Sin flip
    inc de 
    inc de
    inc de 
    inc de 
    ld a, SPRITE_ATTR_NO_FLIP
    ld [de], a

    ; Cargo la dirección del sprite de la cerbatana
    ld hl, $C004

    ld a, [$C001]
    add $08
    ld c, a     ; Guardo en c la dirección x modificada de la cerbatana (cuerpo + 8)

    ld a, [CMP_SPRITES_ADDRESS] ; $C000
    ld b, a     ; En b se queda la misma dirección x 
    call change_entity_pos

    ; Actualizar orientación
    ld a, 00
    ld [player_orientation], a 	; Orientación a la derecha
    
    ret


;;===========================================================
;; flip_left
;; Orienta el jugador hacia la izquierda
;; Acciones: 
;;		- Activa el flip horizontal de ambos sprites
;;		- Actualiza player_orientation = 1
;;
;; MODIFICA: A, DE
flip_left::
	; Flipear sprite 1 (jugador)
    ld de, component_sprite
    inc de 
    inc de 
    inc de 
    ld a, SPRITE_ATTR_FLIP_X
    ld [de], a

    ; Flipear sprite 2 (cerbatana)
    inc de 
    inc de
    inc de 
    inc de 
    ld a, SPRITE_ATTR_FLIP_X
    ld [de], a

    ; Cargo la dirección del sprite de la cerbatana
    ld hl, $C004

    ld a, [$C001]
    sub $08
    ld c, a     ; Guardo en c la dirección x modificada de la cerbatana (cuerpo - 8)

    ld a, [CMP_SPRITES_ADDRESS] ; $C000
    ld b, a     ; En b se queda la misma dirección x 
    call change_entity_pos

    ; Actualizar orientación
    ld a, 01
    ld [player_orientation], a 	; Orientación a la izquierda
    
    ret


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
    
    ; ===== MOVIMIENTO HORIZONTAL =====
    ld b, 0  ; VX por defecto

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
    ret
    
.check_left:
	; Comprobar IZQUIERDA
    bit JOYPAD_LEFT, a 
    jr z, .end
    

    ld a, $00
    call man_entity_locate 

    ld b, $00
    ld c, PLAYER_SPEED_NEGATIVE     
    ld d, $02
    call change_entity_group_vel


    call flip_left				; Orientar a la izquierda
    call choose_stand_or_walk	; Alternar animación 
    ret
.end:
    ret


;;=============================================
;; Alterna entre sprite parado y caminando cada X frames
;;
;; MODIFICA: A
choose_stand_or_walk::
    ld a, [player_anim_counter]
    inc a
    ld [player_anim_counter], a
    cp 8                ; Cambiar animación cada 8 frames aprox
    jr c, .no_change    ; Si no ha llegado a 8, salir sin cambiar

    ; Reiniciar contador
    xor a
    ld [player_anim_counter], a

    ; Alternar animación
    ld a, [player_stand_or_walk]
    cp 00 
    jr z, player_set_stand_sprite  ; Si está parado, cambiar a caminar
    jr nz, player_set_walk_sprite  ; Si está caminando, cambiar a parado

.no_change:
    ret



;;=============================================
;; player_set_walk_sprite
;; Cambia el tile del sprite del jugador a caminar
;; 
;; MODIFICA: A, HL
player_set_walk_sprite::
    ld hl, component_sprite + SPRITE_OFFSET_TILE
    ld [hl], $0A  ; Tile de Player_walk
    ld a, 00 
    ld [player_stand_or_walk], a
    ret

;;=============================================
;; player_set_stand_sprite
;; Cambia el tile del sprite del jugador a parado
;;
;; MODIFICA: A, HL
player_set_stand_sprite::
    ld hl, component_sprite + SPRITE_OFFSET_TILE
    ld [hl], $06  ; Tile de Player_stand 
    ld a, 01
    ld [player_stand_or_walk], a
    ret