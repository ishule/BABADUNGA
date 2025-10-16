INCLUDE "consts.inc"

SECTION "Blink Effect Data", WRAM0
blink_counter:: DS 1    ; Contador de frames para parpadeo
blink_entity:: DS 1     ; ID de entidad que parpadea


SECTION "Entity Draw Code", ROM0
; En una sección de WRAM, alineada a 256 bytes
DEF HRAM_ADDRESS equ $FF80
DmaCopyFunc:
ld a, CMP_SPRITES_H
ldh [$FF46], a
ld c, NUM_ENTITIES
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




sys_blink_update::
    ld a, [blink_counter]
    or a
    ret z               ; No hay parpadeo activo
    
    dec a
    ld [blink_counter], a
    
    ; Alternar cada 4 frames
    and %00000100
    jr z, .hide
    
.show:
    ; Mostrar sprite
    ld a, [blink_entity]
    call _show_sprite
    ret
    
.hide:
    ; Ocultar sprite
    ld a, [blink_entity]
    call _hide_sprite
    ret

_hide_sprite:
    ; A = ID de entidad
    add a
    add a               ; A = ID * 4
    ld h, $FE
    ld l, a
    ld [hl], $00        ; PosY = 0
    ret

_show_sprite:
    ; A = ID de entidad
    push af
    add a
    add a               ; A = ID * 4
    ld h, $FE
    ld l, a             ; HL = sprite en OAM
    
    pop af
    push hl
    call man_entity_locate_v2
    inc h               ; Ir a componente sprite ($C1xx)
    ld a, [hl]          ; Leer PosY original
    pop hl
    ld [hl], a          ; Restaurar PosY
    ret
