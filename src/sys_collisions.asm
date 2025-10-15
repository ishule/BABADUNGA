INCLUDE "consts.inc"
INCLUDE "collisions.inc"


SECTION "Collision System Values", WRAM0
;; Almacenan temporalmente los intervalos a comparar
I1: DS 2 	; Intervalo 1: [Pos, Size]
I2: DS 2 	; Intervalo 2: [Pos, Size]


SECTION "Collision System Code", ROM0 

;; Verifica si se solapan dos intervalos 1D
;; INPUT:
;;	- HL: puntero a (PosY, PosX, Height, Width)
;;
;; MODIFICA: A, BC, HL
;;
;; RETURN: 
;; 	- Registro F: C (carry) = no colisión, NC = colisión
;;
sys_collision_check_overlap::
	;; Caso 1: I2 está a la derecha de I1 
	;; Condición: (PosY + Height - 1) - PosX < 0
	;; Si es menor que 0 (se activa carry) no hay colisión
	;; Si es mayor, si que la hay

	ld a, [hl+] 	; A = PosY 
	ld c, a  		; C = PosY (lo guardamos para el Caso 2)
	inc hl			; HL: apunta a Height
	add [hl] 		; A = PosY + Height 
	dec a 			; A = PosY + Height - 1 
	dec hl			; HL: apunta a PosX
	sub [hl]		; A = (PosY + Height - 1) - PosX

	;;; Ahora comprobamos si se solapan o no
	;; (PosY + Height - 1) < 0
	;; Si el flag carry se activa no hay colisión
	ret c


	;; Ahora verificamos para el Caso 2
	;; Caso 2: I1 está a la derecha de I2 
	;; Condición; (PosX + Width - 1) - PosY < 0

	ld a, [hl+]		; A = PosX 
	inc hl			; A = Width 
	add [hl]		; A = PosX + Width 
	dec a 			; A = PosX + Width - 1 
	sub c 			; A = (PosX + Width - 1) - PosY

	ret 			; Carry = no colisión, NoCarry = colisión


;; Verifica si 2 entidades colisionan
;; INPUT:
;;	- HL: puntero a entidad 1
;; 	- DE: puntero a entidad 2
;;
;; MODIFICA: AF, BC, DE, HL
;;
;; RETURN:
;; 	- Registro F: C (carry) = no colisión, NC = colisión
sys_collision_check_AABB::
	;; Verificamos si ambas entidades están activas
	push de 
	ld a, [hl]	; E1.ACTIVE
	cp 0 
	jr z, .no_collision 

	ld h, d 
	ld l, e
	ld a, [hl] 	; E2.ACTIVE 
	cp 0 
	jr z, .no_collision
	pop de
	pop de 

	;; Copiamos datos Y de ambas entidades a intervalos
	push hl
	push de 

	;; E1.Y y E1.Height -> I1 


.no_collision:
	pop de 
	scf 	; Set Carry = 1 (no hay colisión)