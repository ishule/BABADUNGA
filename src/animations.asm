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
    ; Poner la paleta BGP en negro (todo negro)
    ld a, %11111111     ; Todos los colores a negro
    ld [rBGP], a        ; Background palette
    ld [rOBP0], a       ; Object palette 0 (opcional, si quieres sprites negros también)
    ld [rOBP1], a       ; Object palette 1 (opcional)
    
    call sys_sound_player_dies
    ; Congelar el juego durante unos segundos (por ejemplo, 3 segundos)
    ; A 60 FPS, 3 segundos = 180 frames
    ld b, 180           ; Ajusta este valor: 60 frames = 1 segundo

.freeze_loop:
    call wait_vblank
    dec b
    jr nz, .freeze_loop
    
    
    ret
