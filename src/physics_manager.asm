INCLUDE "consts.inc"

; Physics Component structure
;  size:    8
;  sprite H:   $C1
;      byte 0:  POS          Y (Q8.0, Unsigned)
;      byte 1:  POS          X (Q8.0, Unsigned)
;      ...
;  start H:    $C2
;      byte 0:  POS DECIMAL  Y (Q0.8, Unsigned)
;      byte 1:  POS DECIMAL  X (Q0.8, Unsigned)
;      byte 2:  VELOCITY     Y (Q5.3, C2)
;      byte 3:  VELOCITY     X (Q5.3, C2)
;  continue H: $C3
;      byte 0:  FREE
;      byte 1:  FREE
;      byte 2:  ACCELERATION Y (Q5.3, C2)
;      byte 3:  ACCELERATION X (Q5.3, C2)

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
	ld hl, CMP_PHYSICS_1_ADDRESS
	.acceleration_loop:
        ; Apply acceleration
		call apply_acceleration_to_entity
		
        ; Go to next entity
        inc l

        ; Check last entity
		ld bc, next_free_entity
		ld a, [bc]
		cp l
		jr nz, .acceleration_loop


	; # COMPUTE VELOCITY #
	; foreach (entity in entities) {
	;	 apply_velocity(entity)
	; }
	ld hl, CMP_PHYSICS_0_ADDRESS	
	.velocity_loop:
        ; Apply velocity
		call apply_velocity_to_entity
		
        ; Go to next entity
        inc l

        ; Check last entity
		ld bc, next_free_entity
		ld a, [bc]
		cp l
		jr nz, .velocity_loop


    ; # GROUND CHECK #
    ld d, $02 ;MAGIC
    ld e, $00 ;MAGIC
	;call check_ground_collision

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
    ;  b  -> v_Y
    ;  c  -> v_X
    ;  hl -> entity start address
    ;
    ; MODIFIES: hl(h+2, l+3)
    change_entity_vel::
    	ld h, CMP_PHYSICS_0_H
        inc l
        inc l

    	ld [hl], b
    	inc l
    	ld [hl], c

    	ret

    change_entity_vel_y::
        ld h, CMP_PHYSICS_0_H
        inc l
        inc l

        ld [hl], b    

        ret

    change_entity_vel_x::
        ld h, CMP_PHYSICS_0_H
        inc l
        inc l
        inc l

        ld [hl], b    

        ret

    ; INPUT
    ;  b  -> vel Y
    ;  c  -> vel X
    ;  hl -> entity start address
    ;  d  -> group size
    change_entity_group_vel:
        call change_entity_vel
        dec h
        dec h
        inc l

        dec d
        jr nz, change_entity_group_vel

        ret

    ; INPUT:
    ;  b  -> nueva velocidad Y
    ;  hl -> entity start address
    ;  d  -> group size
    ;
    ; Cambia solo VelY, NO toca VelX
    change_entity_group_vel_y::
        call change_entity_vel_y
        dec h
        dec h
        inc l
        inc l

        dec d
        jr nz, change_entity_group_vel_y
        
        ret


    change_entity_group_vel_x::
        call change_entity_vel_x
        dec h
        dec h
        inc l

        dec d
        jr nz, change_entity_group_vel_x
        ret

acceleration_changers:
    ; INPUT
    ;  b  -> a_Y
    ;  c  -> a_X
    ;  hl -> entity start address
    change_entity_acc::
    	ld h, CMP_PHYSICS_1_H
        inc l
        inc l

    	ld [hl], b
    	inc l
    	ld [hl], c

    	ret

    change_entity_acc_y::
        ld h, CMP_PHYSICS_1_H
        inc l
        inc l

        ld [hl], b

        ret

    ; INPUT
    ;  b  -> a_Y
    ;  c  -> a_X
    ;  hl -> entity start address
    ;  d  -> group size
    change_entity_group_acc:
        call change_entity_acc
        dec h
        dec h
        dec h
        inc l

        dec d
        jr nz, change_entity_group_acc

        ret


    ; INPUT:
    ;  b  -> nueva aceleración Y
    ;  hl -> entity start address
    ;  d  -> group size
    ;
    ; Cambia solo A_Y, NO toca A_X
    change_entity_group_acc_y::
        call change_entity_acc_y
        dec h
        dec h
        dec h
        inc l
        inc l

        dec d
        jr nz, change_entity_group_acc
        ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PRIVATE UTILS                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; # VELOCITY UTILS #

;  INPUT
;   hl -> Entity physics_0 start address ($C2--)
;
;  MODIFIES: HL
apply_velocity_to_entity:
    
    ; Go to v_Y
    inc l
    inc l

	call apply_velocity_to_axis ; Y axis
	
    ; Go to axis X
    inc h
    ld de, CMP_PHYSICS_BYTE_V_X
    add hl, de

	call apply_velocity_to_axis ; X axis

    inc h
    ld de, CMP_PHYSICS_BYTE_V_X - 1
    add hl, de

	ret

; INPUT
;  HL -> v_[AXIS]
;
; MODIFIES: a, bc, de, hl (acaba en h-1 y l-3 )
apply_velocity_to_axis:
	push hl

    call align_v_with_pos

    ; ** Actualizar posición **
    ; Carga de posición (16-bits, Q8.8, Unsigned) en HL
    dec l
    dec l
    ld c, [hl]

    dec h
    ld b, [hl]

    ld h, b
    ld l, c

    ; Suma la velocidad
    add hl, de
    ld d, h
    ld e, l

    pop hl

    ; Guardar la parte decimal
    dec l
    dec l
    ld [hl], e

    ; Guardar la parte entera
    dec h
    ld [hl], d

	ret

; INPUT
;  HL -> v_[AXIS]
;
; RETURN
;  DE -> v_[AXIS]_aligned
;
; MODIFIES: a, de
align_v_with_pos:
    ; ** Carga v_X para la suma **
    ld a, [hl]
    ld e, a    ; Byte bajo de DE = v_X
    ld d, $00  ; Byte alto de DE = $00

    ; ** Manejo del signo **
    ; El bit 7 es el signo. Si es 1 necesitamos rellenar D con $FF
    bit 7, e
    jr z, .no_sign_extend

    ld d, $FF

    .no_sign_extend:

    ; ** Alineación: Multiplicar por 32 (Shift Left 5)
    
    ; Shift 1
    sla e
    rl  d

    ; Shift 2
    sla e
    rl  d

    ; Shift 3
    sla e
    rl  d

    ; Shift 4
    sla e
    rl  d

    ; Shift 5
    sla e
    rl  d

    ; Resultado: Ahora en DE está V << 5 (Q8.8 alineado)

    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; # ACCELERATION UTILS #

; INPUT 
; hl -> Entity physics_0 start address ($C3--)
;
; MODIFIES: hl
apply_acceleration_to_entity:
    
    ; Go to a_Y
    inc l
    inc l

    call add_acceleration_to_axis
    call add_acceleration_to_axis

    ret

; INPUT
;  HL -> a_[AXIS]
;
; MODIFIES: L(++), a
add_acceleration_to_axis:
    
    ld a, [hl]   ; Read a_[AXIS]
    
    ; Go to v_[AXIS]
    dec h
    add a, [hl]  ; a <- v_[AXIS] + a_[AXIS]

    ld [hl+], a
    inc h

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
    call man_entity_locate 

    ld b, GROUND_Y
    ld a, d 
    cp $08 
    jr z, .is32
    jr nz, .isnot32

    .is32:
        ; Leer posición Y
        ld a, e
        call man_entity_locate 
        ld a, [hl]  ; PosY sprite 0
        add 16  ; Al ser un sprite de 32x32, tengo que compararlo con el sprite de abajo (+16)
        
        ; Comparar con suelo
        cp GROUND_Y
        jr c, .not_on_ground

        call change_entity_group_pos_y_32x32
        ld a, 1 
        ld [gorilla_jumping_flag], a
        jr .reset_physics 

    .isnot32:
        ; Leer posición Y
        ld a, e
        call man_entity_locate 
        ld a, [hl]  ; PosY sprite 0
        
        ; Comparar con suelo
        cp GROUND_Y
        jr c, .not_on_ground

        call change_entity_group_pos_y

    .reset_physics:
        ; Resetear física Y
        ld a, e
        call man_entity_locate 

        ld b, $00 
        call change_entity_group_vel_y

        ld b, $00
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