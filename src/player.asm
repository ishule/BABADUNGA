INCLUDE "consts.inc"

SECTION "Player Variables", WRAM0 
player_orientation:: DS 1	; 0 = derecha, 1 = izquierda
player_stand_or_walk:: DS 1 ; 0 = parado, 1 = caminando

SECTION "Player Code", ROM0


player_sprites:
	DB $00, $00, $06, %10000000	;; Izquierdo, personaje
	DB $00, $00, $08, %10000000	;; Derecho, cerbatana


;;============================================================
;; init_player 
;; Inicialización completa del jugador 
;;
;; MODIFICA: A, BC, DE, HL
init_player::
	call init_player_tiles
	call init_player_entity
	call player_init_physics
	ret


;;============================================================
;; init_player_tiles
;; Carga los gráficos del jugador en VRAM
;;
;; Tiles carrgados:
;;		$06-$07: Player_stand
;;		$08-$09: Player_blowgun
;;		$0A-$0B: Player_walk 
;;      $0C: Player_bullet
;;	    $0D: Player_life 
;; MODIFICA: A, BC, DE, HL
init_player_tiles::
	call wait_vblank

	;; Cargar Player_stand en tiles $06-$07
	ld hl, Player_stand
	ld de, VRAM_TILE_DATA_START + ($06 * VRAM_TILE_SIZE)
	ld b, 2 * VRAM_TILE_SIZE	; 2 tiles de 16 bytes cada uno
	call memcpy_256

	;; Cargar Player_blowgun en tiles $08-$09
	ld hl, Player_blowgun
	ld de, VRAM_TILE_DATA_START + ($08 * VRAM_TILE_SIZE)
	ld b, 2 * VRAM_TILE_SIZE
	call memcpy_256

	;; Cargar Player_walk en tiles $0A-$0B 
	ld hl, Player_walk
	ld de, VRAM_TILE_DATA_START + ($0A * VRAM_TILE_SIZE)
	ld b, 2 * VRAM_TILE_SIZE
	call memcpy_256
	;; Cargar Player_bullet en tile $0C
	ld hl,Player_bullet
	ld de,VRAM_TILE_DATA_START + ($0C*VRAM_TILE_SIZE)
	ld b,VRAM_TILE_SIZE
	call memcpy_256
	;; Cargar Player_life en tile $0D
	call wait_vblank
	ld hl,Player_life
	ld de,VRAM_TILE_DATA_START + ($0D*VRAM_TILE_SIZE)
	ld b,2*VRAM_TILE_SIZE
	call memcpy_256

	ret

;;============================================================
;; init_player_entity
;; Crea las entidades de sprites del jugador en OAM
;;
;; Reserva 2 sprites:
;;		- Sprite 1 ($C000): Cuerpo del jugador
;;		- Sprite 2 ($C004): Cerbatana
;;
;; MODIFICA: A, BC, DE, HL
init_player_entity::
	call man_entity_init	; Inicializar gestor de entidades

	; Alocar primer sprite
	call man_entity_alloc
	;; HL = $C000 (primera posición OAM)
	ld d, h 
	ld e, l 
	ld hl, player_sprites
	ld b, SPRITE_SIZE	; 4 bytes por sprite
	call memcpy_256

	; Alocar segundo sprite
	call man_entity_alloc
	;; HL = $C004 (segunda posición OAM)
	ld d, h 
	ld e, l 
	ld hl, player_sprites + 4
	ld b, SPRITE_SIZE
	call memcpy_256

	call wait_vblank
	call man_entity_draw	; Copiar sprites a OAM

	ret


;;=================================================
;; player_init_physics
;; Inicializa el componente de las físicas del jugador
;;
;; Establece:
;; 		- Posición inicial
;; 		- Velocidad inicial: 0, 0 
;; 		- Estado de animación: parado 
;;
;; MODIFICA: A, BC, DE
player_init_physics:: 
	ld de, component_physics 
	ld b, PLAYER_INITIAL_POS_X	; X inicial
	ld c, GROUND_Y				; Y inicial
	call entity_physics_init

	; Player stand al principio 
	ld a, 00 
	ld [player_stand_or_walk], a

	call player_update_sprite_position 

	ret 
 
;;===========================================================
;; flip_right
;; Orienta el jugador hacia la derecha
;; Acciones: 
;;		- Quita el flip si lo hubiese
;;		- Actualiza player_orientation = 0
;;
;; MODIFICA: A, DE
flip_right::
	; Flipear sprite 1 (jugador) a la derecha == Sin flip
    ld de, component_sprite
    inc de ; Saltar Y
    inc de ; Saltar X
    inc de ; Saltar tiles y apuntar a atributos
    ld a, SPRITE_ATTR_NO_FLIP
    ld [de], a

    ; Flipear sprite 2 (cerbatana) a la derecha == Sin flip
    inc de 
    inc de
    inc de 
    inc de 
    ld a, SPRITE_ATTR_NO_FLIP
    ld [de], a

    ; Actualizar orientación
    ld a, 00
    ld [player_orientation], a 	; Orientación a la derecha
    
    ret


;;===========================================================
;; flip_left
;; Orienta el jugador hacia la izquierda
;; Acciones: 
;;		- Activa el flip horizontal de ambos sprites
;;		- Actualiza player_orientation = 1
;;
;; MODIFICA: A, DE
flip_left::
	; Flipear sprite 1 (jugador)
    ld de, component_sprite
    inc de 
    inc de 
    inc de 
    ld a, SPRITE_ATTR_FLIP_X
    ld [de], a

    ; Flipear sprite 2 (cerbatana)
    inc de 
    inc de
    inc de 
    inc de 
    ld a, SPRITE_ATTR_FLIP_X
    ld [de], a

    ; Actualizar orientación
    ld a, 01
    ld [player_orientation], a 	; Orientación a la izquierda
    
    ret


;;=================================================
;; player_update_movement
;; Actualiza el movimiento del jugador
;;
;; Cada frame hace lo siguiente:
;;		1. Lectura de input del joypad (en este caso detecta si es 1 por como está configurado joypad.asm)
;;		2. Movimiento horizontal (izquierda/derecha)
;;		3. Salto (solo si está en el suelo)
;;		4. Aplicación de gravedad
;;		5. Límite de velocidad de caída
;;		6. Detección de suelo
;;		7. Actualización de posición de sprites
;;		
;; MODIFICA: A, BC, DE, HL
player_update_movement::
    call joypad_read
    ld a, [joypad_input]
    
    ; ===== MOVIMIENTO HORIZONTAL =====
    ld b, 0  ; VX por defecto

    ; Comprobar DERECHA
    bit JOYPAD_RIGHT, a 
    jr z, .check_left			; Si es 0, sabemos que no es derecha
    ld b, PLAYER_SPEED 			; VX = velocidad positiva

    call flip_right				; Orientar a la derecha
    call choose_stand_or_walk	; Alternar animación
    jr .set_horizontal
    
.check_left:
	; Comprobar IZQUIERDA
    bit JOYPAD_LEFT, a 
    jr z, .set_horizontal
    ld b, -PLAYER_SPEED			; VX = velocidad negativa

    call flip_left				; Orientar a la izquierda
    call choose_stand_or_walk	; Alternar animación

.set_horizontal:
    ; Solo escribir VX manualmente (sin tocar VY)
    ld de, component_physics
    inc de  ; Saltar Y
    inc de  ; Saltar X
    ld a, b
    ld [de], a  ; Escribir VX
    
    ; ===== SALTO =====
    ld a, [joypad_input]
    bit JOYPAD_UP, a 
    jr z, .apply_gravity
    
    ; Comprobar si está en el suelo
    ld de, component_physics
    call entity_physics_get_position
    ld a, c
    cp GROUND_Y
    jr nz, .apply_gravity		; Si no está en el suelo, no puede saltar
    
    ; Aplicar fuerza de salta (VY negativa)
    ld de, component_physics
    inc de
    inc de
    inc de  ; Apuntar a VY
    
    ld a, PLAYER_JUMP_FORCE	; Velocidad vertical negativa
    ld [de], a

    jr .limit_fall_speed
    
.apply_gravity:
    ; Aplicar gravedad solo si no está en el suelo
    ld de, component_physics
    call entity_physics_get_position
    ld a, c
    cp GROUND_Y
    jr z, .limit_fall_speed		; Si está en el suelo, no aplicar gravedad
    
    ; Añadir gravedad a VY
    ld de, component_physics 
    ld b, 0 
    ld c, PLAYER_GRAVITY 		; Velocidad positiva
    call entity_physics_add_velocity
    
.limit_fall_speed:
	; Limitar velocidad máxima de caída
    ld de, component_physics 
    call entity_physics_get_velocity
    ld a, c 		; C = VY actual
    cp PLAYER_MAX_FALL_SPEED 
    jr c, .apply_movement	; Si VY < MAX, continuar
    
    ; Limitar VY manualmente
    ld de, component_physics
    inc de
    inc de
    inc de
    ld a, PLAYER_MAX_FALL_SPEED
    ld [de], a
    
.apply_movement:
	; Aplicar velocidad a posición: pos += vel
    ld de, component_physics 
    call entity_physics_apply_velocity 
    call player_check_ground 
    call player_update_sprite_position 
    ret


;;================================================
;; player_check_ground 
;; Detiene al jugador cuando toca el suelo 
;; 
;; Si Y >= GROUND_Y:
;;   - Fija Y = GROUND_Y (no atraviesa el suelo)
;;   - Establece VY = 0 (detiene caída)
;;
;; MODIFICA: A, BC, DE 
player_check_ground::
	ld de, component_physics 
	call entity_physics_get_position ; Y = C 

	ld a, c 
	cp GROUND_Y
	ret c ; SI Y < GROUND_Y, no tocal el suelo 

	; Fijar en el suelo 
	ld c, GROUND_Y 
	ld de, component_physics 
	call entity_physics_set_position

	; Detener caída 
	ld de, component_physics 
	call entity_physics_get_velocity 
	ld c, 0 	; VY = 0 
	ld de, component_physics 
	call entity_physics_set_velocity

	ret


;;=============================================
;; player_update_sprite_position 
;; Actualiza sprites con la posición del componente de física 
;;
;; Gestiona orientación:
;;   - Derecha: sprite2 está 8px a la derecha de sprite1
;;   - Izquierda: sprite2 está 8px a la izquierda de sprite1
;;
;; MOFIFICA: A, BC, DE, HL
player_update_sprite_position::
	ld de, component_physics 
	call entity_physics_get_position 

	; Convertir a coordenadas de pantalla: X_display = X_physics + 8   Y_display = Y_physics + 16 
	; calcular Y_display = Y + 16 en A
	ld a, c 
	add 16 
	ld c, a 

	; calcular X_display = X + 8 en D
	ld a, b
	add 8 
	ld d, a

	; Verificar orientación
	ld a, [player_orientation] 
	cp 01 
	jr z, .facing_left 

.facing_right:
	; ORIENTACIÓN DERECHA
	; Sprite 1 (cuerpo) en posición base
	ld hl, component_sprite + SPRITE_OFFSET_Y
	ld [hl], c 	; byte 0 = Y
	inc hl 
	ld [hl], d 	; byte 1 = X 

	; Sprite 2 (cerbatana) 8 píxeles a la derecha
	ld a, d
	add 8 
	ld d, a 	; D = X_display_right

	ld hl, component_sprite + SPRITE_OFFSET_Y + SPRITE_SIZE
	ld [hl], c 
	inc hl 
	ld [hl], d

	ret

.facing_left:
	; ORIENTACIÓN IZQUIERDA
	; Sprite 2 (cerbatana) 8 píxeles a la izquierda
	ld a, d
	sub 8 
	ld e, a 
	
	; Sprite 1 (cuerpo) en posición base
	ld hl, component_sprite + SPRITE_OFFSET_Y
	ld [hl], c 	; byte 0 = Y
	inc hl 
	ld [hl], d 	; X
	
	; Sprite 2 (cerbatana) en X - 8
	ld hl, component_sprite + SPRITE_OFFSET_Y + SPRITE_SIZE
	ld [hl], c 	; byte 0 = Y
	inc hl 
	ld [hl], e 	; byte 1 = X (8 píxeles a la izquierda)

	ret


;;===================================================
;; Alterna entre sprite parado y caminando
;;
;; MODIFICA: A
choose_stand_or_walk:: 
	ld a, [player_stand_or_walk]
	cp 00 
	jr z, player_set_stand_sprite 	; Si está parado (player_stand_or_walk = 0), cambiar a caminar
	jr nz, player_set_walk_sprite 	; Si está caminando (player_stand_or_walk = 1), cambiar a parado
	ret


;;=============================================
;; player_set_walk_sprite
;; Cambia el tile del sprite del jugador a caminar
;; 
;; MODIFICA: A, HL
player_set_walk_sprite::
    ld hl, component_sprite + SPRITE_OFFSET_TILE
    ld [hl], $0A  ; Tile de Player_walk
    ld a, 00 
    ld [player_stand_or_walk], a
    ret

;;=============================================
;; player_set_stand_sprite
;; Cambia el tile del sprite del jugador a parado
;;
;; MODIFICA: A, HL
player_set_stand_sprite::
    ld hl, component_sprite + SPRITE_OFFSET_TILE
    ld [hl], $06  ; Tile de Player_stand 
    ld a, 01
    ld [player_stand_or_walk], a
    ret