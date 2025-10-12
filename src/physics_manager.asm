INCLUDE "consts.inc"

def FRAME_RATE equ $60

SECTION "Physics Variables", WRAM0
physics_frame_index: ds 1 ; de 0 a FRAME_RATE


; Physics Component structure
;  size:    4
;  start address: $C100
;  byte 0:  VELOCITY     Y
;  byte 1:  VELOCITY     X
;  byte 2:  ACCELERATION Y
;  byte 3:  ACCELERATION X
SECTION "Physics Manager", ROM0

; Goes through each entity and aplies velocity
;  
;  MODIFIES: c, hl
compute_physics::
	
	; # COMPUTE ACCELERATION #
	; foreach (entity in entities) {
	;	 apply_acceleration(entity)
	; }
	ld hl, CMP_SPRITES_ADDRESS
	.acceleration_loop:
		call apply_acceleration_to_entity
		inc hl

		ld bc, next_free_entity
		ld a, [bc]
		cp l
		jr nz, .acceleration_loop


	; # COMPUTE VELOCITY #
	; foreach (entity in entities) {
	;	 apply_velocity(entity)
	; }
	ld hl, CMP_SPRITES_ADDRESS	
	.velocity_loop:
		call apply_velocity_to_entity
		inc hl

		ld bc, next_free_entity
		ld a, [bc]
		cp l
		jr nz, .velocity_loop

    ld d, $02
    ld e, $00 

	call check_ground_collision

	; # UPDATE PHYSICS INDEX #
	ld a, [physics_frame_index]
	inc a
	cp FRAME_RATE + 1
	jr nz, go_on
	reset_index:
		xor a
		ld [physics_frame_index], a
	go_on:
	ld [physics_frame_index], a

	ret

; INPUT
;  b  -> pos Y
;  c  -> pos X
;  hl -> entity start address
change_entity_pos::
	ld [hl], b
	inc l
	ld [hl], c

	ret

; INPUT
;  b  -> vel Y
;  c  -> vel X
;  hl -> entity start address
change_entity_vel::
	inc h
	ld [hl], b

	inc l
	ld [hl], c

	ret

; INPUT
;  b  -> acc Y
;  c  -> acc X
;  hl -> entity start address
change_entity_acc::
	inc h
	inc hl
	inc hl
	ld [hl], b
	inc hl
	ld [hl], c

	ret

; INPUT
;  b  -> pos Y
;  c  -> pos X
;  hl -> entity start address
;  d  -> group size
change_entity_group_pos:
	call change_entity_pos
	inc hl
	inc hl
	inc hl

	ld a, 8
	add c
	ld c, a

	dec d
	jr nz, change_entity_group_pos

	ret


; INPUT:
;  b  -> nueva pos Y
;  hl -> entity start address
;  d  -> group size
change_entity_group_pos_y::
.loop:
    ld [hl], b      ; Cambiar solo Y
    inc hl          ; Saltar a X
    inc hl          ; Saltar X (NO modificar)
    inc hl          ; Saltar padding
    inc hl          ; Saltar padding
    
    dec d
    jr nz, .loop
    ret



; INPUT
;  b  -> base pos Y
;  c  -> base pos X
;  hl -> entity start address (primer sprite del grupo)
;
; Usa change_entity_group_pos para colocar dos filas de 4 sprites (32x32 total)
;
; MODIFICA: A, B, C, D, HL
change_entity_group_pos_32x32::
    push bc                ; guardar X e Y originales

    ; === Fila superior ===
    ld d, 4
    call change_entity_group_pos

    pop bc                 ; restaurar X e Y originales
    push bc                ; volver a guardar para la siguiente fila

    ; === Fila inferior ===
    ld a, b
    add a, 16              ; siguiente fila (altura 16)
    ld b, a
    ld d, 4
    call change_entity_group_pos

    pop bc
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
    ; === Fila superior (Y - 16) ===
    push bc
    ld a, b
    sub 32          ; Y de la fila superior
    ld b, a

    ; Primera mitad (sprites 0–1)
    ld d, 2
    call change_entity_group_pos_y

    ; Segunda mitad (sprites 2–3)
    ld d, 2
    call change_entity_group_pos_y

    pop bc
    ; === Fila inferior (Y base) ===
    ld a, b
    sub 16
    ld b, a

    ; Primera mitad inferior (sprites 4–5)
    ld d, 2
    call change_entity_group_pos_y

    ; Segunda mitad inferior (sprites 6–7)
    ld d, 2
    call change_entity_group_pos_y

    ret



; INPUT
;  b  -> vel Y
;  c  -> vel X
;  hl -> entity start address
;  d  -> group size
change_entity_group_vel:
	call change_entity_vel
	dec h
	inc hl
	inc hl
	inc hl

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
    inc h           ; Cambiar de $C0xx a $C1xx (página de física)
    
.loop:
    ld [hl], b      ; Escribir VelY
    inc hl          ; Saltar a VelX
    inc hl          ; NO modificar VelX, saltar padding
    inc hl
    inc hl          ; Siguiente sprite
    
    dec d
    jr nz, .loop
    
    dec h           ; Volver a página de posiciones
    ret


change_entity_group_vel_x::
    inc h           ; Cambiar de $C0xx a $C1xx (página de física)
    
.loop:
    inc hl
    ld [hl], c     ; Escribir VelX
    inc hl          
    inc hl
    inc hl          ; Siguiente sprite
    
    dec d
    jr nz, .loop
    
    dec h           ; Volver a página de posiciones
    ret

; INPUT
;  b  -> acc Y
;  c  -> acc X
;  hl -> entity start address
;  d  -> group size
change_entity_group_acc:
	call change_entity_acc
	dec h
	inc hl

	dec d
	jr nz, change_entity_group_acc

	ret


; INPUT:
;  b  -> nueva aceleración Y
;  hl -> entity start address
;  d  -> group size
;
; Cambia solo AccY, NO toca AccX
change_entity_group_acc_y::
    inc h           ; Cambiar a página de física
    inc hl          ; Saltar VelY
    inc hl          ; Saltar VelX, ahora en AccY
    
.loop:
    ld [hl], b      ; Escribir AccY
    inc hl          ; Saltar AccX
    inc hl          ; Siguiente sprite - VelY
    inc hl          ; VelX
    inc hl          ; AccY del siguiente
    
    dec d
    jr nz, .loop
    
    dec hl          ; Retroceder a posición inicial
    dec hl
    dec h           ; Volver a página de posiciones
    ret




;; ## UTILS ##

; # VELOCITY UTILS #
; Applies velocity to individual entity
; 
;  INPNUT
;   hl -> Entity start address (Y POS)
;
;  MODIFIES:  
apply_velocity_to_entity:
	call add_velocity_to_axis ; Y axis
	inc hl
	call add_velocity_to_axis ; X axis
	inc hl
	inc hl

	ret

; INPUT
; HL -> POS
;
; En función del bit 7 de la velocidad, es positiva(1) o negativa(0)
;
; MODIFIES: a, b
add_velocity_to_axis:
	push hl
	ld a, [hl]  ;; read pos
	inc h

	ld b, [hl] ;; read vel
	
	bit 7, b
	jr z, sub_pos

	add_pos:
		res 7, b
		call normalize_velocity
		add b
		jr save_new_pos
	
	sub_pos:
        res 7, b
		sub b
		call normalize_velocity

	save_new_pos:
	dec h
	ld [hl], a  ;; save new pos
	pop hl
	ret

; INPUT
;   b -> velocity (desnormalizada)
; OUTPUT
;   b -> velocity (normalizada)
; USES
;   c, d
normalize_velocity:
    push af                ; guardamos A (posición actual)
    
    ;; TODO: Normalizar la velocidad para poder poner vellocidades más pequeñas

    pop af                 ; restauramos el valor original de A (posición)
    ret


; # ACCELERATION UTILS #
; INPUT 
; hl -> entity start address (Y POS)
apply_acceleration_to_entity:
    inc h
    call add_acceleration_to_axis  ; ← Misma función para ambos
    inc hl
    call add_acceleration_to_axis  ; ← Misma función para ambos
    inc hl 
    inc hl 
    dec h
    ret


add_acceleration_to_axis:
    push hl
    ld a, [hl+]     ; Leer velocidad
    inc l           ; Saltar padding
    ld b, [hl]      ; Leer aceleración
    
    bit 7, b
    jr z, .sub_vel
    
.add_vel:
    ; Aceleración POSITIVA
    res 7, b
    ld c, a
    
    bit 7, c
    jr nz, .vel_positive
    
    ; Vel- + Acc+: Frenar (restar de negativo)
    sub a, b
    jr nc, .still_negative
    
    ; Cruzó a positivo
    cpl
    inc a
    set 7, a
    jr .save_new_vel
    
.still_negative:
    jr .save_new_vel
    
.vel_positive:
    ; Vel+ + Acc+: Acelerar más
    res 7, a
    add a, b
    set 7, a
    jr .save_new_vel
    
.sub_vel:
    ; Aceleración NEGATIVA
    ld c, a
    
    bit 7, c
    jr z, .vel_negative
    
    ; Vel+ + Acc-: Frenar (restar de positivo)
    res 7, a
    sub a, b
    jr c, .now_negative
    
    set 7, a
    jr .save_new_vel
    
.now_negative:
    cpl
    inc a
    jr .save_new_vel
    
.vel_negative:
    ; Vel- + Acc-: Acelerar más negativo
    add a, b
    
.save_new_vel:
    dec hl
    dec hl
    ld [hl], a
    pop hl
    ret

;; INPUT:
;;  D: Número de sprites de la entidad
;;  E: Posición de inicio de la entidad
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