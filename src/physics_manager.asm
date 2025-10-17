INCLUDE "consts.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Physics Component structure
;;
;;  Component Size: 16
;;  Format: Q8.8 (velocity and acceleration signed with C2)
;;
;;  Minimum step = 0.004px
;;  Scale factor = 256
;;
;; CMP_sprite:      $C1
;;   [p_y_real] [p_x_real] [-------] [-------]    ######################
;;                                                #======= Range =======
;; CMP_physics_pos: $C2                           #
;;   [p_y_low]  [p_x_low]  [       ] [       ]    # (0, 255.996)
;;                                                #
;; CMP_physics_vel: $C3                           #
;;   [v_y_high] [v_x_high]  [v_y_low] [v_x_low]    # (-127.996, +127.996)
;;                                                #
;; CMP_physics_acc: $C4                           #
;;   [a_y_high] [a_x_high] [a_y_low] [a_x_low]    # (-127.996, +127.996)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION "Physics Manager", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PUBLIC                                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ## Main function ##
;
; Goes through each entity and aplies velocity
;  
;  MODIFIES: all
compute_physics::
	
	; # COMPUTE ACCELERATION #
	; foreach (entity in entities) {
	;	 apply_acceleration(entity)
	; }
	ld hl, CMP_PHYSICS_A_ADDRESS
	.acceleration_loop:
        ; Apply acceleration
		call apply_acceleration_to_entity ; hl -> recibe $C4[entity_start] y devuelve $C4[next_entity_start]

        ; Check last entity
		ld bc, next_free_entity
		ld a, [bc]
		cp l
		jr nz, .acceleration_loop


	; # COMPUTE VELOCITY #
	; foreach (entity in entities) {
	;	 apply_velocity(entity)
	; }
	ld hl, CMP_PHYSICS_V_ADDRESS	
	.velocity_loop:
        ; Apply velocity
		call apply_velocity_to_entity ; hl -> recibe $C3[entity_start] y devuelve $C3[next_entity_start]

        ; Check last entity
		ld bc, next_free_entity
		ld a, [bc]
		cp l
		jr nz, .velocity_loop


    ; # GROUND CHECK #
    ld d, $02 ;MAGIC
    ld e, $00 ;MAGIC
	call check_ground_collision

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ## Changers ##

position_changers:
    ; INPUT
    ;  b  -> p_Y
    ;  c  -> p_X
    ;  hl -> entity start address
    ;
    ; MODIFIES: nothing
    change_entity_pos::
        ld h, CMP_SPRITES_H
        ; Y pos
    	ld [hl], b
        ; Y pos (decimal)
        inc h
        ld [hl], $00
        dec h

        ; X pos
    	inc l
    	ld [hl], c
        ; X pos (decimal)
        inc h
        ld [hl], $00

        dec h
        dec l

    	ret

    ; INPUT
    ;  b  -> p_Y
    ;  hl -> entity start address
    ;
    ; MODIFIES: nothing
    change_entity_pos_y::
        ld h, CMP_SPRITES_H
        ; Y pos
        ld [hl], b
        ; Y pos (decimal)
        inc h
        ld [hl], $00
        dec h

        ret

    ; INPUT
    ;  c  -> p_X
    ;  hl -> entity start address
    ;
    ; MODIFIES: nothing
    change_entity_pos_x::
        ld h, CMP_SPRITES_H
        ; X pos
        inc l
        ld [hl], c
        ; X pos (decimal)
        inc h
        ld [hl], $00

        dec h
        dec l

        ret

    ; INPUT
    ;  b  -> pos Y
    ;  c  -> pos X
    ;  hl -> first entity start address
    ;  d  -> group size
    ;
    ; MODIFIES: a, c, d, hl
    change_entity_group_pos:
        call change_entity_pos
        inc hl
        inc hl
        inc hl
        inc hl

        ; Apply X offset to next entity
        ld a, SPRITE_WIDTH
        add c
        ld c, a

        dec d
        jr nz, change_entity_group_pos

        ret

    ; INPUT:
    ;  b  -> nueva pos Y
    ;  hl -> first entity start address
    ;  d  -> group size
    ;
    ; MODIFIES: d, hl
    change_entity_group_pos_y::
        call change_entity_pos_y
        inc hl
        inc hl
        inc hl
        inc hl

        dec d
        jr nz, change_entity_group_pos_y
        
        ret

    ; INPUT
    ;  b  -> base pos Y
    ;  c  -> base pos X
    ;  hl -> first entity start address
    ;
    ; Usa change_entity_group_pos para colocar dos filas de 4 sprites (32x32 total)
    ;
    ; MODIFICA: A, B, C, D, HL
    change_entity_group_pos_32x32::
        push bc                ; guardar X e Y originales

        ; === Fila superior ===
        ld d, 4                ; MAGIC (ancho de el sprite 32x32)
        call change_entity_group_pos
        pop bc                 ; restaurar X e Y originales
        
        ; === Fila inferior ===
        ld a, b
        add a, SPRITE_HEIGHT              
        ld b, a

        ld d, 4
        call change_entity_group_pos

        ret


    ; INPUT:
    ;  b  -> nueva pos Y base (suelo)
    ;  hl -> entity start address (primer sprite del grupo)
    ;
    ; Cambia solo las Y de un grupo 32x32 (4 columnas x 2 filas),
    ; procesando 2 sprites por llamada a change_entity_group_pos_y
    ;
    ; MODIFICA: A, B, D, HL
    change_entity_group_pos_y_32x32::
        push bc                ; guardar X e Y originales

        ; === Fila superior ===
        ld d, 4                ; MAGIC (ancho de el sprite 32x32)
        call change_entity_group_pos_y
        pop bc                 ; restaurar X e Y originales
        
        ; === Fila inferior ===
        ld a, b
        add a, SPRITE_HEIGHT              
        ld b, a

        ld d, 4
        call change_entity_group_pos_y
        ret

velocity_changers:
    ; INPUT
    ;  bc -> v_y_high, v_y_low 
    ;  de -> v_x_high, v_x_low
    ;  hl -> entity start address
    ;
    ; MODIFIES: hl(h=C3, l+3)
    change_entity_vel::
    	ld h, CMP_PHYSICS_V_H
    	
        ld [hl], b
    	inc l
    	
        ld [hl], c
        inc l

        xor a
        ld [hl+], a
        ld [hl], a

    	ret

    ; INPUT
    ;  bc -> v_y_high, v_y_low
    ;  hl -> entity start address
    ;
    ; MODIFIES: hl(h=C3, l+3)
    change_entity_vel_y::
        ld h, CMP_PHYSICS_V_H

        ld [hl], b
        inc l 
        inc l
        ld [hl], c
        inc l

        ret

    ; INPUT
    ;  bc -> v_x_high, v_x_low
    ;  hl -> entity start address
    ;
    ; MODIFIES: hl(h=C3, l+3)
    change_entity_vel_x::
        ld h, CMP_PHYSICS_V_H
        inc l
        ld [hl], b
        inc l
        inc l
        ld [hl], c 

        ret

    ; INPUT
    ;  bc -> v_y_high, v_y_low
    ;  de -> v_x_high, v_x_low
    ;  hl -> entity start address
    ;  a  -> group size
    change_entity_group_vel:
        call change_entity_vel
        inc l

        dec a
        jr nz, change_entity_group_vel

        ret

    ; INPUT:
    ;  bc -> v_y_high, v_y_low
    ;  hl -> entity start address
    ;  d  -> group size
    change_entity_group_vel_y::
        call change_entity_vel_y
        inc l

        dec d
        jr nz, change_entity_group_vel_y
        
        ret

    ; INPUT:
    ;  bc -> v_x_high, v_x_low
    ;  hl -> entity start address
    ;  d  -> group size
    change_entity_group_vel_x::
        call change_entity_vel_x
        inc l

        dec d
        jr nz, change_entity_group_vel_x
        ret

acceleration_changers:
    ; INPUT
    ;  bc -> a_y_high, a_y_low 
    ;  de -> a_x_high, a_x_low
    ;  hl -> entity start address
    ;
    ; MODIFIES: hl(h=C3, l+3)
    change_entity_acc::
        ld h, CMP_PHYSICS_A_H
        
        ld [hl], b
        inc l
        
        ld [hl], c
        inc l

        xor a
        ld [hl+], a
        ld [hl], a

        ret

    ; INPUT
    ;  bc -> v_a_high, v_a_low
    ;  hl -> entity start address
    ;
    ; MODIFIES: hl(h=C3, l+3)
    change_entity_acc_y::
        ld h, CMP_PHYSICS_A_H

        ld [hl], b
        inc l 
        inc l
        ld [hl], c
        inc l

        ret

    ; INPUT
    ;  bc -> a_x_high, a_x_low
    ;  hl -> entity start address
    ;
    ; MODIFIES: hl(h=C3, l+3)
    change_entity_acc_x::
        ld h, CMP_PHYSICS_A_H
        inc l
        ld [hl], b
        inc l
        inc l
        ld [hl], c 

        ret

    ; INPUT
    ;  bc -> a_y_high, a_y_low
    ;  de -> a_x_high, a_x_low
    ;  hl -> entity start address
    ;  a  -> group size
    change_entity_group_acc:
        call change_entity_acc
        inc l

        dec a
        jr nz, change_entity_group_acc

        ret

    ; INPUT:
    ;  bc -> a_y_high, a_y_low
    ;  hl -> entity start address
    ;  d  -> group size
    change_entity_group_acc_y::
        call change_entity_acc_y
        inc l

        dec d
        jr nz, change_entity_group_acc_y
        
        ret

    ; INPUT:
    ;  bc -> a_x_high, a_x_low
    ;  hl -> entity start address
    ;  d  -> group size
    change_entity_group_acc_x::
        call change_entity_acc_x
        inc l

        dec d
        jr nz, change_entity_group_acc_x
        ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PRIVATE UTILS                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; # VELOCITY UTILS #

;  INPUT
;   hl -> Entity physics_v start address ($C3[entity_start])
;
;  MODIFIES: HL($C3[next_entity_start])
apply_velocity_to_entity:
    
	call apply_velocity_to_axis ; Y axis (hl -> recibe v_Y y devuelve h-1)
	
    ; Go to axis X
    inc h
    inc l
	call apply_velocity_to_axis ; X axis (hl -> recibe v_X y devuelve h-1)

    inc h
    inc l
    inc l
    inc l

	ret

; INPUT
;  HL -> v_[AXIS]
;
; MODIFIES: a, bc, de, hl (acaba en h-1)
apply_velocity_to_axis:
	
    ; v_high -> B
    ld b, [hl]

    ; v_low -> C
    inc l
    inc l
    ld c, [hl]

    ; p_low -> E
    dec l
    dec l
    dec h
    ld e, [hl]

    ; p_high -> D
    dec h
    ld d, [hl]

    ; save entity
    ld a, l

    ; new_pos -> B.C
    ld h, b
    ld l, c
    add hl, de
    ld b, h
    ld c, l

    ; store new_pos
    ld h, CMP_SPRITES_H
    ld l, a
    ld [hl], b
    inc h
    ld [hl], c

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; # ACCELERATION UTILS #

; INPUT 
; hl -> Entity physics_a start address ($C4[entity_start])
;
; MODIFIES: hl:($C4[next_entity_start])
apply_acceleration_to_entity:
    
    call apply_acceleration_to_axis

    ; Go to a_x
    inc h
    dec l
    call apply_acceleration_to_axis

    ; Go to next
    inc h
    inc l

    ret

; INPUT
;  HL -> a_[AXIS]_high
;
; MODIFIES: HL(v_[axis]_low)
apply_acceleration_to_axis:
    
    ; a_high -> B
    ld b, [hl]
    
    ; a_low  -> C
    inc l
    inc l
    ld c, [hl]

    ; v_low  -> E
    dec h
    ld e, [hl]

    ; v_high -> D
    dec l
    dec l
    ld d, [hl]

    ; save entity
    ld a, l

    ; new_vel -> B.C
    ld h, b
    ld l, c
    add hl, de
    ld b, h
    ld c, l

    ; store new_vel
    ld h, CMP_PHYSICS_V_H
    ld l, a
    ld [hl], b
    inc l
    inc l
    ld [hl], c

    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; # GROUND CHECK UTILS

;; INPUT
;;  D -> Número de sprites de la entidad
;;  E -> Posición de inicio de la entidad
;;
check_ground_collision::

    ; Ajustar posición Y al suelo exactamente
    ld a, e
    call man_entity_locate_v2

    ld b, GROUND_Y
    ld a, d 
    cp $08 
    jr z, .is32
    jr nz, .isnot32

    .is32:
        ; Leer posición Y
        ld a, e
        call man_entity_locate_v2 
        inc h
        ld a, [hl]  ; PosY sprite 0
        add 16  ; Al ser un sprite de 32x32, tengo que compararlo con el sprite de abajo (+16)
        
        ; Comparar con suelo
        cp GROUND_Y
        jr c, .not_on_ground

        ld b, GROUND_Y
        ld c, $00
        call change_entity_group_pos_y_32x32
        ld a, 1 
        ld [gorilla_jumping_flag], a
        jr .reset_physics 

    .isnot32:
        ; Leer posición Y
        ld a, e
        call man_entity_locate_v2 
        inc h
        ld a, [hl]  ; PosY sprite 0
        
        ; Comparar con suelo
        cp GROUND_Y
        jr c, .not_on_ground

        ld b, GROUND_Y
        ld c, $00
        ld d, $02
        call change_entity_group_pos_y

    .reset_physics:
        ; Resetear física Y
        ld a, e
        call man_entity_locate_v2 

        ld bc, $0000
        call change_entity_group_vel_y

        ld bc, $0000
        call change_entity_group_acc_y

        ld a, 1 
        ld [player_on_ground_flag], a
    
    ret

.not_on_ground:
    xor a 
    ld [player_on_ground_flag], a 
    ret



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                                                                                                 ;;;;
;;;;                                   TODO ESTO FUERA DE PSHYSICS                                   ;;;;
;;;;                                                                                                 ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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
    ld hl, $C104 ; MAGIC

    ld a, [$C101] ; MAGIC
    add $08 ; MAGIC
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
    ld hl, $C104 ; MAGIC

    ld a, [$C101] ; MAGIC
    sub $08 ; MAGIC
    ld c, a     ; Guardo en c la dirección x modificada de la cerbatana (cuerpo - 8)

    ld a, [CMP_SPRITES_ADDRESS] ; $C000
    ld b, a     ; En b se queda la misma dirección x 
    call change_entity_pos

    ; Actualizar orientación
    ld a, 01 ; MAGIC
    ld [player_orientation], a 	; Orientación a la izquierda
    
    ret



;;=============================================
;; Alterna entre sprite parado y caminando cada X frames
;;
;; MODIFICA: A
choose_stand_or_walk::
    ld a, [player_anim_counter]
    inc a
    ld [player_anim_counter], a
    cp 8                ; Cambiar animación cada 8 frames aprox ; MAGIC
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
    ld [hl], $0A  ; Tile de Player_walk ; MAGIC
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
    ld [hl], $06  ; Tile de Player_stand  ; MAGIC
    ld a, 01 ; MAGIC
    ld [player_stand_or_walk], a
    ret