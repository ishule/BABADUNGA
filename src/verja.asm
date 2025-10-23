INCLUDE "consts.inc"


SECTION "Verja Code", ROM0


verja_sprites:
	DB $78, $08, $14, %00000000
	DB $78, $A0, $14, %00100000	; Volteo  vertical



;;============================================================
;; init_player 
;; Inicialización completa del jugador 
;;
;; MODIFICA: A, BC, DE, HL
init_verja::
	call init_verja_tiles
	call init_verja_entity
	ret


;;============================================================
;; init_verja_tiles
;; Carga los gráficos del jugador en VRAM

;; MODIFICA: A, BC, DE, HL
init_verja_tiles::
	call wait_vblank

	;; Cargar Verja en tiles $0A-$0B
	ld hl, Verja
	ld de, VRAM_TILE_DATA_START + ($14 * VRAM_TILE_SIZE)
	ld b, 2 * VRAM_TILE_SIZE	; 2 tiles de 16 bytes cada uno
	call memcpy_256

	
	ret

;;============================================================
;; init_verja_entity
;; Crea las entidades de sprites del jugador en OAM
;;
;; Reserva 2 sprites:
;;		- Sprite 1 ($C000): Cuerpo del jugador
;;		- Sprite 2 ($C004): Cerbatana
;;
;; MODIFICA: A, BC, DE, HL
init_verja_entity::

	; Alocar primer sprite
	call man_entity_alloc
	inc h
	;; HL = $C100 (primera posición OAM)
	ld d, h 
	ld e, l 
	ld hl, verja_sprites
	ld b, SPRITE_SIZE	; 4 bytes por sprite
	call memcpy_256

	; Alocar segundo sprite
	call man_entity_alloc
	inc h
	;; HL = $C104 (segunda posición OAM)
	ld d, h 
	ld e, l 
	ld hl, verja_sprites + 4
	ld b, SPRITE_SIZE
	call memcpy_256

	call wait_vblank
	call man_entity_draw	; Copiar sprites a OAM

	ret


