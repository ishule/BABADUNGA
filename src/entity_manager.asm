INCLUDE "consts.inc"
													;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
													;; =========== Entities array structure ===========
													;;
SECTION "Entity Manager Data"        , WRAM0[$C000] ;; [ACTIVE]     [TYPE]       [FLAGS]   [num_sprites]
component_info::      DS CMP_TOTALBYTES             ;;
num_entities_alive::  DS 1                          ;;
next_free_entity::    DS 1                          ;;
                                                    ;;
SECTION "Entity Sprites"             , WRAM0[$C100] ;; [p_y_high]   [p_x_high]   [tile]    [ATTR]
component_sprite::    DS CMP_TOTALBYTES             ;;
                                                    ;;
SECTION "Entity Physics Position"    , WRAM0[$C200] ;; [p_y_low]    [p_x_low]    [health]  [damage]
component_physics_p:: DS CMP_TOTALBYTES             ;;
                                                    ;;
SECTION "Entity Physics Velocity"    , WRAM0[$C300] ;; [v_y_high]   [v_x_high]   [v_y_low] [v_x_low]
component_physics_v:: DS CMP_TOTALBYTES             ;;
                                                    ;;
SECTION "Entity Physics Acceleration", WRAM0[$C400] ;; [a_y_high]   [a_x_high]   [a_y_low] [a_x_low]
component_physics_a:: DS CMP_TOTALBYTES             ;;
                                                    ;;
SECTION "Entity Physics Collisions"  , WRAM0[$C500] ;; [y_collision_offset] [x_collision_offset] [height] [width]
collision_values::    DS CMP_TOTALBYTES             ;;

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
	ld hl, component_physics_p
	ld b, CMP_TOTALBYTES
	xor a 
	call memset_256

	; Limpiar física 1
	ld hl, component_physics_v
	ld b, CMP_TOTALBYTES
	xor a 
	call memset_256

	; Limpiar física 2
	ld hl, component_physics_a
	ld b, CMP_TOTALBYTES
	xor a 
	call memset_256

	; Limpiar colisiones
	ld hl, collision_values
	ld b, CMP_TOTALBYTES
	xor a 
	call memset_256

	; Inicializa contadores de entidades a 0
	ld [next_free_entity], a 
	ld [num_entities_alive], a 
	;Inicializa flags bosses
	ld a,%00100000
	ld [snake_flags],a
	ret 

;;	RETURN:
;;		HL -> Dirección del sprite de la nueva entidad en component_sprite		
;;  MODIFIES: A
man_entity_alloc:
	;; +1 Entity
	ld a, [num_entities_alive]
	inc a 
	ld [num_entities_alive], a

	;; Calcula la dirección del siguiente sprite libre
	ld a, [next_free_entity]	;; Obtener índice actual
	ld h, CMP_START_H			;; Parte alta de la dirección base
	ld l, a 							;; Parte baja = índice
	add CMP_SIZE				;; Avanza la dirección por el tamaño de un sprite
	ld [next_free_entity], a 	;; Guarda el índice actualizado
	ret
 
; INPUT
; C  -> CMP_SIZE
; HL -> Source
; DE -> Destination
go_to_next_entity_start_DE_HL:
	; Prepare HL
	inc h
	ld a, l
	sub a, c
	ld l, a

	; Prepare DE
	inc d
	ld a, e
	sub c
	ld e, a

	ret

; INPUT
; C  -> CMP_SIZE
; HL -> Source
go_to_next_entity_start_HL:
	; Prepare HL
	inc h
	ld a, l
	sub a, c
	ld l, a

	ret

; INPUT
; a -> entity ID
man_entity_delete::
	ld c, CMP_SIZE

	; Search entity to delete
	call man_entity_locate_v2
	ld d, h
	ld e, l
	
	; If last -> memset_256 a $00
	ld a, l
	add CMP_SIZE
	ld hl, next_free_entity
	ld b, [hl]
	cp b
	jr z, .is_last_entity
	
	.not_last_entity:
	; Search last entity
	ld a, [num_entities_alive]
	dec a
	ld [num_entities_alive], a
	call man_entity_locate_v2

	; Copy CMP_INFO
	ld b, c ; CMP_SIZE
	call memcut_256

	; Copy CMP_SPRITE
	call go_to_next_entity_start_DE_HL
	ld b, c; CMP_SIZE
	call memcut_256

	; Copy CMP_PHYSICS_P
	call go_to_next_entity_start_DE_HL
	ld b, c; CMP_SIZE
	call memcut_256

	; Copy CMP_PHYSICS_V
	call go_to_next_entity_start_DE_HL
	ld b, c; CMP_SIZE
	call memcut_256

	; Copy CMP_PHYSICS_A
	call go_to_next_entity_start_DE_HL
	ld b, c; CMP_SIZE
	call memcut_256

	; Decrement next_free_entity
	ld a, [next_free_entity]
	sub c; CMP_SIZE
	ld [next_free_entity], a
	jr .exit

	.is_last_entity:
	; Reduce entities alive
	ld a, [num_entities_alive]
	dec a
	ld [num_entities_alive], a

	; CMP_INFO
	ld h, d
	ld l, e
	ld b, c; CMP_SIZE
	call memreset_256

	;CMP_SPRITE
	call go_to_next_entity_start_HL
	ld b, c; CMP_SIZE
	call memreset_256

	;CMP_PHYSICS_P
	call go_to_next_entity_start_HL
	ld b, c; CMP_SIZE
	call memreset_256

	;CMP_PHYSICS_V
	call go_to_next_entity_start_HL
	ld b, c; CMP_SIZE
	call memreset_256

	;CMP_PHYSICS_A
	call go_to_next_entity_start_HL
	ld b, c; CMP_SIZE
	call memreset_256

	.exit:
	ld a, [next_free_entity]
	sub CMP_SIZE
	ld [next_free_entity], a

	ret



; INPUT:
;   A = entity ID
;
; OUTPUT:
;   HL = C000 + (A * 4)

man_entity_locate_v2:
    ld h, CMP_INFO_H      ; base address

    add a             ; A = A * 2
    add a             ; A = A * 4

    ld l, a           ; E = offset (low byte)
    ret


;; Busca la primera entidad del tipo dado
;; INPUT:
;;    A = tipo buscado
;; OUTPUT:
;;    HL = dirección de la entidad (o 0 si no existe)
;; FLAGS:
;;    CARRY = 1 si no encontró nada
;; MODIFICA: AF, BC, DE, HL
man_entity_locate_first_type::
    ld c, a                   ; guardar tipo buscado en C

    ld a, [num_entities_alive]
    or a
    jr z, .not_found          ; si no hay entidades, salir

    ld b, a                   ; contador = número de entidades
    xor a                     ; ID = 0

	.loop:
    push af                   ; guardar ID actual
    call man_entity_locate_v2 ; HL = dirección entidad(ID)
    inc hl                    ; HL = dirección del campo TYPE
    ld a, [hl]                ; A = tipo de la entidad
    cp c                      ; comparar con tipo buscado
    jr z, .found              ; si coincide, salir

    pop af                    ; recuperar ID
    inc a                     ; siguiente ID
    dec b
    jr nz, .loop              ; mientras queden entidades

	.not_found:
    ld hl, $0000
    scf                       ; Carry = 1 → no encontrado
    ret

	.found:
    pop af                    ; limpiar pila
    call man_entity_locate_v2 ; HL = dirección exacta entidad
    or a                      ; clear carry (carry=0 → éxito)
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




; INPUT
;  HL -> preset address
;  c  -> Entity size
spawn_group_entity:
	push hl
	call man_entity_alloc
	ld d, h
	ld e, l

	; Sprite
	inc d
	pop hl
	ld b, CMP_SIZE
	call memcpy_256

	; Collisions
	ld d, CMP_COLLISIONS_H
	ld a, e
	sub CMP_SIZE
	ld e, a
	ld b, CMP_SIZE
	call memcpy_256

	dec c
	jr nz, spawn_group_entity
	
	ret

; INPUT
;  HL -> collisions preset address
;  C  -> Entity size
change_boss_collisions::
	push hl
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	ld d, h
	ld e, l
	pop hl
	ld d, CMP_COLLISIONS_H
	
	.loop:
	ld b, CMP_SIZE
	call memcpy_256

	dec c
	jr nz, .loop

	ret