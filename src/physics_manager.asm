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
	call add_acceleration_to_axis
	inc hl
	call add_acceleration_to_axis
	inc hl 
	inc hl 
	dec h

	ret

; INPUT
;  hl -> entity velocity address
add_acceleration_to_axis:
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
