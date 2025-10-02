INCLUDE "consts.inc"

SECTION "Entity Draw Code", ROM0

;; Copia los datos del sprite de la entidad a la memoria OAM
;; INPUT:
;;	HL: apunta al sprite de la entidad (component_sprite)
;; 	DE: apunta al inicio de OAM ($FE00)
;; 	A: índice de la siguiente entidad libre
;; 	B: cantidad de bytes a copiar (igual al valor de A en este caso)
man_entity_draw::
	ld hl, component_sprite
	ld de, OAM_START
	ld a, [next_free_entity]
	ld b, a 
	call memcpy_256
	ret