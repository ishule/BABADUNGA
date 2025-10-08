INCLUDE "consts.inc"

; Physics Component structure
;  size:    4
;  start address: $C100
;  byte 0:  VELOCITY Y
;  byte 1:  VELOCITY X


SECTION "Physics Manager", ROM0

; Goes through each entity and aplies velocity
;  
;  MODIFIES: c, hl
compute_physics::
	; foreach (entity in entities) {
	;	 apply_velocity(entity)
	; }

	ld hl, CMP_SPRITES_ADDRESS	
	.loop:
		call apply_velocity_to_entity
		inc hl

		ld bc, next_free_entity
		ld a, [bc]
		cp l
		jr nz, .loop

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
change_entity_vel::
	inc h
	ld [hl], b

	inc l
	ld [hl], c

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


;; ## UTILS ##
; Applies velocity to individual entity
; 
;  INPNUT
;   hl -> Entity start address (POS X)
;
;  MODIFIES:  
apply_velocity_to_entity:
	call add_velocity_to_axis
	inc hl
	call add_velocity_to_axis
	inc hl
	inc hl

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
		add b
		jr save_new_pos
	
	sub_pos:
		sub b

	save_new_pos:
	dec h
	ld [hl], a  ;; save new pos

	ret