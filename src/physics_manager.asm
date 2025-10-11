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

	call check_player_ground_collision

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
		sub b
		call normalize_velocity

	save_new_pos:
	dec h
	ld [hl], a  ;; save new pos

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
	call add_acceleration_to_axis_y
	inc hl
	call add_acceleration_to_axis_x
	inc hl 
	inc hl 
	dec h

	ret


; INPUT
;  hl -> entity velocity address
add_acceleration_to_axis_x:
    ld a, [hl+] ; read vel
    inc l
    ld b, [hl]  ; read acc
    bit 7, b
    jr z, sub_vel
    add_vel:
        res 7, b
        add b
        jr save_new_vel
    sub_vel:
        sub b
    save_new_vel:
    dec hl
    dec hl
    ld [hl], a
    ret


; INPUT
;  hl -> dirección de velocidad de la entidad (puede ser VelX o VelY)
;
; DESCRIPCIÓN:
;  Aplica la aceleración a la velocidad del eje especificado.
;
; MODIFICA: a, b, c
add_acceleration_to_axis_y::
    ld a, [hl+]     ; Leer velocidad actual, HL++
    inc l           ; Saltar byte de padding
    ld b, [hl]      ; Leer aceleración
    
    ; Comprobar signo de aceleración (bit 7)
    bit 7, b
    jr z, .sub_vel
    
.add_vel:
    ; Aceleración POSITIVA (bit 7 = 1)
    res 7, b        ; Extraer magnitud
    ld c, a         ; Guardar velocidad original
    
    ; Comprobar signo de velocidad
    bit 7, c
    jr nz, .vel_positive
    
    ; Velocidad NEGATIVA + Aceleración POSITIVA
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
    ; Velocidad POSITIVA + Aceleración POSITIVA
    res 7, a
    add a, b
    set 7, a
    jr .save_new_vel
    
.sub_vel:
    ; Aceleración NEGATIVA (bit 7 = 0)
    ld c, a         ; Guardar velocidad
    
    ; Comprobar signo de velocidad
    bit 7, c
    jr z, .vel_negative
    
    ; Velocidad POSITIVA - Aceleración NEGATIVA
    res 7, a
    sub a, b
    jr c, .now_negative
    
    ; Sigue positivo
    set 7, a
    jr .save_new_vel
    
.now_negative:
    ; Cruzó a negativo
    cpl
    inc a
    jr .save_new_vel
    
.vel_negative:
    ; Velocidad NEGATIVA - Aceleración NEGATIVA
    add a, b
    
.save_new_vel:
    ; HL actualmente apunta a AccY/AccX
    ; Necesitamos volver a VelY/VelX
    dec hl          ; Volver de AccY/AccX a padding
    dec hl          ; Volver de padding a VelY/VelX
    ld [hl], a      ; Guardar nueva velocidad
    ret

    
; DESCRIPCIÓN:
;  Verifica si el jugador (entidad 0) ha tocado o pasado el suelo.
;  Si es así, ajusta su posición al suelo y resetea su física vertical.
;
; FUNCIONAMIENTO:
;  1. Lee la posición Y del jugador (ambos sprites)
;  2. Compara con GROUND_Y
;  3. Si Y >= GROUND_Y:
;     - Ajusta posición Y a GROUND_Y exactamente
;     - Pone velocidad Y a 0
;     - Pone aceleración Y a 0
;  4. Mantiene intactos velocidad X y aceleración X
;
; MODIFICA: a, b, c, d, hl
check_player_ground_collision::
    ; Leer posición Y del sprite 0 del jugador
    ld hl, CMP_SPRITES_ADDRESS
    ld a, [hl]  ; PosY sprite 0
    
    ; Comparar con suelo
    cp GROUND_Y
    ret c  ; Si PosY < GROUND_Y, aún está en el aire, salir
    
    ; === SPRITE 0: Tocó el suelo ===
    
    ; Ajustar posición Y al suelo exactamente
    ld a, GROUND_Y
    ld [hl], a  ; PosY = GROUND_Y
    
    ; Resetear física Y del sprite 0
    ld hl, CMP_PHYSICS_ADDRESS  ; $C100 (página de física)
    ld [hl], $00    ; VelY sprite 0 = 0
    inc hl
    inc hl          ; Saltar VelX
    ld [hl], $00    ; AccY sprite 0 = 0
    
    ; === SPRITE 1 ===
    ld hl, CMP_SPRITES_ADDRESS + 4  ; PosY sprite 1
    ld a, GROUND_Y
    ld [hl], a
    
    ; Resetear física Y del sprite 1
    ld hl, CMP_PHYSICS_ADDRESS + 4  ; Física sprite 1
    ld [hl], $00    ; VelY sprite 1 = 0
    inc hl
    inc hl          ; Saltar VelX
    ld [hl], $00    ; AccY sprite 1 = 0
    
    ret


stop_physics_player::
    ld a, $00
    call man_entity_locate 

    ;ld b, $00 ; Put VY to 0
    ld c, $00 ; Put VX to 0
    ld d, $02
    call change_entity_group_vel

    ;ld b, $00 ; Put AY to 0
    ld c, $00 ; Put AX to 0
    ld d, $02
    call change_entity_group_acc
	ret
