INCLUDE "consts.inc"
INCLUDE "collisions.inc"

SECTION "Collision Manager Array", WRAM0

collision_array: DS COLLISION_ARRAY_SIZE


SECTION "Collision Manager Code", ROM0


man_collision_init::
	ld hl, collision_array 
	ld b, COLLISION_ARRAY_SIZE
	xor a 
	call memset_256

	ret 


;;	RETURN:
;;		HL -> Dirección del sprite de la nueva entidad en collision_array		
man_collision_alloc:
	ld hl, collision_array 
	ld b, MAX_COLLISIONS 
	ld de, SIZEOF_COLLISION 

	.loop:
		ld a, [hl]
		inc l 
		inc l 	; Me desplazo hasta height 
		cp 0 
		ret z 	; si es 0, se que he encontrado el hueco 
		add hl, de 
		dec b 
		jr .loop 

	ld hl, $FFFF 	; Pongo hl a $FFFF si no he encontrado ningún hueco en collisions_array

	ret 


;; Crea una colisión en las coordenadas dadas
;; INPUT: 
;;	- B: PosY
;;	- C: PosX 
;; 	- D: Height 
;; 	- E: Width
;; 
;; MODIFICA: AF, BC, DE, HL 
;;
;; RETURN: HL, dirección de la colisión creada
man_collision_create_collision:: 
	push bc 
	push de 
	call man_collision_alloc 	; HL = dirección del hueco libre 
	pop de 
	pop bc 

	push de ; Guardamos el valor de HEIGHT y WIDTH

	;; Copiamos en la dirección dada todos los parámetros
	push hl 
	ld de, C_POSY 
	add hl, de 
	ld [hl], b 
	pop hl

	push hl 
	ld de, C_POSX
	add hl, de 
	ld [hl], c
	pop hl

	; Recuperamos HEIGHT y WIDTH y lo pasamos a bc
	pop de 
	ld b, d 
	ld c, e

	push hl 
	ld de, C_HEIGHT
	add hl, de 
	ld [hl], b 
	pop hl

	push hl 
	ld de, C_WIDTH
	add hl, de 
	ld [hl], c
	pop hl

	ret 


man_collision_create_all_collisions::

	;; Crear suelo
	ld b, 136 
	ld c, 8 
	ld d, 8 
	ld e, 144
	call man_collision_create_collision

	;; Crear pared izquierda
	ld b, 16 
	ld c, 8 
	ld d, 120 
	ld e, 8
	call man_collision_create_collision


	;; Crear pared derecha
	ld b, 16 
	ld c, 144
	ld d, 120
	ld e, 8
	call man_collision_create_collision

	ret
