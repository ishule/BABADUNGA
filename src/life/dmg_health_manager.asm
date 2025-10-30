include "consts.inc"

SECTION "Game Stats",WRAM0
player_health: ds 1 
boss_player_dead: ds 1 ; Bit 0 a 1 boss muerto, bit 1 a 1 player muerto
player_bullet: ds 1 ; 0 = preset0, 1 preset1, 2 preset2
player_dmg: ds 1
player_total_health: ds 1

SECTION "DmgHealthManager",ROM0


; ==========================================================
; draw_hearts
; Draws half-hearts sequentially (L, R, L, R...) up to player_health.
; Fills remaining slots (up to 6) with EMPTY_HEART_TILE ($02).
; Assumes hearts are drawn at $9A01 (top) and $9A21 (bottom).
; MODIFICA: AF, BC, DE, HL
; ==========================================================
draw_hearts::
    ld a, [player_health]   ; C = current health (number of half-hearts, 0-6)
    ld c,a
    ld b, 0                 ; B = loop counter / slot index (0 to 5)
    ld hl, $9A01            ; Start address top row
    ld de, $9A01 + 32       ; Start address bottom row ($9A21)

.loop:
    push bc                 ; Save slot index B and current health C

    ; --- Compare current slot index B with health C ---
    ld a, b                 ; A = slot index (0-5)
    cp c                    ; Compare with current health
    jr c, .draw_filled      ; If B < C (slot index < health), draw this half

.draw_empty:
    ; Health is less than or equal to this slot index, draw empty
    ld a, $02               ; <<< TILE VACIO
    ld [hl], a              ; Write empty top
    ld [de], a              ; Write empty bottom
    jr .next_iter_pointers  ; Skip drawing filled half

.draw_filled:
    ; Health is greater than this slot index, draw the appropriate half-heart tile
    ; Check if B is even (left half) or odd (right half)
    ld a, b
    rra                     ; Rotate right, carry = original bit 0
    jr nc, .draw_left_half  ; If bit 0 was 0 (B=0, 2, 4), it's a left half

.draw_right_half:
    ; Slot index B is odd (1, 3, 5) -> Draw right half
    ld a, $14               ; Tile ID for top-right
    ld [hl], a              ; Write top-right
    ld a, $15               ; Tile ID for bottom-right
    ld [de], a              ; Write bottom-right
    jr .next_iter_pointers

.draw_left_half:
    ; Slot index B is even (0, 2, 4) -> Draw left half
    ld a, $12               ; Tile ID for top-left
    ld [hl], a              ; Write top-left
    ld a, $13               ; Tile ID for bottom-left
    ld [de], a              ; Write bottom-left
    ; Fall through to pointer increment

.next_iter_pointers:
    inc hl                  ; Advance top row pointer to next slot
    inc de                  ; Advance bottom row pointer to next slot

    pop bc                  ; Restore slot index B and original health C
    inc b                   ; Increment slot index
    ld a, b
    cp 12    ; Have we processed all 6 slots? (MAX_PLAYER_HEALTH should be 6)
    jr c, .loop             ; If B < 6, loop again

    ret