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
	call sys_collision_check_player_bullets_vs_boss
	ret


;; Verifica si se solapan dos intervalos 1D
;; INPUT:
;;    - HL: puntero a (Y, H, X, W)
;;
;; MODIFICA: A, BC, HL
;;
;; RETURN: 
;;     - Registro F: C (carry) = no colisión, NC = colisión
;;
sys_collision_check_overlap::
    push bc            
    push hl             
    
    ; Calcular I1.End = I1.Pos + I1.Size - 1
    ld a, [I1]          ; A = I1.Pos
    ld hl, I1 + 1
    add [hl]            ; A = I1.Pos + I1.Size
    dec a               ; A = I1.End
    ld b, a             ; B = I1.End
    
    ; Caso 1: I1.End < I2.Start?
    ld a, [I2]          ; A = I2.Start
    cp b                ; Si I2.Start > I1.End
    jr nc, .no_collision ; ← CAMBIAR ret nc por jr nc
    
    ; Caso 2: I2.End < I1.Start?
    ld a, [I2]          ; A = I2.Pos
    ld hl, I2 + 1
    add [hl]            ; A = I2.Pos + I2.Size
    dec a               ; A = I2.End
    ld c, a             ; C = I2.End
    ld a, [I1]          ; A = I1.Start
    cp c                ; Si I1.Start > I2.End
    jr c, .collision    ; Si I1.Start < I2.End → colisión
    
.no_collision:
    pop hl              
    pop bc              
    scf                 ; Carry = no colisión
    ret
    
.collision:
    pop hl              
    pop bc              
    or a                ; Clear carry = colisión
    ret

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
	push hl
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
	inc h 		; h = $C1
	ld a, [hl] 	; A = E1.PosY
	ld [I1 + I_POS], a 

	inc h
	inc h 		; h = $C3
	ld a, [hl] 	; A = E1.Height 
	ld[I1 + I_SIZE], a 

	;; E2.Y y E2.Height -> I2 
	ld h, d 
	ld l, e 

	inc h 		; h = $C1
	ld a, [hl] 	; A = E2.PosY
	ld [I2 + I_POS], a 

	inc h
	inc h 		; h = $C3
	ld a, [hl] 	; A = E2.Height 
	ld[I2 + I_SIZE], a 

	;; Verificar overlap en Y 
	call sys_collision_check_overlap

	pop de 
	pop hl 

	ret c 	; Si no hay overlap en Y, es que no hay colisión


	;; Copiamos datos X de ambas entidades a intervalos 
	push hl 
	push de 

	;; E1.PosX y E1.Width -> I1 
	inc h 		; h = $C1
	inc l
	ld a, [hl] 	; A = E1.PosX
	ld [I1 + I_POS], a 

	inc h
	inc h 		; h = $C3
	ld a, [hl] 	; A = E1.Width
	ld[I1 + I_SIZE], a 

	;; E2.X y E2.Width -> I2 
	ld h, d 
	ld l, e 

	inc h 		; h = $C1
	inc l
	ld a, [hl] 	; A = E2.PosX
	ld [I2 + I_POS], a 

	inc h
	inc h 		; h = $C3
	ld a, [hl] 	; A = E2.Width
	ld[I2 + I_SIZE], a 

	;; Verificar overlap en Y 
	call sys_collision_check_overlap

	pop de 
	pop hl 

	ret

.no_collision:
	pop de 
	pop hl
	scf 	; Set Carry = 1 (no hay colisión)
	ret



sys_collision_check_player_vs_boss::
	ld hl, $C000
	ld de, $C008
	call sys_collision_check_AABB
	ret c 

	ld a, $00 
	ld[$C100], a 
	ld[$C101], a 

	ld [$C104], a 
	ld [$C105], a

	ret


sys_collision_check_player_bullets_vs_boss::
	ld hl, $C000


	ret