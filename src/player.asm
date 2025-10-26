INCLUDE "consts.inc"

SECTION "Player Variables", WRAM0 
player_orientation:: DS 1	; 0 = derecha, 1 = izquierda
player_stand_or_walk:: DS 1 ; 0 = parado, 1 = caminando
shot_cooldown:: ds 1
can_shot_flag:: ds 1

SECTION "Player Code", ROM0


player_sprites:
	DB $00, $00, $0A, %00000000	;; Izquierdo, personaje
	DB $00, $00, $0C, %00000000	;; Derecho, cerbatana


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
;; Tiles cargados:
;;		$0C-$0D: Player_stand
;;		$0E-$0F: Player_blowgun
;;		$10-$11: Player_walk 
;;      $12: Player_bullet
;;	    $13: Player_life 
;; 		$18: Player_lookup
;; MODIFICA: A, BC, DE, HL
init_player_tiles::
	call wait_vblank

	;; Cargar Player_stand en tiles $0A-$0B
	ld hl, Player_stand
	ld de, VRAM_TILE_DATA_START + ($0A * VRAM_TILE_SIZE)
	ld b, 2 * VRAM_TILE_SIZE	; 2 tiles de 16 bytes cada uno
	call memcpy_256

	;; Cargar Player_blowgun en tiles $0C-$0D
	ld hl, Player_blowgun
	ld de, VRAM_TILE_DATA_START + ($0C * VRAM_TILE_SIZE)
	ld b, 2 * VRAM_TILE_SIZE
	call memcpy_256

	;; Cargar Player_walk en tiles $0E-$0F 
	ld hl, Player_walk
	ld de, VRAM_TILE_DATA_START + ($0E * VRAM_TILE_SIZE)
	ld b, 2 * VRAM_TILE_SIZE
	call memcpy_256
	;; Cargar Player_bullet en tile $10
	ld hl,bullet_0_h
	ld de,VRAM_TILE_DATA_START + ($10*VRAM_TILE_SIZE)
	ld b,VRAM_TILE_SIZE
	call memcpy_256
	;; Cargar Player_life en tile $12
	call wait_vblank
	ld hl,Player_life
	ld de,VRAM_TILE_DATA_START + ($12*VRAM_TILE_SIZE)
	ld b,4*VRAM_TILE_SIZE
	call memcpy_256

	;; Cargar Player_lookup en tile $18
	call wait_vblank
	ld hl,player_look_up
	ld de,VRAM_TILE_DATA_START + ($18*VRAM_TILE_SIZE)
	ld b,4*VRAM_TILE_SIZE
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

	; Alocar primer sprite
	call man_entity_alloc
	inc h
	;; HL = $C100 (primera posición OAM)
	ld d, h 
	ld e, l 
	ld hl, player_sprites
	ld b, SPRITE_SIZE	; 4 bytes por sprite
	call memcpy_256

	; Alocar segundo sprite
	call man_entity_alloc
	inc h
	;; HL = $C104 (segunda posición OAM)
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
;; Establece:l
;; 		- Posición inicial
;; 		- Velocidad inicial: 0, 0 
;; 		- Estado de animación: parado 
;;
;; MODIFICA: A, BC, DE
player_init_physics:: 

	ld a, $00
	call man_entity_locate_v2

	push hl

	;; Info Player
	ld a, BYTE_ACTIVE
	ld [hl+], a 		; Active = 1

	ld a, TYPE_PLAYER
	ld [hl+], a 	 	; Type = 0

	ld a, [hl]                     ; carga el byte actual
    or FLAG_CAN_TAKE_DAMAGE
    ld [hl+], a                     ; guarda el nuevo valor 

    ld a, $02 
    ld [hl+], a 	; Número de sprites

    ld a, BYTE_NON_ACTIVE
	ld [hl+], a 		; Active = 0

	ld a, TYPE_PLAYER
	ld [hl+], a 	 	; Type = 0

	ld a, [hl]                     ; carga el byte actual
    or FLAG_CAN_TAKE_DAMAGE
    ld [hl+], a                     ; guarda el nuevo valor 

    ld a, $02 
    ld [hl], a 	; Número de sprites


	pop hl 
	push hl

	ld b, GROUND_Y				; Y inicial
	ld c, PLAYER_INITIAL_POS_X 	; X inicial

	; Guardamos la posicion incial en C000
   	ld d, $02
   	call change_entity_group_pos

	;; ASIGNAR WIDTH Y HEIGHT
	ld b, $02
	pop hl
	ld h, CMP_COLLISIONS_H
	inc l
	inc l
	.loop:
   	ld a, PLAYER_HEIGHT 
	ld [hl+], a 

	ld a, PLAYER_WIDTH 
	ld [hl+], a
	inc l
	inc l 
	dec b
	jr nz, .loop

   	

	ret 
 
