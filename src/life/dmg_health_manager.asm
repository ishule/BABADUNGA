include "consts.inc"

SECTION "Game Stats",WRAM0
player_health: ds 1 ;; Bit 7 = Muerto

boss_health: ds 1 ;; Bit 7 = Muerto
player_dmg: ds 1

SECTION "DmgHealthManager",ROM0


;;;; b, nueva vida a poner
;;;; hl -> entity start address
change_entity_dmg::
	ld h,CMP_PHYSICS_P_H
	inc l
	inc l
	inc l
	ld [hl],b
	ret


;;;; b, nueva vida a poner
;;;; hl -> entity start address
;;;; d -> group size
change_entity_group_dmg::
	push hl
	call change_entity_dmg
	pop hl
	dec d
	cp 0
	jr nz,change_entity_group_dmg
	ret


change_player_dmg::

	ld a,PLAYER_BODY_ENTITY_ID
	call man_entity_locate_v2
	ld a,[player_dmg]
	ld d,PLAYER_SPRITES_SIZE
	call change_entity_group_dmg
	ret


draw_player_health::

	ret


; ==========================================================
; draw_hearts
; Draws player health (up to 6 halves = 3 full hearts)
; Fills remaining slots with EMPTY_HEART_TILE.
; Assumes hearts are drawn at $9A01 (top) and $9A21 (bottom).
; MODIFICA: AF, BC, DE, HL
; ==========================================================
draw_hearts::
    ld a, [player_health]   ; C = current health (0-6)
    ld c,a
    ld b, 0                 ; B = loop counter (0 to 5, representing half-heart slot index)
    ld hl, $9A01            ; Start address top row
    ld de, $9A01 + 32       ; Start address bottom row ($9A21)

.loop:
    push bc                 ; Save loop counter B and current health C

    ; --- Compare current slot index B with health C ---
    ld a, b                 ; A = slot index (0-5)
    cp c                    ; Compare with current health
    jr c, .draw_filled      ; If B < C (slot index < health), draw a filled half

.draw_empty:
    ; Health is less than or equal to this slot index, draw empty
    ld a,2 ; TILE VACIO
    ld [hl+], a             ; Write empty top, advance HL to next slot's top
    ld [de], a              ; Write empty bottom
    inc de                  ; Advance DE to next slot's bottom
    jr .next_iter

.draw_filled:
    ; Health is greater than this slot index, draw a filled half-heart tile
    ; Check if B is even (left half) or odd (right half)
    ld a, b
    rra                     ; Rotate right, carry = original bit 0
    jr nc, .draw_left_half  ; If bit 0 was 0 (B=0, 2, 4), it's a left half

.draw_right_half:
    ; Slot index B is odd (1, 3, 5) -> Draw right half
    ld a, $14               ; Tile ID for top-right
    ld [hl+], a             ; Write top-right, advance HL
    ld a, $15               ; Tile ID for bottom-right
    ld [de], a              ; Write bottom-right
    inc de                  ; Advance DE
    jr .next_iter

.draw_left_half:
    ; Slot index B is even (0, 2, 4) -> Draw left half
    ld a, $12               ; Tile ID for top-left
    ld [hl+], a             ; Write top-left, advance HL
    ld a, $13               ; Tile ID for bottom-left
    ld [de], a              ; Write bottom-left
    inc de                  ; Advance DE
    ; jr .next_iter (falls through)

.next_iter:
    pop bc                  ; Restore loop counter B and original health C
    inc b                   ; Increment slot index
    ld a, b
    cp 6    ; Have we processed all 6 slots?
    jr c, .loop             ; If B < 6, loop again

    ret