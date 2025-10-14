INCLUDE "consts.inc"

SECTION "Entity Draw Code", ROM0
; En una sección de WRAM, alineada a 256 bytes
DEF HRAM_ADDRESS equ $FF80
DmaCopyFunc:
ld a, $C0 ;;Byte alto
ldh [$FF46], a
ld c, 40
.wait_copy
dec c
jr nz, .wait_copy
ret


DmaCopyFunc_End:


def DMA_FUNC_SIZE equ (DmaCopyFunc_End - DmaCopyFunc)
RSSET HRAM_ADDRESS
DEF HRAM_DMA_FUNC rb DMA_FUNC_SIZE

InitDmaCopy:
ld hl, HRAM_DMA_FUNC
ld de, DmaCopyFunc
ld c, DMA_FUNC_SIZE
.func_copy
ld a, [de]
ld [hli], a
inc de
dec c
jr nz, .func_copy
ret
man_entity_draw:
jp HRAM_DMA_FUNC
;; Copia los datos del sprite de la entidad a la memoria OAM
;; INPUT:
;;	HL: apunta al sprite de la entidad (component_sprite)
;; 	DE: apunta al inicio de OAM ($FE00)
;; 	A: índice de la siguiente entidad libre
;; 	B: cantidad de bytes a copiar (igual al valor de A en este caso)
man_entity_draw1::
	ld hl, component_sprite
	ld de, OAM_START
	ld a, [next_free_entity]
	ld b, a 
	call memcpy_256
	ret