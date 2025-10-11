INCLUDE "hardware.inc"

DEF NR10=$FF10
DEF NR11=$FF11
DEF NR12=$FF12
DEF NR13=$FF13
DEF NR14=$FF14
DEF NR21=$FF16
DEF NR22=$FF17
DEF NR23=$FF18
DEF NR24=$FF19
DEF NR30=$FF1A
DEF NR31=$FF1B
DEF NR32=$FF1C
DEF NR33=$FF1D
DEF NR34=$FF1E
DEF NR41=$FF20
DEF NR42=$FF21
DEF NR43=$FF22
DEF NR44=$FF23
DEF NR50=$FF24
DEF NR51=$FF25
DEF NR52=$FF26

DEF TEMPO=12
DEF SH=$FF
DEF TAM_CHIP_SONIDO=20

SECTION "SYS_SOUND",ROM0

;;
; Inicializa sistema de sonido
;;
sys_sound_init::
    ld hl,NR10
    ld b,TAM_CHIP_SONIDO
    xor a
    .loop:
        ld [hl+],a
        dec b
    jr nz,.loop
    ld hl,NR50
    ld [hl],$FF
    ld hl, NR51
    ld [hl],$FF
    ld hl,NR52
    set 7,[hl]
    ret

;;
; Sonido de salto
;;
sys_sound_jump::
    ld a,$1E
    ld [NR10],a
    ld a,$82
    ld [NR11],a
    ld a,$77
    ld [NR12],a
    ld a,$C3
    ld [NR13],a
    ld a,$C6
    ld [NR14],a
    ret

;;
; Inicializa música
;;
sys_sound_init_music::
    xor a
    ld [current_score],a
    ld [relojMusica],a
    ld hl,contadorNotas
    ld [hl+],a
    ld [hl],a

    ld hl,nota
    ld [hl],LOW(OST)
    inc hl
    ld [hl],HIGH(OST)
    
    ; Activar sistema de sonido
    ld a,%10000000
    ld [rNR52],a
    
    ; Volumen maestro moderado
    ld a,%01110111
    ld [rNR50],a
    
    ; Canal 2 en ambos altavoces
    ld a,%00100010
    ld [rNR51],a
    
    ; Duty cycle 50%
    ld a,%10000000
    ld [rNR21],a
    
    ; **CAMBIO CRÍTICO**: Volumen 9, CONSTANTE (sin decay)
    ; Tu valor: %01010100 = Vol 5, decreciente, período 4 → se apaga
    ; Nuevo:    %10010000 = Vol 9, constante, período 0 → se mantiene
    ld a,%10010000
    ld [rNR22],a
    
    ; Frecuencia inicial
    xor a
    ld [rNR23],a
    ld [rNR24],a
ret

;;
; Toca la siguiente nota
;;
sys_sound_siguienteNota::
    ld a,[relojMusica]
    cp TEMPO
    jr z,.tocanota
    inc a
    ld [relojMusica],a
ret

.tocanota:
    ; Reiniciar contador
    xor a
    ld [relojMusica],a

    ; Cargar puntero
    ld hl,nota
    ld c,[hl]
    inc hl
    ld b,[hl]
    dec hl

    ; Leer nota
    ld a,[bc]
    
    ; ¿Es silencio?
    cp SH
    jr z,.silencio
    
    ; Escribir frecuencia
    ld [rNR23],a
    
    ; Reconfigurar volumen antes de trigger (seguridad)
    ld a,%10010000
    ld [rNR22],a
    
    ; Trigger nota
    ld a,[rNR24]
    set 7,a
    ld [rNR24],a

.silencio:
    ; Avanzar puntero
    inc bc
    ld a,c
    ld [hl+],a
    ld a,b
    ld [hl],a

    ; Incrementar contador
    ld hl,contadorNotas+1
    ld a,[hl]
    add 1
    ld [hl-],a
    ld a,[hl]
    adc 0
    ld [hl],a
    
    ; Verificar fin
    ld bc,EndOST-OST
    ld a,[hl+]
    cp b
    jr nz,.noReset
    ld a,[hl]
    cp c
    jr z,.resetearNotas

.noReset:
    ret

.resetearNotas:
    xor a
    ld hl,contadorNotas
    ld [hl+],a
    ld [hl],a
    ld hl,nota
    ld [hl],LOW(OST)
    inc hl
    ld [hl],HIGH(OST)
    ret

SECTION "Sound",WRAM0
relojMusica: ds 1
nota: ds 2
contadorNotas: ds 2