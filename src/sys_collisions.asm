INCLUDE "consts.inc"
INCLUDE "collisions.inc"

SECTION "Collision System Values", WRAM0
;; Almacenan temporalmente los intervalos a comparar
intervalos:
I1: DS 2 	; Intervalo 1: [Pos, Size]
I2: DS 2 	; Intervalo 2: [Pos, Size]

SECTION "Bullet Collision Vars", WRAM0
current_bullet_offset: DS 1


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

    inc l 
    inc l
    bit 5, [hl]     ; Ver si flag STILL BULLET está a 1 
    jr nz, .adjust_l_for_still_bullet   ; Si está a 1 saltamos a siguiente entidad

    dec l 
    ld a, [hl]
    dec l 
    cp TYPE_VERJA ; Si es verja saltar colisiones
    jr z, .next_entity

    inc l
    cp TYPE_BOSS
    jr nz, .skip_flag

    inc l 
    res 3, [hl]     ; Desactivar flag GOT_DAMAGE
    dec l
    dec l 
    jr .continue

.skip_flag:
    dec l
    call sys_collision_check_entity_vs_tiles
    ld h, d 
    ld l, e

.continue:
    push hl
    call sys_collision_check_entity_vs_entity
    pop hl
    jr .next_entity 

.adjust_l_for_still_bullet:
    dec l
    dec l

.next_entity:
    ; Avanzar HL al siguiente bloque de entidad
    ld a, 4 
    add l 
    ld l, a

    ld a, [num_entities_alive]   
    ld b, a                      ; B = número de entidades 

    ld a, l 
    srl a 
    srl a   ; A = número de entidad actual
    cp b                         ; ¿hemos revisado todas?
    jr c, .loop_entities

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
    ld b, a

    ld a, 4 
    add h 
    ld h, a     ; H = $C5
    ld a, [hl]  ; HL = Offset_Y
    add b       ; A = PosY + OffsetY
    ld [I1 + I_POS], a 

	inc l 
	inc l 		; hl -> $C502
	ld a, [hl] 	; A = E1.Height 
	ld[I1 + I_SIZE], a 

	;; E2.Y y E2.Height -> I2 
	ld h, d 
	ld l, e 

	inc h 		; h = $C1
	ld a, [hl] 	; A = E2.PosY
	ld b, a 

    ld a, 4 
    add h 
    ld h, a     ; H = $C5
    ld a, [hl]  ; HL = Offset_Y
    add b       ; A = PosY + OffsetY
    ld [I2 + I_POS], a 

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
	ld b, a 

    ld a, 4 
    add h 
    ld h, a     ; H = $C5
    ld a, [hl]  ; HL = Offset_X
    add b       ; A = PosX + OffsetX
    ld [I1 + I_POS], a 

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
	ld b, a 

    ld a, 4 
    add h 
    ld h, a     ; H = $C5
    ld a, [hl]  ; HL = Offset_X
    add b       ; A = PosX + OffsetX
    ld [I2 + I_POS], a 

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
	ld d, h 
    ld e, l     ; Player en de
    push de

	ld a, TYPE_BOSS
	call man_entity_locate_first_type 	; Boss en HL

    pop de      ; DE = Player

    .loop_boss:
        push hl
        push de

        inc l 
        ld a, [hl]
        cp TYPE_BOSS
        jr nz, .no_collision_detected

        dec l

    	call sys_collision_check_AABB
        pop de
        pop hl

    	jr nc, .collision_detected

        ld a, 4 
        add l 
        ld l, a   ; Pasamos a la siguiente entidad
        jr .loop_boss

    .no_collision_detected:
        dec l
        pop de
        pop hl
        ret 

    .collision_detected:
    ; ===== AQUÍ HAY COLISIÓN Y PUEDE RECIBIR DAÑO =====
    
    ; 1. Quitar vida al jugador
    push hl
    push de
    inc h ; Fisicas
    inc h
    inc l
    inc l
    inc l ; Daño
    ld b, [hl]
    ld a,[player_health]
    cp b
    jr c, .set_health_zero
    sub b
    jr .quitar_vida
.set_health_zero:
    xor a
.quitar_vida:
    ld [player_health], a
    call sys_sound_hit_effect
    pop de
    pop hl

    call sys_sound_player_gets_hit_effect
    ; TODO: decrementar HP
    ; TODO: comprobar si HP = 0
    
    ; 2. Desactivar flag de daño
    ld h , d
    ld l, e
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
    dec l
    cp TYPE_BULLET
    ret nz

    ; Verificar si es bala del jugador
    inc l
    inc l           ; FLAGS de la bala
    ld a, [hl]
    dec l 
    dec l
    bit 4, a        ; FLAG_BULLET_PLAYER (bit 4)
    ret z           ; Si NO es bala del jugador, salir
    
    ; Guardar bala
    ld d, h 
    ld e, l         ; DE = bullet
    
    ; Buscar primer boss
    push de
    ld a, TYPE_BOSS
    call man_entity_locate_first_type   ; HL = primera entidad del boss
    pop de
    
    ; Verificar si el boss puede recibir daño (UNA SOLA VEZ)
    push hl
    inc l
    inc l           ; FLAGS
    bit 0, [hl]
    pop hl
    ret z           ; Si es invencible, salir (todo el boss es invencible)
    
    ; Ahora iterar por todas las partes del boss
.loop_boss:
    push hl         ; [1] Guardar parte del boss actual
    push de         ; [2] Guardar bullet
    
    ; Verificar si sigue siendo TYPE_BOSS
    inc l
    ld a, [hl]
    cp TYPE_BOSS
    jr nz, .end_loop    ; Si ya no es boss, terminamos
    dec l
    
    ; Comprobar colisión (HL = parte del boss, DE = bullet)
    call sys_collision_check_AABB
    jr nc, .collision_detected
    
    ; No colisionó con esta parte, siguiente
    pop de          ; [2] Recuperar bullet
    pop hl          ; [1] Recuperar parte actual
    
    ; Avanzar a siguiente parte del boss
    ld a, l
    add a, 4
    ld l, a
    
    jr .loop_boss

.end_loop:
    ; Llegamos al final sin colisión
    pop de          ; [2]
    pop hl          ; [1]
    ret

.collision_detected:
    pop de          ; [2] DE = bullet
    pop hl          ; [1] HL = parte del boss que colisionó
    
    ; === HAY COLISIÓN ===
    
    ; 1. Quitar vida al boss
    push hl
    push de
    inc d ; Fisicas
    inc d
    inc e
    inc e
    inc e ; Daño
    ld a, [de]
    ld b,a
    ld a,[boss_health]
    cp b
    jr c, .set_health_zero
    sub b
    jr .quitar_vida
.set_health_zero:
    xor a
.quitar_vida:
    ld [boss_health], a
    call sys_sound_hit_effect
    pop de
    pop hl
    
    ; 2. Activar flags del boss (en la PRIMERA parte)
    ; Necesitamos volver a la primera parte del boss
    push de
    push hl
    ld a, TYPE_BOSS
    call man_entity_locate_first_type   ; HL = primera parte
    inc l
    inc l           ; FLAGS
    set 3, [hl]     ; GOT_DAMAGE
    res 0, [hl]     ; CAN_TAKE_DAMAGE = 0
    pop hl
    pop de
    
    ; 3. Iniciar invencibilidad
    ld a, 60
    ld [boss_invincibility_timer], a
    ld a, 5
    ld [boss_blink_timer], a
    
    ; 4. Eliminar bala
    ld h, d
    ld l, e
    inc l
    call delete_bullet
    
    ret



sys_collision_check_bullet_vs_player::
    ; HL ya apunta a la bala
    inc l
    ld a, [hl]
    cp TYPE_BULLET      ; Verificar que sea bala
    ret nz
    dec l
    
    push hl
    
    ; Buscar player
    ld a, TYPE_PLAYER
    call man_entity_locate_first_type
    
    ; Verificar si player puede recibir daño
    push hl
    inc l
    inc l               ; FLAGS
    bit 0, [hl]
    pop hl
    jr z, .player_invincible
    
    ld d, h
    ld e, l
    pop hl
    push hl
    
    ; Comprobar AABB
    call sys_collision_check_AABB
    jr c, .no_collision
    
    ; ===== HAY COLISIÓN Y PLAYER PUEDE RECIBIR DAÑO =====
    
    ; 1. Quitar vida al player
    ; TODO: decrementar player HP
    push hl
    push de
    ld d, h 
    ld e, l
    inc d ; Fisicas
    inc d
    inc e
    inc e
    inc e ; Daño
    ld a, [de]
    ld b,a
    ld a,[player_health]
    cp b
    jr c, .set_health_zero
    sub b
    jr .quitar_vida
.set_health_zero:
    xor a
.quitar_vida:
    ld [player_health], a
    call sys_sound_hit_effect
    pop de
    pop hl
    ; 2. Desactivar flag del player
    ld h, d
    ld l, e
    inc l
    inc l               ; FLAGS
    res 0, [hl]
    
    ; 3. Iniciar invencibilidad del boss
    ld a, 60            ; 1 segundo
    ld [player_invincibility_timer], a
    ld a, 5
    ld [player_blink_timer], a
    
    ; 4. Eliminar bala
    pop hl
    inc l
    call delete_bullet
    
    ret
    
.player_invincible:
    pop hl
    ret
    
.no_collision:
    pop hl
    ret



sys_collision_check_bullet_vs_bullet::
    ; HL apunta a la bala actual
    inc l
    ld a, [hl]
    cp TYPE_BULLET
    ret nz
    dec l
    
    ; Guardar offset de bala actual
    ld a, l
    ld [current_bullet_offset], a
    
    ; Verificar si la bala actual tiene FLAG_BULLET_PLAYER
    inc l
    inc l               ; FLAGS
    ld a, [hl]
    bit 4, a            ; FLAG_BULLET_PLAYER
    dec l
    dec l               ; Volver al inicio
    
    ld c, a             ; C = flags de bala actual (para comparar después)
    
    ; Obtener número de entidades
    ld a, [num_entities_alive]
    ld b, a             ; B = contador
    xor a               ; A = ID = 0
    
.loop:
    push bc
    push af
    
    ; Calcular offset de la entidad a comparar
    add a
    add a               ; A = ID * 4
    
    ; Verificar que no sea la misma bala
    ld e, a             ; E = offset temporal
    ld a, [current_bullet_offset]
    cp e
    jr z, .skip         ; Es la misma, saltar
    
    ; Verificar que esté activa y sea bala
    ld h, CMP_INFO_H
    ld l, e
    ld a, [hl]          ; Active?
    or a
    jr z, .skip
    
    inc l
    ld a, [hl]          ; Type
    cp TYPE_BULLET
    jr nz, .skip
    
    ; Verificar flags de la otra bala
    inc l               ; FLAGS de otra bala
    ld a, [hl]
    bit 4, a            ; ¿Tiene FLAG_BULLET_PLAYER?
    
    ; Verificar que una tenga el flag y la otra no
    ; XOR: si ambas tienen el flag o ninguna lo tiene → skip
    jr z, .check_xor    ; Otra bala NO tiene flag
    
    ; Otra bala SÍ tiene flag, verificar que actual NO lo tenga
    bit 4, c            ; ¿Bala actual tiene flag?
    jr nz, .skip        ; Ambas tienen flag → skip
    jr .do_collision_check
    
.check_xor:
    ; Otra bala NO tiene flag, verificar que actual SÍ lo tenga
    bit 4, c
    jr z, .skip         ; Ninguna tiene flag → skip
    
.do_collision_check:
    ; Una tiene flag y la otra no → comprobar colisión
    dec l
    dec l               ; Volver al inicio de otra bala
    
    ld d, h
    ld e, l             ; DE = otra bala
    
    ld a, [current_bullet_offset]
    ld h, CMP_INFO_H
    ld l, a             ; HL = bala actual
    
    push hl
    push de
    call sys_collision_check_AABB
    pop de
    pop hl
    jr c, .skip         ; No colisionan
    
    ; ===== COLISIÓN DETECTADA =====
    ; Determinar cuál tiene FLAG_BULLET_PLAYER y eliminar solo esa
    
    ; Verificar bala actual
    push hl
    push de
    inc l
    inc l               ; FLAGS bala actual
    bit 4, [hl]
    pop de
    pop hl
    jr nz, .delete_current
    
    ; La otra bala tiene el flag
.delete_other:
    ld h, d
    ld l, e
    ld [hl], 0          ; Marcar inactiva
    inc l
    call delete_bullet
    jr .exit_after_delete
    
.delete_current:
    ld [hl], 0          ; Marcar inactiva
    inc l
    call delete_bullet
    pop af
    pop bc
    ret                 ; Salir (bala actual eliminada)
    
.exit_after_delete:
    ; Continuar loop (bala actual sigue viva)
    jr .skip
    
.skip:
    pop af
    pop bc
    inc a               ; Siguiente ID
    dec b
    jr nz, .loop
    
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
    push hl             ; [1] Guardar HL original
    inc l 
    ld a, [hl]
    cp TYPE_PLAYER    
    jr z, check_collision_player
    cp TYPE_BULLET
    jr z, check_collision_bullet
    pop hl              ; [1] Restaurar
    ret

check_collision_player:
    dec l               ; HL = inicio entidad
    call sys_collision_check_entity_vs_verja
    call sys_collision_check_player_vs_boss
    pop hl              ; [1] ← Recuperar el push inicial
    ret

check_collision_bullet:
    dec l               ; HL = inicio entidad
    call sys_collision_check_entity_vs_verja
    call sys_collision_check_bullet_vs_boss
    call sys_collision_check_bullet_vs_player

    ;; Solo compruebo bala con bala si es bala del jugador
    inc l 
    inc l 
    ld a, [hl] 
    dec l 
    dec l
    bit 4, a
    jr z, .end
    call sys_collision_check_bullet_vs_bullet
    pop hl              ; [1] ← Recuperar el push inicial
    ret

.end:
    pop hl 
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

    ; --- Tile 3: pared izquierda ---
    cp 3
    jr z, touching_left_collision

    ; --- Tile 4: pared derecha ---
    cp 4
    jr z, touching_right_collision

    ; --- Tile 5: techo  ---
    cp 5 
    jr z, touching_up_collision

    ; --- Tile 2: suelo ---
    cp 2
    jr z, touching_up_collision

    ; --- Tile 6: suelo abajo ---
    cp 6
    jr z, touching_up_collision

    ret


; B = 0 → izquierda (inc), B = 1 → derecha (dec)
touching_horizontal_collision:
    ld c, b             ; C = dirección (0=izq, 1=der)
    
    inc l
    ld a, [hl]
    cp TYPE_BULLET
    jr z, delete_bullet
    
    ; Ajustar sprite X
    inc h
    ld a, [hl]
    bit 0, c
    jr z, .inc_sprite
    dec a
    jr .apply_sprite
.inc_sprite:
    inc a
.apply_sprite:
    ld [hl], a
    
    ; Bloquear velocidad sprite
    inc h
    inc h
    xor a
    ld [hl], a
    
    ; Ajustar Info X
    dec l
    dec l
    dec l
    dec l
    dec l
    ld h, CMP_INFO_H
    inc h
    inc l
    ld a, [hl]
    bit 0, c            ; Usar C en lugar de B
    jr z, .inc_info
    dec a
    jr .apply_info
.inc_info:
    inc a
.apply_info:
    ld [hl], a
    
    ; Bloquear velocidad info
    inc h
    inc h
    xor a
    ld [hl], a
    
    ret

touching_left_collision:
    ld b, 0
    jr touching_horizontal_collision

touching_right_collision:
    ld b, 1
    jr touching_horizontal_collision

touching_up_collision:
    ; De momento solo puede tocar el techo las balas
    inc l
    call delete_bullet
    ret

delete_bullet::
    dec l
    ld [hl], 0      ; Marcar como inactiva

    ld a, l 
    srl a 
    srl a   ; Si dividimos l entre 4 tenemos el id de la entidad
    call man_entity_delete  


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
convert_coord_to_tile:
    cp b
    jr c, .clamp
    sub b
    srl a
    srl a
    srl a
    ret
.clamp:
    xor a
    ret

convert_x_to_tx::
    ld b, 8
    jr convert_coord_to_tile
    
convert_y_to_ty::
    ld b, 16
    jr convert_coord_to_tile

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