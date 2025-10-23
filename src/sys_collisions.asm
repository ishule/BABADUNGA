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

    push bc                      ; Guardar contador
    push hl                      ; Guardar puntero de entidad

    call sys_collision_check_entity_vs_tiles

    pop hl
    pop bc

.next_entity:
    ; Avanzar HL al siguiente bloque de entidad
    inc l 
    inc l 
    inc l 	; HL = $C003 (número de sprites)
    ld a, [hl] 	; A = número de sprites

    dec l 
    dec l 
    dec l
   
   	ld d, 0 
   	ld e, a
    call multiply_DE_by_4 ; A = entidades a saltar

    add hl, de

    inc c                        ; C++
    ld a, c
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

;;INPUT:
;; - HL: Apunta a la direcciń 0 de la entidad (C0xx)
sys_collision_check_entity_vs_tiles::
	; Guardar puntero base
	ld d, h 
	ld l, e

    ld h, CMP_COLLISIONS_H 	; HL = $C5 
    inc l 
    inc l 	; HL = $C502
    ld a, [hl+] 	; Height 
    ld b, a
    ld a, [hl] 		; Width
    ld c, a 

    push bc

    dec l 
    dec l 
    dec l
    ld h, CMP_SPRITES_H 	; HL = $C1xx
    call get_address_of_tile_being_touched

    pop bc

    ld a, [hl]


    
    ;; Recuperar valor HL
    ld h, d 
    ld l, e 	

    ; --- Si tile = 0 (aire) => no colisiona ---
    cp 0 	
    ret z

    ; --- Tile 1: pared izquierda ---
    cp 1
    jr z, .touching_left

    ; --- Tile 2: pared derecha ---
    cp 2
    jr z, .touching_right

    ret


.touching_left:

	;; Ajustar posición
	inc h
    inc l               ; HL = C001 (X)
    ld a, [hl]

    inc a
    ld [hl], a          ; reposicionar

    ; Bloquear movimiento horizontal
    inc h 
    inc h 	; HL = $C300
    ld a, $00 
    ld [hl], a

    ret


.touching_right:
	;; Ajustar posición
	inc h
    inc l               ; HL = C001 (X)
    ld a, [hl]

    dec a
    ld [hl], a          ; reposicionar

    ; Bloquear movimiento horizontal
    inc h 
    inc h 	; HL = $C300
    ld a, $00 
    ld [hl], a

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

;; Gets the Address in VRAM of the tile the entity is touching.
;; INPUT:
;; HL: Address of the Sprite Component
;; OUTPUT:
;; HL: VRAM Address of the tile the sprite is touching
get_address_of_tile_being_touched::
    ; Sprite en memoria: [Y][X][ID][ATTR]
    
    ; Convertir Y a TY
    ld a, [hl+]    ; A = Y
    push hl        ; Guardar dirección de X
    call convert_y_to_ty
    ld l, a        ; L = TY
    
    ; Convertir X a TX
    pop hl         ; Recuperar dirección de X
    ld a, [hl]     ; A = X
    call convert_x_to_tx
    ; A = TX, L = TY
    
    ; Calcular dirección en VRAM
    call calculate_address_from_tx_and_ty
    
    ret

;;-------------------------------------------------------
;; Converts sprite X-coordinate to tilemap TX-coordinate
;; INPUT: A = Sprite X-coordinate
;; OUTPUT: A = TX-coordinate
convert_x_to_tx::
    ; TX = (X - 8) / 8
    sub a, 8       ; A = X - 8
    srl a          ; A = A / 2
    srl a          ; A = A / 2
    srl a          ; A = A / 2  (total: / 8)
    ret

;;-------------------------------------------------------
;; Converts sprite Y-coordinate to tilemap TY-coordinate
;; INPUT: A = Sprite Y-coordinate
;; OUTPUT: A = TY-coordinate
convert_y_to_ty::
    ; TY = (Y - 16) / 8
    sub a, 16      ; A = Y - 16
    srl a          ; A = A / 2
    srl a          ; A = A / 2
    srl a          ; A = A / 2  (total: / 8)
    ret

;;-------------------------------------------------------
;; Calculates VRAM Tilemap Address from tile coordinates
;; INPUT: L = TY coordinate, A = TX coordinate
;; OUTPUT: HL = Address where the (TX, TY) tile is stored
calculate_address_from_tx_and_ty::
    ; Dirección = $9800 + TY * 32 + TX
    ; TY * 32 = TY * 2^5 = TY << 5
    
    push bc
    
    ; Guardar TX
    ld b, a        ; B = TX
    
    ; HL = TY * 32
    ld h, 0        ; HL = TY (ya está en L)
    
    ; Multiplicar por 32 (shift left 5 veces)
    add hl, hl     ; x2
    add hl, hl     ; x4
    add hl, hl     ; x8
    add hl, hl     ; x16
    add hl, hl     ; x32
    
    ; Sumar TX
    ld a, b
    add a, l
    ld l, a
    ld a, 0
    adc a, h
    ld h, a
    
    ; Sumar dirección base $9800
    ld bc, $9800
    add hl, bc
    
    pop bc
    ret
