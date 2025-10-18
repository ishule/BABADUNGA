SECTION "Snake", ROM0
 include "consts.inc"
; Start of tile array.
;; Snake Idle
SnakeIdle::
DB $00,$00,$00,$00,$00,$00,$01,$01
DB $01,$01,$01,$01,$01,$01,$01,$01
DB $02,$03,$0C,$0F,$F0,$FF,$00,$FC
DB $00,$FC,$00,$FF,$00,$FF,$FF,$FF
DB $00,$00,$7E,$7E,$85,$FF,$01,$FF
DB $0F,$FF,$02,$FE,$1E,$7E,$10,$30
DB $10,$30,$10,$30,$10,$F0,$30,$70
DB $20,$E0,$40,$C0,$80,$80,$00,$00
;; Snake Movement
SnakeMovement::
DB $00,$00,$00,$00,$01,$01,$02,$03
DB $02,$03,$02,$03,$02,$03,$01,$01
DB $02,$03,$0C,$0F,$F0,$FF,$00,$FC
DB $00,$FC,$00,$FF,$00,$FF,$FF,$FF
DB $00,$00,$FC,$FC,$0A,$FE,$02,$FE
DB $1E,$FE,$04,$FC,$1C,$7C,$10,$30
DB $10,$30,$10,$30,$10,$F0,$10,$70
DB $10,$F0,$10,$F0,$20,$E0,$C0,$C0

;; Snake Tail
SnakeTail::
DB $00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$7F,$7F
DB $80,$9F,$80,$9F,$7F,$7F,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$0F,$0F,$F0,$FF,$00,$F9
DB $00,$C1,$00,$FF,$0F,$FF,$F0,$F0

init_snake::
	call init_snake_tiles
	call init_snake_entity
	call snake_init_physics
	ret

init_snake_tiles::
	call wait_vblank
	
	; Primer cuarto: tiles $10-$13 (4 tiles = 64 bytes)
	ld hl, SnakeIdle
	ld de, VRAM_TILE_DATA_START + ($10 * VRAM_TILE_SIZE)
	ld b, 4 * VRAM_TILE_SIZE
	call memcpy_256

	call wait_vblank
	; Primera mitad: tiles $14-$17 (4 tiles = 64 bytes)
	ld hl, SnakeMovement
	ld de, VRAM_TILE_DATA_START + ($14 * VRAM_TILE_SIZE)
	ld b, 4 * VRAM_TILE_SIZE
	call memcpy_256
	
	call wait_vblank
	; Segunda mitad: tiles $18-$1B (4 tiles = 64 bytes)
	ld hl, SnakeTail 
	ld de, VRAM_TILE_DATA_START + ($18 * VRAM_TILE_SIZE)
	ld b, 4 * VRAM_TILE_SIZE
	call memcpy_256

	
	ret


snake_sprites:: ;; Cuando se mueva habrá que cambiar los 2 sprites idle a movement
    DB $00, $00, $18, SPRITE_ATTR_NO_FLIP   ; Sprite 0: Columna 1, Fila 1
    DB $00, $00, $1A, SPRITE_ATTR_NO_FLIP   ; Sprite 1: Columna 2, Fila 2
    DB $00, $00, $10, SPRITE_ATTR_NO_FLIP   ; Sprite 2: Columna 1, Fila 3 
    DB $00, $00, $12, SPRITE_ATTR_NO_FLIP   ; Sprite 3: Columna 1, Fila 4

snake_sprites_turned::
    DB $00, $00, $12, SPRITE_ATTR_FLIP_X   ; Sprite 0: Columna 1, Fila 1
    DB $00, $00, $10, SPRITE_ATTR_FLIP_X   ; Sprite 1: Columna 2, Fila 2
    DB $00, $00, $1A, SPRITE_ATTR_FLIP_X   ; Sprite 2: Columna 1, Fila 3 
    DB $00, $00, $18, SPRITE_ATTR_FLIP_X   ; Sprite 3: Columna 1, Fila 4
;;============================================================
;; init_snake_entity
;; Crea las entidades de sprites del snake en OAM
;;
;;
;; MODIFICA: A, BC, DE, HL
init_snake_entity::

	; Alocar sprite 0
	call man_entity_alloc
	inc h
	ld d, h 
	ld e, l 
	ld hl, snake_sprites
	ld b, SPRITE_SIZE
	call memcpy_256
	
	; Alocar sprite 1
	call man_entity_alloc
	inc h
	ld d, h 
	ld e, l 
	ld hl, snake_sprites + 4
	ld b, SPRITE_SIZE
	call memcpy_256
	
	; Alocar sprite 2
	call man_entity_alloc
	inc h
	ld d, h 
	ld e, l 
	ld hl, snake_sprites + 8
	ld b, SPRITE_SIZE
	call memcpy_256
	
	; Alocar sprite 3
	call man_entity_alloc
	inc h
	ld d, h 
	ld e, l 
	ld hl, snake_sprites + 12
	ld b, SPRITE_SIZE
	call memcpy_256
	
	call wait_vblank
	call man_entity_draw
	ret


snake_init_physics:: 
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2 
	push hl
	;;SNAKE INFO
	ld b,SNAKE_SPRITES_SIZE
	.info_loop:
		ld a,BYTE_ACTIVE
		ld [hl+],a

		ld a,TYPE_BOSS
		ld [hl+],a

		ld a,[hl]
		or FLAG_CAN_TAKE_DAMAGE | FLAG_CAN_DEAL_DAMAGE
		ld [hl+], a                     ; guarda el nuevo valor
	    inc l 
	    dec b 
	    jr nz, .info_loop 
	pop hl
	push hl

	ld b, GROUND_Y - 4		; Y = suelo menos altura del gorila (32 píxeles)
	ld c, $80				; X = 60 (bien visible, no en borde)
	ld d,SNAKE_SPRITES_SIZE ;; MAGIC (Ancho)
	call change_entity_group_pos

	;; ASIGNAR WIDTH Y HEIGHT
	pop hl
	ld h, CMP_PHYSICS_P_H
	inc l
	inc l

    ld d, SNAKE_SPRITES_SIZE ;; <-- ¡¡AÑADE ESTA LÍNEA!!

.loop:
    ld a, SNAKE_HEIGHT
	ld [hl+], a
	ld a, SNAKE_WIDTH 
	ld [hl+], a
	inc l
	inc l
	dec d
	jr nz, .loop
	
	ret



;============================================================
; snake_update_sprites (VERSIÓN CORREGIDA PARA ECS)
; Copia los 4 sprites (16 bytes) desde la ROM a las ubicaciones
; correctas y no contiguas de los componentes de sprite en WRAM.
;
; INPUT:
;   HL: Dirección de origen de los datos (ej. snake_sprites_turned)
; MODIFICA: A, BC, DE, HL
snake_update_sprites::
    push bc
    push de

    ld c, ENEMY_START_ENTITY_ID ; C = Contador de ID de entidad (empezamos en la entidad 1)
    ld b, 4 ; B = Contador de sprites a procesar

.sprite_loop:
    ; --- 1. Calcular la dirección de DESTINO en WRAM ---
    push hl ; Guardamos el puntero de origen (ROM) temporalmente

    ld a, c ; Cargamos el ID de la entidad actual (1, 2, 3 o 4)
    call man_entity_locate_v2 ; HL apunta a la info ($C0xx)
    ld h, CMP_SPRITES_H       ; Cambiamos a la sección de sprites (HL = $C1xx)
    
    ; Ahora HL es el puntero de destino. Lo movemos a DE.
    ld d, h
    ld e, l

    pop hl ; Recuperamos el puntero de origen (ROM)

    ; --- 2. Copiar 4 bytes del sprite actual ---
    ; HL = Origen (ROM), DE = Destino (WRAM)

    inc de
    inc hl
    inc de
    inc hl
    ld a, [hl+] ; Copia Tile
    ld [de], a
    inc de
    ld a, [hl+] ; Copia Tile
    ld [de], a
    
    ; El puntero HL ya ha avanzado 4 bytes, listo para el siguiente sprite
    
    ; --- 3. Preparar siguiente iteración ---
    inc c   ; Siguiente ID de entidad
    dec b
    jr nz, .sprite_loop ; Repetir si quedan sprites

    pop de
    pop bc
    ret
    
;============================================================
; snake_flip
; Actualiza los sprites para que la serpiente mire a la izquierda.
snake_flip::
    ld hl, snake_sprites_turned
    jp snake_update_sprites

;============================================================
; snake_unflip
; Actualiza los sprites para que la serpiente mire a la derecha.
snake_unflip::
    ld hl, snake_sprites
    jp snake_update_sprites