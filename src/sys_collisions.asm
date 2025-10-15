INCLUDE "consts.inc"
INCLUDE "collisions.inc"


SECTION "Collision System Values", WRAM0
;; Almacenan temporalmente los intervalos a comparar
intervalos:
I1: DS 2 	; Intervalo 1: [Pos, Size]
I2: DS 2 	; Intervalo 2: [Pos, Size]


SECTION "Collision System Code", ROM0 


sys_collision_check_all::
	call sys_collision_check_player_vs_boss
	ret

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
	pop hl

	;; Copiamos datos Y de ambas entidades a intervalos
	push hl
	push de 

	;; E1.PosY y E1.Height -> I1 
	inc h 
	inc h 		; h = $C2
	ld a, [hl] 	; A = E1.PosY
	ld [I1 + I_POS], a 

	inc h 		; h = $C3
	ld a, [hl] 	; A = E1.Height 
	ld[I1 + I_SIZE], a 

	;; E2.Y y E2.Height -> I2 
	ld h, d 
	ld l, e 

	inc h 
	inc h 		; h = $C2
	ld a, [hl] 	; A = E2.PosY
	ld [I2 + I_POS], a 

	inc h 		; h = $C3
	ld a, [hl] 	; A = E2.Height 
	ld[I2 + I_SIZE], a 

	;; Verificar overlap en Y 
	ld hl, intervalos 
	call sys_collision_check_overlap

	pop de 
	pop hl 

	ret c 	; Si no hay overlap en Y, es que no hay colisión


	;; Copiamos datos X de ambas entidades a intervalos 
	push hl 
	push de 

	;; E1.PosX y E1.Width -> I1 
	inc h 
	inc h 		; h = $C2
	inc l
	ld a, [hl] 	; A = E1.PosX
	ld [I1 + I_POS], a 

	inc h 		; h = $C3
	ld a, [hl] 	; A = E1.Width
	ld[I1 + I_SIZE], a 

	;; E2.X y E2.Width -> I2 
	ld h, d 
	ld l, e 

	inc h 
	inc h 		; h = $C2
	inc l
	ld a, [hl] 	; A = E2.PosX
	ld [I2 + I_POS], a 

	inc h 		; h = $C3
	ld a, [hl] 	; A = E2.Width
	ld[I2 + I_SIZE], a 

	;; Verificar overlap en Y 
	ld hl, intervalos 
	call sys_collision_check_overlap

	pop de 
	pop hl 

	ret

.no_collision:
	pop de 
	scf 	; Set Carry = 1 (no hay colisión)
	ret



sys_collision_check_player_vs_boss::
	ld hl, $C000
	ld de, $C008
	call sys_collision_check_AABB
	ret c 

	ld a, $00 
	call man_entity_delete

	ret