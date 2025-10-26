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
sys_sound_pickup_effect::
    ; Pickup: Short, bright ascending tone
    ld a, %00100011  ; NR10: Sweep Time=2, Direction=Increase(0), Shift=3 (Nice quick rise)
    ld [NR10], a
    ld a, %10001100  ; NR11: Duty 50% (clean tone), Length=12 (short but noticeable)
    ld [NR11], a
    ld a, %11000000  ; NR12: Volume=12, No decay (clear tone)
    ld [NR12], a
    ld a, $00        ; NR13: Frequency LSB (Start relatively low for the sweep)
    ld [NR13], a
    ld a, %11000110  ; NR14: Trigger=1, Length Enable=1, Freq MSB=$06 (Ends on a mid-high note)
    ld [NR14], a
    ret
sys_sound_jump_effect::
    ; Disparo: "Pew!" agudo, corto, descendente
    ld a, %00011010  ; NR10: Sweep Time=1, Direction=Decrease(1), Shift=2 (Descenso rápido y sutil)
    ld [NR10], a
    ld a, %01000100  ; NR11: Duty 25% (fino), Longitud MUY corta (4)
    ld [NR11], a
    ld a, %11110001  ; NR12: Volumen MAX (15), Decay rápido (step=1)
    ld [NR12], a
    ld a, $00        ; NR13: Frecuencia baja (no importa mucho, NR14 la sobreescribe casi toda)
    ld [NR13], a
    ld a, %11000111  ; NR14: Trigger + Length Enable + Frecuencia ALTA ($07) - ¡La más alta posible!
    ld [NR14], a
    ret
sys_sound_shoot_effect::
    ; Salto: Tono ascendente limpio y corto
    ld a, %00100011  ; NR10: Sweep Time=2, Direction=Increase(0), Shift=3 (Ascenso moderado)
    ld [NR10], a
    ld a, %10010000  ; NR11: Duty 50%, Longitud media-corta (16)
    ld [NR11], a
    ld a, %11110000  ; NR12: Volumen MAX (15), Sin Decay
    ld [NR12], a
    ld a, $00        ; NR13: Frecuencia baja inicial
    ld [NR13], a
    ld a, %11000110  ; NR14: Trigger + Length Enable + Frecuencia media-alta ($06)
    ld [NR14], a
    
    ret
    
sys_sound_boss_death_effect::
    ; Muerte del boss: Explosión grande con múltiples componentes
    ; Canal 1: Tono bajo que baja
    ld a, %01110101   ; Sweep descendente pronunciado
    ld [NR10], a
    ld a, %10111111   ; Duty 50%, longitud larga
    ld [NR11], a
    ld a, %11110010   ; Volumen 15, decay
    ld [NR12], a
    ld a, $00
    ld [NR13], a
    ld a, %10000010   ; Trigger + tono bajo
    ld [NR14], a
    
    ; Canal 4: Explosión ruidosa intensa
    ld a, %00111111   ; Longitud larga
    ld [NR41], a
    ld a, %11110011   ; Volumen MÁXIMO (15), decay lento
    ld [NR42], a
    ld a, %00110111   ; Ruido explosivo (7-bit, muy caótico)
    ld [NR43], a
    ld a, %10000000   ; Trigger
    ld [NR44], a
    ret

sys_sound_hit_effect::
    ; Golpe/Hit: Impacto seco y corto
    ld a, %00000011   ; NR41: Longitud muy corta (3) - más seco
    ld [NR41], a
    ld a, %11110001   ; NR42: Volumen 15 (FUERTE), decay muy rápido
    ld [NR42], a
    ld a, %01100011   ; NR43: Ruido más grave y seco (mejor impacto)
    ld [NR43], a
    ld a, %11000000   ; NR44: Trigger + length enable
    ld [NR44], a
    ret

sys_sound_player_gets_hit_effect::
    ; "Oof" sound - Short, downward pitch sweep with decay
    ld a, %00101100  ; NR10: Sweep Time=2, Direction=Decrease(1), Shift=4 (Fast pitch drop)
    ld [NR10], a
    ld a, %10001010  ; NR11: Duty 50%, Length=10 (Short duration)
    ld [NR11], a
    ld a, %11110010  ; NR12: Volume MAX (15), Fast Decay (step=2)
    ld [NR12], a
    ld a, $EC        ; NR13: Frequency LSB (Part of the starting pitch - approx G5)
    ld [NR13], a
    ld a, %11000101  ; NR14: Trigger=1, Length Enable=1, Freq MSB=$05 (Completes G5 pitch)
    ld [NR14], a
    ret

sys_sound_spit_effect::
    ; Escupitajo: "Ptui!" húmedo y rápido
    ; Canal 1: Tono descendente rápido
    ld a, %00010111   ; Sweep descendente muy rápido
    ld [NR10], a
    ld a, %00000100   ; Duty 0% (más áspero), longitud muy corta (4)
    ld [NR11], a
    ld a, %11000010   ; Volumen 12, decay
    ld [NR12], a
    ld a, $50         ; Frecuencia media-alta
    ld [NR13], a
    ld a, %11000101   ; Trigger + length enable
    ld [NR14], a
    
    ; Canal 4: Ruido húmedo/siseante simultáneo
    ld a, %00000011   ; Longitud muy corta
    ld [NR41], a
    ld a, %10100001   ; Volumen 10, decay rápido
    ld [NR42], a
    ld a, %01100001   ; Ruido "hissy" agudo
    ld [NR43], a
    ld a, %11000000   ; Trigger + length enable
    ld [NR44], a
    ret

sys_sound_player_dies::
    ; Muerte del jugador: Tono grave, largo y sostenido

    ; --- Canal 1: Tono Grave 1 (e.g., C3) ---
    ld a, %00000000      ; NR10: No sweep
    ld [NR10], a
    ld a, %10000000      ; NR11: Duty 50%, Length DISABLED (plays indefinitely until stopped)
    ld [NR11], a
    ld a, %11110000      ; NR12: Volume MAX (15), No Decay (sustained)
    ld [NR12], a
    ld a, $D4            ; NR13: Frequency LSB for C3
    ld [NR13], a
    ld a, %10000001      ; NR14: Trigger=1, Length Disable=0, Freq MSB=$01 (Completes C3)
    ld [NR14], a

    ; --- Canal 2: Tono Grave 2 (e.g., C#3 - slight dissonance) ---
    ld a, %10000000      ; NR21: Duty 50%, Length DISABLED
    ld [NR21], a
    ld a, %11110000      ; NR22: Volume MAX (15), No Decay
    ld [NR22], a
    ld a, $63            ; NR23: Frequency LSB for C#3
    ld [NR23], a
    ld a, %10000010      ; NR24: Trigger=1, Length Disable=0, Freq MSB=$02 (Completes C#3)
    ld [NR24], a

    ; --- Canal 4: Ruido Grave (Rumble) ---
    ld a, %00111111      ; NR41: Max Length (~0.25s with length enabled)
    ld [NR41], a
    ld a, %11110011      ; NR42: Volume MAX (15), Slow Decay (step=3)
    ld [NR42], a
    ld a, %01110111      ; NR43: Clock Shift=7, 7-bit Noise, Divisor=7 (Low rumble)
    ld [NR43], a
    ld a, %11000000      ; NR44: Trigger + Length Enable=1 (sound stops after NR41 duration)
    ld [NR44], a

    ; --- Wait for the sound duration ---
    ld c, 14             ; Duration in frames (~1.5 seconds at 60fps)
.wait:
    call wait_time_vblank_24
    dec c
    jr nz, .wait

    ; --- Explicitly Stop Channels 1 & 2 (by setting volume to 0) ---
    xor a                ; A = 0
    ld [NR12], a         ; Set Channel 1 Volume Envelope to 0
    ld [NR22], a         ; Set Channel 2 Volume Envelope to 0
    ; Channel 4 stops automatically due to length or decay

    ret
; =============================================
; sys_sound_door_opening_scrape
; Plays a very short scraping noise. Call repeatedly during animation.
; Uses Channel 4.
; MODIFIES: A
; =============================================
sys_sound_door_opening_scrape::
    ld a, %00000010  ; NR41: Length VERY short (2)
    ld [NR41], a
    ld a, %10100010  ; NR42: Volume=10, Decay fast (step=2)
    ld [NR42], a
    ld a, %01010100  ; NR43: Clock Shift=5, 7-bit Noise, Divisor=4 (Mid-frequency scrape)
    ld [NR43], a
    ld a, %11000000  ; NR44: Trigger + Length Enable
    ld [NR44], a
    ret

; =============================================
; sys_sound_door_opened_clink
; Plays a short, clear "clink" sound. Call once when animation finishes.
; Uses Channel 1.
; MODIFIES: A
; =============================================
sys_sound_door_opened_clink::
    ld a, %00000000  ; NR10: No Sweep
    ld [NR10], a
    ld a, %10001000  ; NR11: Duty 50%, Length=8 (short)
    ld [NR11], a
    ld a, %11100000  ; NR12: Volume=14, No Decay
    ld [NR12], a
    ld a, $00        ; NR13: Frequency LSB
    ld [NR13], a
    ld a, %11000111  ; NR14: Trigger + Length Enable + Frequency HIGH ($07)
    ld [NR14], a
    ret

; =============================================
; sys_sound_earthquake_rumble
; Plays a low-frequency rumbling noise.
; Uses Channel 4.
; MODIFIES: A
; =============================================
sys_sound_earthquake_rumble::
    ld a, %00111111      ; NR41: Long Length (Max duration with length enabled)
    ld [NR41], a
    ld a, %11110011      ; NR42: Volume MAX (15), Slow Decay (step=3) - makes it rumble longer
    ld [NR42], a
    ld a, %10000111      ; NR43: Clock Shift=8, 7-bit Noise, Divisor=7 (Very low frequency rumble)
    ld [NR43], a
    ld a, %11000000      ; NR44: Trigger + Length Enable=1 (sound stops after NR41 duration)
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

sys_sound_init_rest_music::
    ld hl,RestMusic
    ld bc, EndRestMusic-RestMusic
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