SECTION "Screen Effects", ROM0
include "consts.inc"
DEF WIPE_DELAY_FRAMES equ 1 ; Cuántos frames esperar entre pasos

; =============================================
; wipe_out_right
; Cubre la pantalla columna por columna de izq -> der
; escribiendo tiles negros en el tilemap
; MODIFIES: AF, BC, DE, HL
; =============================================
wipe_out_right::
    ld b, 0             ; Columna inicial (0-19)
    
.next_column:
    push bc
    
    ; Esperar 2-3 VBlanks por columna para hacerlo más lento
    ld a, 2             ; Número de frames a esperar
.wait_frames:
    push af
    call wait_vblank
    pop af
    dec a
    jr nz, .wait_frames
    
    ; Ahora dibujamos TODA la columna
    ld c, 0
    
.draw_tile:
    ; Calcular dirección en tilemap: $9800 + (fila * 32) + columna
    ld a, c             ; A = fila
    ld h, 0
    ld l, a
    ; Multiplicar fila por 32
    add hl, hl          ; * 2
    add hl, hl          ; * 4
    add hl, hl          ; * 8
    add hl, hl          ; * 16
    add hl, hl          ; * 32
    
    ; Añadir columna
    ld a, b             ; A = columna
    ld e, a
    ld d, 0
    add hl, de
    
    ; Añadir base del tilemap
    ld de, $9800
    add hl, de          ; HL = dirección final en tilemap
    
    ; Escribir tile negro (tile 2) - SIN wait_vblank aquí
    ld a, 2
    ld [hl], a
    
    inc c               ; Siguiente fila
    ld a, c
    cp 18               ; ¿Hemos dibujado toda la columna?
    jr c, .draw_tile
    
    pop bc
    inc b               ; Siguiente columna
    ld a, b
    cp 20               ; ¿Hemos cubierto toda la pantalla? (20 columnas)
    jr c, .next_column
    
    ret

player_dies_animation::

    ; --- 1. Set Player Sprite Priority (Above Background) ---
    ld a, PLAYER_BODY_ENTITY_ID
    ld b, PLAYER_SPRITES_SIZE
    ld c,20
    call die_animation
    call restore_die_animation

    ret
; b -> Nº Sprites
; hl -> map
boss_dies_animation::
    ld a,ENEMY_START_ENTITY_ID
    ld c,16
    push hl
    call die_animation
    

    ;Restore game
    call turn_screen_off
    pop hl
    call draw_map

    call restore_die_animation
    call turn_screen_on
    ret
;; c -> duration
;; a -> Entity Start Id
;; b -> Nº Sprites
die_animation::
    .priority_loop:
    push af
    push bc
    call man_entity_locate_v2
    ld h, CMP_SPRITES_H
    inc l
    inc l
    inc l
    res 7, [hl]                 ; 0 = Sprite Above BG
    pop bc
    pop af
    inc a
    dec b
    jr nz, .priority_loop
    push bc
    ld hl,rOBP0
    ld [hl],%00000000
    ld hl,rOBP1
    ld [hl],%00000000
    call turn_screen_off
    call fill_background_black ; <<< Call the new function
    call turn_screen_on
    call man_entity_draw
    ; --- 3. Play Sound & Wait ---
    ; call kill_boss
    call sys_sound_player_dies
    pop bc ; mantener contador c
    ; Freeze the game
.freeze_loop:
    call wait_time_vblank_24
    dec c
    jr nz, .freeze_loop

ret

restore_die_animation::
    .priority_loop:
    push af
    push bc
    call man_entity_locate_v2
    ld h, CMP_SPRITES_H
    inc l
    inc l
    inc l
    set 7, [hl]                 ; 0 = Sprite Above BG
    pop bc
    pop af
    inc a
    dec b
    jr nz, .priority_loop
    ld hl,rOBP0
    ld [hl],%11100001
    ld hl,rOBP1
    ld [hl],%01010101
ret

fill_background_black::
    ld b, 0             ; Columna inicial (0-19)
    
.next_column:
    push bc
    
    ; Esperar 2-3 VBlanks por columna para hacerlo más lento
    ld a, 1             ; Número de frames a esperar

    ; Ahora dibujamos TODA la columna
    ld c, 0
    
.draw_tile:
    ; Calcular dirección en tilemap: $9800 + (fila * 32) + columna
    ld a, c             ; A = fila
    ld h, 0
    ld l, a
    ; Multiplicar fila por 32
    add hl, hl          ; * 2
    add hl, hl          ; * 4
    add hl, hl          ; * 8
    add hl, hl          ; * 16
    add hl, hl          ; * 32
    
    ; Añadir columna
    ld a, b             ; A = columna
    ld e, a
    ld d, 0
    add hl, de
    
    ; Añadir base del tilemap
    ld de, $9800
    add hl, de          ; HL = dirección final en tilemap
    
    ; Escribir tile negro (tile 2) - SIN wait_vblank aquí
    ld a, 2
    ld [hl], a
    
    inc c               ; Siguiente fila
    ld a, c
    cp 18               ; ¿Hemos dibujado toda la columna?
    jr c, .draw_tile
    
    pop bc
    inc b               ; Siguiente columna
    ld a, b
    cp 20               ; ¿Hemos cubierto toda la pantalla? (20 columnas)
    jr c, .next_column
    
    ret

;; Abre la puerta DERECHA con animación ascendente (CORREGIDO)
open_door::
    ; 1. Find the first gate entity
    ld a, TYPE_VERJA
    call man_entity_locate_first_type
    ret c ; Exit if no gate found (Carry set)

    ; 2. Calculate the ID of the first gate sprite
    ld a, l ; Get the offset L
    srl a   ; A = L / 2
    srl a   ; A = L / 4 = ID of the first (left) gate sprite

    ; 3. Calculate the ID of the second (right) gate sprite
    inc a   ; A = ID_Left + 1 = ID_Right
    push af ; Save the ID of the right gate for later deactivation

    ; 4. Locate the second gate entity's SPRITE component
    call man_entity_locate_v2 ; HL = Address of right gate's Info ($C0xx + L')
    inc h                     ; HL = Address of right gate's Sprite ($C1xx + L')
    ld d, h                   ; Store Sprite component address in DE
    ld e, l                   ; DE now points to the Y coordinate byte

    ; --- 5. Animation Loop: Move Up 16 Pixels (1 pixel per frame) ---
    ld c, 16                  ; C = Number of pixels to move up
.anim_loop:
    ; *** CORRECCIÓN: Esperar UN VBLANK por cada píxel ***
    call wait_time_vblank_12
    ; Read current Y, decrement, write back
    ld a, [de]                ; Read current Y from Sprite Component
    dec a                     ; Move up 1 pixel
    ld [de], a                ; Write new Y back

    push bc
    call man_entity_draw
    pop bc
    ; *** DIBUJAR INMEDIATAMENTE PARA VER EL CAMBIO (Opcional pero recomendado) ***
    ; Si tu man_entity_draw es rápido, puedes llamarlo aquí para actualizar OAM
    ; Si no, el cambio se verá en el siguiente wait_vblank del bucle principal
    ; call man_entity_draw ; (Opcional)
    call sys_sound_door_opening_scrape
    dec c
    jr nz, .anim_loop         ; Loop until moved 16 pixels

    ; --- 6. Deactivate the entity AFTER animation ---
    pop af                    ; Restore the ID of the right gate into A
    call man_entity_locate_v2 ; HL = Address of right gate's Info ($C0xx + L')
    xor a                     ; A = 0 (Inactive value)
    ld [hl], a                ; Set ACTIVE flag to 0
    call sys_sound_door_opened_clink
    ret

    ; =============================================
; shake_screen
; Plays rumble sound and shakes the screen briefly.
; MODIFIES: AF, B, C, HL (uses rSCY, rSCX)
; =============================================
shake_screen::

    ; --- 2. Screen Shake Loop ---
    ld c, 8 ; C = Loop counter . DURACIÓN DEL TERREMOTO

.shake_loop:
    push bc              ; Save loop counter

    ; Wait for next frame
    call wait_time_vblank_24

    ; --- Calculate Shake Offset ---
    ; Simple alternating offset: +Amount, -Amount, +Amount, -Amount...
    ; We can use the frame counter (C) parity (odd/even)
    ld a, c
    and 1                ; A = 0 if C is even, A = 1 if C is odd
    jr z, .positive_offset

.negative_offset:
    ld a, -1  ; Offset = -1 or -2
    jr .apply_offset

.positive_offset:
    ld a, 1   ; Offset = +1 or +2

.apply_offset:
    ld [$FF42], a         ; Apply vertical scroll offset
    ld [$FF43], a         ; Apply horizontal scroll offset (can use different value if desired)

    pop bc               ; Restore loop counter
    dec c
    jr nz, .shake_loop   ; Loop until C = 0

    ; --- 3. Restore Scroll Position ---
    xor a                ; A = 0
    ld [$FF42], a         ; Reset vertical scroll
    ld [$FF43], a         ; Reset horizontal scroll

    ret