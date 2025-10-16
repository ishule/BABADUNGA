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

	; Set Info Array to 0
	ld hl, component_info
	ld b, CMP_TOTALBYTES
	xor a 
	call memset_256

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
	ld hl, CMP_START_ADDRESS
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

	ld b, CMP_SIZE
	call memcpy_256

	ret



; INPUT:
;   A = entity ID
;
; OUTPUT:
;   HL = C000 + (A * 4)

man_entity_locate_v2:
    ld hl, $C000      ; base address

    add a             ; A = A * 2
    add a             ; A = A * 4

    ld e, a           ; E = offset (low byte)
    ld d, $00         ; D = 0

    add hl, de        ; HL = C000 + offset
    ret


; INPUT
;   A = tipo buscado
;   DE = puntero a callback
; CALLBACK INPUTS
;   A = ID
;   DE = dirección de la entidad
man_entity_foreach_type::
    ld c, a             ; C = tipo buscado
    ld a, [num_entities_alive]
    or a
    ret z
    ld b, a             ; B = contador
    xor a               ; A = ID inicial
.loop:
    push bc             ; [1] guarda contador
    push de             ; [2] guarda callback
    push af             ; [3] guarda ID
    
    ; Calcular offset = ID * 4
    add a
    add a               ; A = A * 4
    ld h, $C0
    ld l, a

    ;;Verificar si está activa
    ld a, [hl]          ; Leer E_ACTIVE
    or a
    jr z, .skip         ; Si no está activa, skip

    inc l               ; HL = $C001 + (ID * 4)
    ld a, [hl]
    cp c
    jr nz, .skip
    
    ; --- Es del tipo buscado ---
    pop af              ; [3] recupera ID
    push af             ; [3] guarda ID de nuevo
    call man_entity_locate_v2   ; HL = dirección entidad
    
    ; Preparar parámetros para callback
    ; A ya tiene el ID
    ld d, h
    ld e, l             ; DE = dirección entidad
    
    pop af              ; [3] recupera ID (A correcto para callback)
    pop hl              ; [2] recupera callback en HL
    push hl             ; [2] guarda callback de nuevo
    
    call man_entity_foreach_call
    
    pop de              ; [2] recupera callback
    pop bc              ; [1] recupera contador
    jr .continue
    
.skip:
    pop af              ; [3] limpiar ID
    pop de              ; [2] restaurar callback
    pop bc              ; [1] restaurar contador
    
.continue:
    inc a               ; Siguiente ID
    dec b
    jr nz, .loop
    ret

man_entity_foreach_call:
    jp hl

