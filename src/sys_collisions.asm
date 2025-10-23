INCLUDE "consts.inc"
INCLUDE "collisions.inc"

SECTION "Collision System Values", WRAM0
;; Almacenan temporalmente los intervalos a comparar
intervalos:
I1: DS 2 	; Intervalo 1: [Pos, Size]
I2: DS 2 	; Intervalo 2: [Pos, Size]


SECTION "Collision System Code", ROM0 

sys_collision_check_all::
    ld hl, CMP_START_ADDRESS     ; Dirección base de la primera entidad
    ld a, [num_entities_alive]   
    ld b, a 					 ; B = número de entidades 
    ld c, 0                      ; C = índice actual

.loop_entities:
    ld a, [hl]                   ; Leer estado
    cp 0
    jr z, .next_entity           ; Si está inactiva, saltar


    call sys_collision_check_entity_vs_tiles
    ld h, d 
    ld l, e

    call sys_collision_check_entity_vs_entity
    ld h, d 
    ld l, e

.next_entity:
    ; Avanzar HL al siguiente bloque de entidad
    inc l 
    inc l 
    inc l 	; HL = $C003 (número de sprites)
    inc l

    ld a, [num_entities_alive]   
    ld b, a                      ; B = número de entidades 

    ld a, l 
    srl a 
    srl a   ; A = número de entidad actual
    cp b                         ; ¿hemos revisado todas?
    jr nz, .loop_entities

    ret

; INPUT: DE = entidades a saltar
; OUTPUT: DE = número de bytes que saltamos
multiply_DE_by_4:
	;; x2
    sla e 
    rl d 
    sla e
    rl d 

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

sys_collision_check_entity_vs_entity::
ret

;;INPUT:
;; - HL: Apunta a la direcciń 0 de la entidad (C0xx)
sys_collision_check_entity_vs_tiles::
	; Guardar puntero base
	ld d, h 
	ld e, l

    ld h, CMP_SPRITES_H 	; HL = $C1xx
    call get_address_of_tile_being_touched

    ld a, [hl]
    
    ;; Recuperar valor HL
    ld h, d
    ld l, e

    ; --- Si tile = 0 (aire) => no colisiona ---
    cp 0 	
    ret z

    ; --- Tile 1: pared izquierda ---
    cp 3
    jr z, touching_left_collision

    ; --- Tile 2: pared derecha ---
    cp 4
    jr z, touching_right_collision

    ret


touching_left_collision:
    inc l
    ld a, [hl]  ; A = TYPE 
    cp 3        ; 3 = Bullet
    jr z, delete_bullet

	;; Ajustar posición
	inc h       ; HL = C001 (X)
    ld a, [hl]

    inc a
    ld [hl], a          ; reposicionar

    ; Bloquear movimiento horizontal
    inc h 
    inc h 	; HL = $C300
    xor a 
    ld [hl], a

    dec l 
    dec l 
    dec l 
    dec l
    dec l 
    ld h, CMP_INFO_H

    ;; Ajustar posición
    inc h
    inc l               ; HL = C001 (X)
    ld a, [hl]

    inc a
    ld [hl], a          ; reposicionar

    ; Bloquear movimiento horizontal
    inc h 
    inc h   ; HL = $C300
    xor a 
    ld [hl], a

    ret


touching_right_collision:
    inc l
    ld a, [hl]  ; A = TYPE 
    cp 3        ; 3 = Bullet
    jr z, delete_bullet

    ;; Ajustar posición
    inc h       ; HL = C001 (X)
    ld a, [hl]

    dec a
    ld [hl], a          ; reposicionar

    ; Bloquear movimiento horizontal
    inc h 
    inc h   ; HL = $C300
    xor a 
    ld [hl], a

    dec l 
    dec l 
    dec l 
    dec l
    dec l 
    ld h, CMP_INFO_H

    ;; Ajustar posición
    inc h
    inc l               ; HL = C001 (X)
    ld a, [hl]

    dec a
    ld [hl], a          ; reposicionar

    ; Bloquear movimiento horizontal
    inc h 
    inc h   ; HL = $C300
    xor a 
    ld [hl], a

    ret

delete_bullet::
    dec l
    ld [hl], 0      ; Marcar como inactiva
    ld a, [num_entities_alive] ; TODO: Usar el id de la bala. No la última
    dec a
    call man_entity_delete  ; Aplicar cuando funcione la función




get_address_of_tile_being_touched::
    ; Sprite: [Y][X][ID][ATTR]
    ld a, [hl+]    ; A = Y, HL apunta a X
    ld b, a        ; B = Y
    ld a, [hl]     ; A = X
    
    ; Verificar límites de Y
    ld a, b
    cp 16
    jr c, .out_of_bounds    ; Si Y < 16, fuera del mapa
    
    ; Verificar límites de X
    ld a, [hl]
    cp 8
    jr c, .out_of_bounds    ; Si X < 8, fuera del mapa
    
    ; Convertir X a TX
    sub a, 8
    srl a
    srl a
    srl a          ; A = TX
    ld c, a        ; C = TX
    
    ; Convertir Y a TY
    ld a, b
    sub a, 16
    srl a
    srl a
    srl a          ; A = TY
    ld l, a        ; L = TY
    
    ; Calcular dirección
    ld a, c        ; A = TX
    call calculate_address_from_tx_and_ty
    ret

.out_of_bounds:
    ; Retornar dirección segura (tile 0 del mapa)
    ld hl, $9800
    ret

;;-------------------------------------------------------
convert_x_to_tx::
    ; TX = (X - 8) / 8
    cp 8
    jr c, .clamp_zero
    sub a, 8
    srl a
    srl a
    srl a
    ret
.clamp_zero:
    xor a          ; A = 0
    ret

;;-------------------------------------------------------
convert_y_to_ty::
    ; TY = (Y - 16) / 8
    cp 16
    jr c, .clamp_zero
    sub a, 16
    srl a
    srl a
    srl a
    ret
.clamp_zero:
    xor a          ; A = 0
    ret

;;-------------------------------------------------------
calculate_address_from_tx_and_ty::
    ; INPUT: L = TY, A = TX
    ; OUTPUT: HL = $9800 + TY * 32 + TX

    ld b, a        ; B = TX
    
    ; HL = TY * 32
    ld h, 0        ; HL = TY
    add hl, hl     ; x2
    add hl, hl     ; x4
    add hl, hl     ; x8
    add hl, hl     ; x16
    add hl, hl     ; x32
    
    ; HL += TX
    ld a, b
    add a, l
    ld l, a
    adc a, h
    sub a, l
    ld h, a
    
    ; HL += $9800
    ld bc, $9800
    add hl, bc
    
    ret