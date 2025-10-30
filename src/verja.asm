INCLUDE "consts.inc"


SECTION "Verja Code", ROM0


verja_sprites:
	DB $78, $08, $16, %10000000
	DB $78, $A0, $16, %10100000	; Volteo  vertical




;;============================================================
;; init_player 
;; Inicialización completa del jugador 
;;
;; MODIFICA: A, BC, DE, HL
init_verja::
	call init_verja_tiles
	call init_verja_entity
	call init_verja_physics
	ret


;;============================================================
;; init_verja_tiles
;; Carga los gráficos del jugador en VRAM

;; MODIFICA: A, BC, DE, HL
init_verja_tiles::
	;; Cargar Verja en tiles $0A-$0B
	ld hl, Verja
	ld de, VRAM_TILE_DATA_START + ($16 * VRAM_TILE_SIZE)
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
	push hl
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

	pop hl

	ret



;;=================================================
;; init_verja_physics
;; Inicializa las físicas de las dos verjas
;; MODIFICA: A, BC, DE, HL
init_verja_physics::
    ; ----- Primera verja -----
    ld b, $78                  ; Y inicial
    ld c, $08                  ; X inicial

    ld d, h 
    ld e, l
    call .init_one_verja

    ; ----- Segunda verja -----
    ld h, d 
    ld l, e
    ld de, $04               ; Cada entidad ocupa 4 bytes
    add hl, de
    ld b, $78
    ld c, $A0
    call .init_one_verja

    ret

;;-------------------------------------------------
;; .init_one_verja
;; INPUT: 
;;   HL = dirección del componente INFO
;;   B = Y inicial
;;   C = X inicial
;;-------------------------------------------------
.init_one_verja:
    ; === INFO ===
    ld a, BYTE_ACTIVE
    ld [hl+], a            ; Active = 1
    ld a, TYPE_VERJA
    ld [hl+], a            ; Type = 5

    ; === SPRITE ===
    ld h, CMP_SPRITES_H
    dec l
    dec l                  ; HL = $C100 (posición)
    ld a, b
    ld [hl+], a            ; Y inicial
    ld a, c
    ld [hl+], a            ; X inicial

    ; === SIZE ===
    ld a, h
    add 4
    ld h, a
    ld a, VERJA_HEIGHT
    ld [hl+], a
    ld a, VERJA_WIDTH
    ld [hl], a
    ret
