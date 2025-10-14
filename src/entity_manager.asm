INCLUDE "consts.inc"

SECTION "Entity Manager Data"          , WRAM0[$C000]
component_info::      DS CMP_TOTALBYTES
num_entities_alive::  DS 1	;; Contador de entidades activas
next_free_entity::    DS 1		;; Índice de la siguiente entidad

SECTION "Entity Sprites"               , WRAM0[$C100]
component_sprite::    DS CMP_TOTALBYTES	;; Array de memoria para almacenar los sprites de entidades

SECTION "Entity Physics (pos and vel)" , WRAM0[$C200]
component_physics_0:: DS CMP_TOTALBYTES

SECTION "Entity Physics (acceleration)", WRAM0[$C300]
component_physics_1:: DS CMP_TOTALBYTES


SECTION "Entity Manager Code", ROM0

;; Inicializa todos los sprites de entidades y contadores
man_entity_init::
	; Set Component Sprite Array to 0
	ld hl, component_sprite
	ld b, CMP_TOTALBYTES
	xor a 
	call memset_256

	; Limpiar física 0
	ld hl, component_physics_0
	ld b, CMP_TOTALBYTES
	xor a 
	call memset_256

	; Limpiar física 1
	ld hl, component_physics_1
	ld b, CMP_TOTALBYTES
	xor a 
	call memset_256

	; Inicializa contadores de entidades
	ld [next_free_entity], a 
	ld [num_entities_alive], a 
	ret 

;;	RETURN:
;;		HL -> Dirección del sprite de la nueva entidad en component_sprite		
man_entity_alloc:
	;; +1 Entity
	ld a, [num_entities_alive]
	inc a 
	ld [num_entities_alive], a

	;; Calcula la dirección del siguiente sprite libre
	ld a, [next_free_entity]	;; Obtener índice actual
	ld h, CMP_SPRITES_H			;; Parte alta de la dirección base
	ld l, a 							;; Parte baja = índice
	add SPRITE_SIZE				;; Avanza la dirección por el tamaño de un sprite
	ld [next_free_entity], a 	;; Guarda el índice actualizado
	ret
 

; INPUT
;  a -> entity ID
; 
; RETURN
;  hl -> entity_start_address
man_entity_locate:
	ld hl, CMP_SPRITES_ADDRESS
	ld c, $03 ; MAGIC
	iter:
		add a
		dec c
		jr nz, iter
	
	ld l, a

	ret

; INPUT
; a -> entity ID
man_entity_delete::
	call man_entity_locate
	ld d, h
	ld e, l

	ld a, [num_entities_alive]
	dec a
	call man_entity_locate

	ld b, ENTITY_SIZE
	call memcpy_256

	ret