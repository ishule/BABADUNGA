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

.continue:
    push hl
    call sys_collision_check_entity_vs_entity
    pop hl

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
    jr c, .loop_entities

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
	ld h, CMP_INFO_H 	; Player en HL
    inc l 
    inc l   ; FLAGS
    ld a, [hl]          ; Cargar FLAGS en A
    bit 0, a            ; Comprobar bit 0 (FLAG_CAN_TAKE_DAMAGE)
    ret z               ; Si bit = 0, saltar

    dec l 
    dec l
	push hl

	ld a, TYPE_BOSS
	call man_entity_locate_first_type 	; Boss en HL

	ld d, h 
	ld e, l 
	pop hl
    push hl

	call sys_collision_check_AABB
    pop hl
	ret c 


    ; ===== AQUÍ HAY COLISIÓN Y PUEDE RECIBIR DAÑO =====
    ld d , h 
    ld e, l
    ; 1. Quitar vida al jugador
    ; TODO: decrementar HP
    ; TODO: comprobar si HP = 0
    
    ; 2. Desactivar flag de daño

    ld h, CMP_INFO_H
    inc l 
    inc l               ; FLAGS
    res 0, [hl]         ; FLAG_CAN_TAKE_DAMAGE = 0
    
    ; 3. Iniciar timer de invencibilidad (60 frames = 1 seg, 120 = 2 seg)
    ld a, 120           ; 2 segundos a 60 FPS
    ld [player_invincibility_timer], a
    
    ; 4. Iniciar parpadeo
    ld a, 5             ; Parpadear cada 5 frames
    ld [player_blink_timer], a

    ld h, d 
    ld l, e

	ret


sys_collision_check_bullet_vs_boss::
    ; HL ya apunta a la bala
    inc l
    ld a, [hl]
    cp TYPE_BULLET      ; Verificar que sea bala
    ret nz
    dec l
    
    push hl
    
    ; Buscar boss
    ld a, TYPE_BOSS
    call man_entity_locate_first_type
    
    ; Verificar si boss puede recibir daño
    push hl
    inc l
    inc l               ; FLAGS
    bit 0, [hl]
    pop hl
    jr z, .boss_invincible
    
    ld d, h
    ld e, l
    pop hl
    push hl
    
    ; Comprobar AABB
    call sys_collision_check_AABB
    jr c, .no_collision
    
    ; ===== HAY COLISIÓN Y BOSS PUEDE RECIBIR DAÑO =====
    
    ; 1. Quitar vida al boss
    ; TODO: decrementar boss HP
    
    ; 2. Desactivar flag del boss
    ld h, d
    ld l, e
    inc l
    inc l               ; FLAGS
    res 0, [hl]
    
    ; 3. Iniciar invencibilidad del boss
    ld a, 60            ; 1 segundo
    ld [boss_invincibility_timer], a
    ld a, 5
    ld [boss_blink_timer], a
    
    ; 4. Eliminar bala
    pop hl
    inc l
    call delete_bullet
    
    ret
    
.boss_invincible:
    pop hl
    ret
    
.no_collision:
    pop hl
    ret


sys_collision_check_entity_vs_verja::
    push hl
    ld a, TYPE_VERJA
    call man_entity_locate_first_type

    ld d, h 
    ld e, l
    pop hl

    inc h
    inc l 
    ld a, [hl]  ;A = PosX

    cp $20          ; Compara con $20
    jr c, .check_verja_izquierda    ; Salta si B < $20 (es decir, B <= $1F)

.check_verja_derecha:
    dec h
    dec l
    push hl 
    inc de 
    inc de 
    inc de 
    inc de ; Me paso al siguiente sprite de la verja

    call sys_collision_check_AABB
    pop hl
    ret c 

    ld d, h 
    ld e, l
    call touching_right_collision
    ld h, d 
    ld l, e
    ret

.check_verja_izquierda:
    dec h
    dec l
    push hl

    call sys_collision_check_AABB
    pop hl
    ret c 

    ld d, h 
    ld e, l
    call touching_left_collision
    ld h, d 
    ld l, e
    ret

sys_collision_check_entity_vs_entity::
    inc l 
    ld a, [hl]
    dec l
    cp 0    ; TYPE = player
    jr z, check_collision_player

    inc l 
    ld a, [hl] 
    cp TYPE_BULLET
    jr z, check_collision_bullet


ret


check_collision_player::
    push hl
    call sys_collision_check_entity_vs_verja
    call sys_collision_check_player_vs_boss
    pop hl

    ret


check_collision_bullet::
    dec l 
    call sys_collision_check_entity_vs_verja
    call sys_collision_check_bullet_vs_boss
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

    cp 5 
    jr z, touching_up_collision

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

touching_up_collision:
    ; De momento solo puede tocar el techo las balas
    inc l
    call delete_bullet
    ret

delete_bullet::
    push de
    dec l
    ld [hl], 0      ; Marcar como inactiva

    ld a, l 
    srl a 
    srl a   ; Si dividimos l entre 4 tenemos el id de la entidad
    call man_entity_delete  
    pop de


    ret


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