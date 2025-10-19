INCLUDE "hardware.inc"
    rev_Check_hardware_inc 4.0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Constantes

DEF NR10 = $FF10
DEF NR11 = $FF11
DEF NR12 = $FF12
DEF NR13 = $FF13
DEF NR14 = $FF14
DEF NR21 = $FF16
DEF NR22 = $FF17
DEF NR23 = $FF18
DEF NR24 = $FF19
DEF NR30 = $FF1A
DEF NR31 = $FF1B
DEF NR32 = $FF1C
DEF NR33 = $FF1D
DEF NR34 = $FF1E
DEF NR41 = $FF20
DEF NR42 = $FF21
DEF NR43 = $FF22
DEF NR44 = $FF23
DEF NR50 = $FF24
DEF NR51 = $FF25
DEF NR52 = $FF26

DEF TEMPO = 8
DEF SH = $FF ;Silencio

DEF TAM_CHIP_SONIDO = 20

SECTION "SYS_SOUND", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inicializa el sistema de sonido
sys_sound_init::
    ld hl, NR10
    ld b, TAM_CHIP_SONIDO
    ld a, 0
    .loop
        ld [hl+], a
        dec b
    jr nz, .loop
    ld hl, NR50
    ld [hl],$FF
    ld hl, NR51
    ld [hl],$FF
    ld hl, NR52
    set 7, [hl]
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Sound Effects
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sys_sound_shoot_effect::
    ld a, $1E     
    ld [NR10], a
    ld a, $82     
    ld [NR11], a
    ld a, $47     
    ld [NR12], a
    ld a, $C3     
    ld [NR13], a
    ld a, $C6 
    ld [NR14], a
    ret
    
sys_sound_death_effect::
    ; Canal 4 (Ruido) para una muerte
    ld a, %00111111   ; Longitud
    ld [NR41], a
    ld a, %11110010   ; Volumen 15 (¡FUERTE!), DECAY, Período 2
    ld [NR42], a
    ld a, %01010101   ; Ruido "crujiente"
    ld [NR43], a
    ld a, %10000000   ; Trigger
    ld [NR44], a
    ret
sys_sound_hit_effect::
    ld a, %00000101   ; NR41: Longitud MUY corta (5)
    ld [NR41], a
    ld a, %10000010   ; NR42: Volumen 8 (¡FLOJO!), DECAY, Período 2 (muy rápido)
    ld [NR42], a
    ld a, %01010101   ; NR43: Ruido "crujiente" (buen pop)
    ld [NR43], a
    ld a, %11000000   ; NR44: Trigger Y 'length enable' (se apaga por longitud)
    ld [NR44], a
    ret
sys_sound_spit_effect::
    ; Canal 4 (Ruido) para un "spit" (escupitajo) Para la serpiente
    ld a, %00000101   ; NR41: Longitud MUY corta (5)
    ld [NR41], a
    ld a, %11110010   ; NR42: Volumen 15 (Fuerte), DECAY, Período 2 (muy rápido)
    ld [NR42], a
    ld a, %01010001   ; NR43: Ruido "hissy" agudo (Clock 5, 15-bit, Div 1)
    ld [NR43], a
    ld a, %11000000   ; NR44: Trigger Y 'length enable' (se apaga por longitud)
    ld [NR44], a
    ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inicializa el sistema de música (Tu versión)
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
    
    ; --- INICIALIZA EL HARDWARE (Lógica del "archivo bueno") ---
    ; activar sistema de sonido
    ld a, %10000000
    ld [rNR52], a
    ; iniciamos los volumenes
    ld a, %01110111           ; SO1 y S02 casi tope de volumen
    ld [rNR50], a
    ld a, %10111011           ; Canal 2, sale por SO1 y S02
    ld [rNR51], a
    ; canal 2, longitud 63, ciclo 75%
    ld a, %11111111
    ld [rNR21], a
    ; canal 2, envolvente, volumen inicial alto, creciente
    ld a, %01010100
    ld [rNR22], a
    ; canal 2, longitud activada y valor de la frecuencia baja
    ld a, %01000011           ; 1 en el bit 6, longitud activa, y
    ld [rNR24], a             ; %011 en los tres bits altos de la frecuencia
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Cambia la nota a la siguente a tocar
;; (CON EL BUG DEL CONTADOR CORREGIDO)
;;
sys_sound_siguienteNota:
    ld a, [relojMusica]       ; vemos si hay que tocar la nota o esperar
    cp a, TEMPO
    jr z, .tocanota
    inc a
    ld [relojMusica], a
ret
.tocanota:
    ; reiniciamos el contador
    ld a, 0
    ld [relojMusica], a

    ; pasamos a tocar la nota
    ld hl, nota_actual  ; <-- Variable generalizada
    ld c, [hl]
    inc hl
    ld b, [hl]   ; BC: puntero a nota a tocar
    dec hl

    ld a, [bc] ; A = NOTA a tocar
    ;; Es silencio?
    cp SH
    jr z, .silencio
    ld [rNR23], a ; la escribimos en el registro de frecuencia del canal 2
    ; reiniciamos la nota
    ld a, [rNR24]
    set 7,a
    ld [rNR24], a

    .silencio

    ; pasamos a la siguiente nota y comprobamos si tenemos que reiniciar
    inc bc
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl], a

; --- INICIO DEL BLOQUE CORREGIDO ---
    ; Incrementa el contador de 16 bits (contador_notas)
    ld hl, contador_notas
    inc [hl]                ; Incrementa el byte bajo (LSB)
    jr nz, .comprobarFinal  ; Si no es cero (no hay overflow), saltamos
    inc hl                  ; Si hubo overflow, apuntamos al byte alto (MSB)
    inc [hl]                ; Incrementamos el byte alto
    
.comprobarFinal:
    ; Recargamos HL al inicio del contador para la comparación
    ld hl, contador_notas
; --- FIN DEL BLOQUE CORREGIDO ---
    
    ; Compara con la longitud guardada
    ld de, longitud_cancion ; <-- Variable generalizada
    ld a, [de]
    cp [hl]
    jr nz, .noReseteamos
    inc de
    inc hl
    ld a, [de]
    cp [hl]     ; hemos llegado al final?
    jr z, .reseteanotas
    
    .noReseteamos
ret
.reseteanotas:
    ;si, reiniciarmos, guardamos y volvemos
    ld hl, contador_notas
    ld [hl], 0
    inc hl
    ld [hl], 0
    
    ; Carga el INICIO de la canción guardado
    ld hl, puntero_cancion ; <-- Variable generalizada
    ld c, [hl]
    inc hl
    ld b, [hl]
    ld hl, nota_actual
    ld [hl], c       ; Guarda el byte bajo (LSB)
    inc hl           ; Apunta al byte alto (MSB) de nota_actual
    ld [hl], b       ; Guarda el byte alto (MSB)
ret

sys_sound_init_inicio_music::
    ld hl,InicioMusic
    ld bc,EndInicioMusic-InicioMusic
    call sys_sound_init_music
    ret
sys_sound_init_gorilla_music::
    ld hl,GorillaMusic
    ld bc,EndGorillaMusic-GorillaMusic
    call sys_sound_init_music
    ret
sys_sound_init_snake_music::
    ld hl,SnakeMusic
    ld bc,EndSnakeMusic-SnakeMusic
    call sys_sound_init_music
    ret
sys_sound_init_spider_music::
    ld hl,SpiderMusic
    ld bc,EndSpiderMusic-SpiderMusic
    call sys_sound_init_music
    ret
sys_sound_init_victory_music::
    ld hl, VictoryMusic
    ld bc,EndVictoryMusic-VictoryMusic
    call sys_sound_init_music
    ret
sys_sound_init_defeat_music::
    ld hl, DefeatMusic
    ld bc,EndDefeatMusic-DefeatMusic
    call sys_sound_init_music
    ret

SECTION "Sonido", WRAM0

relojMusica:
ds 1
nota_actual:           ; Puntero a la nota que toca sonar
ds 2
contador_notas:
ds 2
puntero_cancion:       ; Dirección de la primera nota (para el loop)
ds 2
longitud_cancion:      ; Longitud total de la canción
ds 2