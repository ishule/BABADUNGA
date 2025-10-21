INCLUDE "consts.inc"
INCLUDE "collisions.inc"


SECTION "Collision System Values", WRAM0
;; Almacenan temporalmente los intervalos a comparar
temp_wall_x: DS 1
intervalos:
I1: DS 2 	; Intervalo 1: [Pos, Size]
I2: DS 2 	; Intervalo 2: [Pos, Size]


SECTION "Collision System Code", ROM0 


sys_collision_check_all::
	call sys_collision_check_player_vs_boss
	call sys_collision_check_player_bullets_vs_boss
	call sys_collision_check_boss_bullets_vs_player

	;; Check collision between player and tiles
	ld hl, CMP_START_ADDRESS 	; Player
	call sys_collision_check_entity_vs_tiles

	;; Check collision between boss and tiles
	;ld a, TYPE_BOSS
	;call man_entity_locate_first_type 	; Boss en HL
	;call sys_collision_check_entity_vs_tiles

	;call sys_collision_check_bullets_vs_tiles


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

	inc h 		; h = $C2
	inc h 
	inc h
	inc h 		; h = $C5
	inc l 
	inc l 		; hl -> $C502
	ld a, [hl] 	; A = E1.Height 
	ld[I1 + I_SIZE], a 

	;; E2.Y y E2.Height -> I2 
	ld h, d 
	ld l, e 

	inc h 		; h = $C1
	ld a, [hl] 	; A = E2.PosY
	ld [I2 + I_POS], a 

	inc h
	inc h 
	inc h
	inc h 		; h = $C5
	inc l
	inc l 		; hl -> $C502
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
	inc h 
	inc h
	inc h 		; h = $C5
	inc l 
	inc l 		; hl = $C503
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
	inc h 
	inc h
	inc h 		; h = $C5
	inc l 
	inc l 		; hl = $C503
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
	ld hl, CMP_START_ADDRESS 	; Player en HL
	push hl


	ld a, TYPE_BOSS
	call man_entity_locate_first_type 	; Boss en HL

	ld d, h 
	ld e, l 
	pop hl

	call sys_collision_check_AABB
	ret c 

;;====================================================
	;; AQUÍ YA SABEMOS QUE HAY COLISIÓN
	;; PROVISIONAL!!
	;; El comportamiento que queremos es que el jugador pierda vida
;;====================================================	
	

	;; TODO: EL JUGADOR PIERDE VIDA


	;; SOLO PASARÁ SI EL JUGADOR HA MUERTO
	;ld a, $00 
	;ld [CMP_START_ADDRESS], a  	; Marcar como inactiva cuando el jugador pierda todas las vidas

	;ld a, $00 
	;call man_entity_delete 	; Activar cuando el jugador pierda todas las vidas

	;ld a, $01
	;call man_entity_delete

	

    ; Código para hacer que el jugador parpadee + invencibilidad al jugador
    ;ld a, $00
    ;ld [blink_entity], a
    ;ld a, 30
    ;ld [blink_counter], a

	ret



sys_collision_check_player_bullets_vs_boss::
    ld a, 3
    ld de, sys_collision_bullet_boss_callback
    call man_entity_foreach_type
    ret

sys_collision_bullet_boss_callback:
    ; INPUT: A = ID de la bala, DE = dirección de la bala
    push de
    
    ld h, d
    ld l, e             ; HL = dirección de la bala
    push hl


	ld a, TYPE_BOSS
	call man_entity_locate_first_type 	; Boss en HL

	ld d, h 
	ld e, l 
	pop hl

    push hl
    call sys_collision_check_AABB
    
    pop hl
    pop de              ; Recuperar dirección bala
    ret c               ; No colisión
    

;;====================================================
	;; AQUÍ YA SABEMOS QUE HAY COLISIÓN
	;; PROVISIONAL!!
	;; El comportamiento que queremos es que el boss pierda vida y la bala desaparezca
;;====================================================	
    ld [hl], 0  	; Marcar como inactiva
    ld a, [num_entities_alive] ; TODO: Usar el id de la bala. No la última
    dec a
    call man_entity_delete 	; Aplicar cuando funcione la función




    ;;TODO: EL BOSS PIERDE VIDA


    ; Código para hacer que el boss parpadee + invencibilidad al boss
    ;ld a, $02
    ;ld [blink_entity], a
    ;ld a, 30
    ;ld [blink_counter], a

    
    ret


sys_collision_check_boss_bullets_vs_player::
    ld a, 3
    ld de, sys_collision_bullet_player_callback
    call man_entity_foreach_type
    ret

sys_collision_bullet_player_callback:
    ; INPUT: A = ID de la bala, DE = dirección de la bala
    push de
    
    ld h, d
    ld l, e             ; HL = dirección de la bala
    push hl


	ld a, TYPE_PLAYER
	call man_entity_locate_first_type 	; Boss en HL

	ld d, h 
	ld e, l 
	pop hl

    push hl
    call sys_collision_check_AABB
    
    pop hl
    pop de              ; Recuperar dirección bala
    ret c               ; No colisión
    
;;====================================================
	;; AQUÍ YA SABEMOS QUE HAY COLISIÓN
	;; PROVISIONAL!!
	;; El comportamiento que queremos es que el jugador pierda vida y la bala desaparezca
;;====================================================
    ld [hl], 0  	; Marcar como inactiva
    call man_entity_delete 	; Activar cuando vaya la función



    ;;TODO: EL BOSS PIERDE VIDA


    ; Código para hacer que el boss parpadee + invencibilidad al boss
    ;ld a, $02
    ;ld [blink_entity], a
    ;ld a, 30
    ;ld [blink_counter], a

    
    ret


sys_collision_check_bullets_vs_tiles::
    ld a, 3
    ld de, move_from_de_to_hl
    call man_entity_foreach_type
    ret

move_from_de_to_hl::
	ld h, d 
	ld l, e
	call sys_collision_check_entity_vs_tiles
	ret

;; INPUT: HL: direction to the player or the boss
sys_collision_check_entity_vs_tiles::
	ld a, [hl] 	; E_ACTIVE 
	cp 0 
	ret z 	; Si está inactiva, salir 

	;; Verificar colisión con el suelo
	push hl
	;call .check_floor
	pop hl

	;; Verificar colisíon con pared izquierda
	push hl
	call .check_wall_left 
	pop hl
	ret nc 

	;; Verificar colisión con pared derecha
	push hl
	call .check_wall_right 
	pop hl
	ret nc 

	scf 	; Set Carry (no hay colisión)

	ret 

.check_floor
	push hl
	ld h, CMP_SPRITES_H
	ld a, [hl] 	 
	ld d, a 	; D = Entity.PosY

	inc h 
	inc h 
	inc h
	inc h 		; h = $C5
	inc l 
	inc l 		; HL = $C502
	ld a, [hl] 	
	ld e, a 	; E = Entity.Height	

	ld a, d 
	add e 
	ld b, a 	; B = Entity.PosY + Entity.Height

	ld de, collision_array 
	ld a, [de] 	; Suelo.PosY
	sub $08
	cp b 
	pop hl

	jr nc, .no_floor_collision ; Si Suelo.PosY - 8 (margen) > (Entity.PosY + Entity.Height), no hay colisión
	
	;; HAY COLISIÓN CON EL SUELO
	push hl	
	ld h, CMP_PHYSICS_V_H
	; HL = $C300 = VY 
	xor a 
	ld [hl], a 
	inc h 	; HL = $C400 = AY 
	ld [hl], a

	or a ;Para limpiar Carry (colisión)
	pop hl

	ret

	.no_floor_collision:
		scf 	; Set Carry (no colisión)
		ret


.check_wall_left:
	push hl
	ld a, l
	ld hl, CMP_SPRITES_ADDRESS
	ld l, a 
	inc l
	ld a, [hl] 	 ; A = Entity.PosX
	push af

	ld de, collision_array 
	ld h, d 
	ld l, e 
	ld de, SIZEOF_COLLISION 
	add hl, de
	ld de, C_POSX 
	add hl, de
	ld a, [hl+] 	
	ld b, a 		; B = WallLeft.X

	inc l
	ld a, [hl] 		; A = WallLeft.Width

	add b 			; A = WallLeft.X + WallLeft.Width 
	ld b, a 		; B = WallLeft.X + WallLeft.Width
	pop af  		; A = Entity.PosX

	cp b
	pop hl 

	jr nc, .no_left_collision 	; Si Entity.PosX >= límite, no hay colisión

	;;HAY COLISIÓN: Empujar hacia la derecha 
	ld hl, CMP_START_ADDRESS
	inc l
	ld a, [hl]
	cp 03 	
	jr z, .delete_bullet 	; Si el tipo es 3, eliminamos la bala 
	dec l 


	ld a, l
	ld hl, CMP_SPRITES_ADDRESS
	ld l, a
	inc l 	; HL = Entity.PosX
	ld a, b 	; A = Límite izquierdo
	ld [hl], a 	; Entity.X = Límite izquierdo
	

	;; Detener velocidad y aceleración de X
	ld h, CMP_PHYSICS_V_H
	inc l 	; HL = $C301 = VX 
	xor a 
	ld [hl], a 
	inc h
	; HL = $C401 = AX 
	ld [hl], a

	ret 

.no_left_collision:
	scf 	; Set Carry (no hay colisión)
	ret


.check_wall_right:
	push hl
	ld a, l
	ld hl, CMP_SPRITES_ADDRESS
	ld l, a 
	inc l
	ld a, [hl] 	 
	ld d, a 	; D = Entity.PosX

	inc h
	inc h 
	inc h
	inc h 		; h = $C5
	inc l 
	inc l
	ld a, [hl]
	ld e, a 	; E = Entity.Width
	push de

	ld a, d 	; A = Entity.PosX 
	add e 		; 
	ld b, a 	; B = Entity.PosX + Entity.Width

	ld de, collision_array 
	ld h, d 
	ld l, e 
	ld de, SIZEOF_COLLISION 
	add hl, de
	add hl, de 	; Ahora si apunto al muro derecho
	ld de, C_POSX 
	add hl, de
	ld a, [hl] 	; A = WallRight.X
	push af

	cp b

	jr nc, .no_right_collision 	; Si límite >= Entity.PosX + Entity.Width, no hay colisión

	;;HAY COLISIÓN: Empujar hacia la izquierda 
	pop af 		; A = WallRight.X
	pop de 		; D = Entity.PosX   E = Entity.Width
	pop hl
	sub e 		; A = WallRight.X - Entity.Width
	ld [temp_wall_x], a 	;Guardo en VRAM el valor de a

	inc l 
	ld a, l 
	cp 0
	jr z, .assign_player


.assign_boss 
	ld a, TYPE_BOSS
	jr .continue

.assign_player
	ld a, TYPE_PLAYER

.continue
	ld de, .move_left
	call man_entity_foreach_type
	ret

.move_left:
	ld h, CMP_SPRITES_H
	ld l, e
	inc l 	; HL = Entity.PosX

	ld a, [temp_wall_x]
	ld [hl], a 	; Entity.X = Límite derecho - WallRight.X
	

	;; Detener velocidad y aceleración de X
	ld h, CMP_PHYSICS_V_H
	xor a 
	ld [hl], a 
	inc h 	; HL = $C401 = AX 
	ld [hl], a

	ret 

.no_right_collision:
	pop af 
	pop de
	pop hl
	scf 	; Set Carry (no hay colisión)
	ret



.delete_bullet:
	dec l
    ld [hl], 0  	; Marcar como inactiva
    ;call man_entity_delete 	; Activar cuando vaya la función

    ;; Eliminar 
    inc h
    ld a, $00
    ld [hl+], a 
    ld [hl], a
    ret nc



