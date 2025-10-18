INCLUDE "hardware.inc"
   rev_Check_hardware_inc 4.0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Constantes

DEF TEMPO = 8              ; Reducido para que las notas sean más rápidas
DEF SH = $FF              ; Silencio = 0 (no $FF)

DEF TAM_CHIP_SONIDO = 23  ; Tamaño correcto del área de registros de sonido

SECTION "SYS_SOUND", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inicializa el sistema de sonido
sys_sound_init::
    ; Limpia todos los registros de sonido
    ld hl, rNR10
    xor a
    ld b, TAM_CHIP_SONIDO
.loop
    ld [hl+], a
    dec b
    jr nz, .loop

    ; Configura volúmenes máximos
    ld a, $FF
    ldh [rNR50], a
    ldh [rNR51], a

    ; Activa el sistema de sonido
    ld a, %10000000
    ldh [rNR52], a
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Efectos de sonido
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sys_sound_tira_salto::
    ld hl, .data
    ld de, rNR10
    ld b, 5
    jr _reproducir_efecto
.data
    DB $1E, $82, $F3, $73, $87

sys_sound_tira_explosion::
    ld hl, .data
    ld de, rNR41
    ld b, 4
    jr _reproducir_efecto
.data
    DB %00001111, %11110011, %01010011, %11000000

sys_sound_mata_cosas::
    ld hl, .data
    ld de, rNR10
    ld b, 5
    jr _reproducir_efecto
.data
    DB %00010001, %10000010, %11110010, $33, %11000111

sys_sound_recoge_cosas::
    ld hl, .data
    ld de, rNR10
    ld b, 5
    jr _reproducir_efecto
.data
    DB %00000011, %10001000, %01110101, $CD, %10000111

_reproducir_efecto:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, _reproducir_efecto
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inicializa el sistema de música
;; ENTRADA: 
;;   HL: puntero al inicio de la canción
;;   BC: longitud de la canción en bytes
sys_sound_init_music::
    ; Guarda puntero y longitud
    ld a, l
    ld [puntero_cancion], a
    ld a, h
    ld [puntero_cancion + 1], a
    
    ld a, c
    ld [longitud_cancion], a
    ld a, b
    ld [longitud_cancion + 1], a
    
    ; Reinicia contadores
    xor a
    ld [relojMusica], a
    ld [contador_notas], a
    ld [contador_notas + 1], a
    
    ; Inicializa puntero a primera nota
    ld a, l
    ld [nota_actual], a
    ld a, h
    ld [nota_actual + 1], a
    
    ; Activa sistema de sonido
    ld a, %10000000
    ldh [rNR52], a
    
    ; Volúmenes altos
    ld a, %01110111
    ldh [rNR50], a
    
    ; Canal 2 en ambos altavoces
    ld a, %00100010
    ldh [rNR51], a
    
    ; Canal 2: Duty cycle 50% (sonido más lleno)
    ld a, %10000000          ; Bits 7-6: 10 = 50% duty, sin length
    ldh [rNR21], a
    
    ; Volumen máximo constante, sin envolvente
    ld a, %11110000          ; Volumen 15, sin cambios
    ldh [rNR22], a
    
    ; Frecuencia inicial (silencio)
    xor a
    ldh [rNR23], a
    ldh [rNR24], a
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Reproduce la siguiente nota
sys_sound_siguienteNota::
    ; Control de tempo
    ld a, [relojMusica]
    inc a
    cp TEMPO
    jr c, .actualizar_reloj
    
    ; Es momento de cambiar nota
    xor a
    ld [relojMusica], a
    
    ; Obtiene la nota actual
    ld hl, nota_actual
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    
    ; Lee la nota
    ld a, [hl+]
    
    ; ¿Es silencio?
    or a
    jr z, .es_silencio
    
    ; Reproduce la nota
    ldh [rNR23], a
    
    ; CRÍTICO: Trigger para reiniciar el canal
    ld a, [rNR24]          ; Bit 7=trigger, bits 2-0=freq alta
    set 7,a
    ldh [rNR24], a
    jr .actualizar_puntero
    
.es_silencio
    ; Silencia poniendo volumen a 0
    xor a
    ldh [rNR22], a
    
    ; Pequeña pausa
    ld b, 2
.pausa
    dec b
    jr nz, .pausa
    
    ; Restaura volumen
    ld a, %11110000
    ldh [rNR22], a
    
.actualizar_puntero
    ; Guarda nuevo puntero
    ld a, l
    ld [nota_actual], a
    ld a, h
    ld [nota_actual + 1], a
    
    ; Incrementa contador
    ld hl, contador_notas
    inc [hl]
    jr nz, .no_overflow
    inc hl
    inc [hl]
    dec hl
    
.no_overflow
    ; Verifica si llegó al final
    ld de, longitud_cancion
    ld a, [de]
    cp [hl]
    jr nz, .no_reiniciar
    inc de
    inc hl
    ld a, [de]
    cp [hl]
    jr nz, .no_reiniciar
    
    ; Reinicia la canción
    xor a
    ld [contador_notas], a
    ld [contador_notas + 1], a
    
    ld hl, puntero_cancion
    ld a, [hl+]
    ld [nota_actual], a
    ld a, [hl]
    ld [nota_actual + 1], a
    
.no_reiniciar
    ret
    
.actualizar_reloj
    ld [relojMusica], a
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Cambia la canción actual
sys_sound_cambiar_cancion::
    call sys_sound_init_music
    ret

SECTION "Sonido", WRAM0

relojMusica:        DS 1
nota_actual:        DS 2
contador_notas:     DS 2
puntero_cancion:    DS 2
longitud_cancion:   DS 2