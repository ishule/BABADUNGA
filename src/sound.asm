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

DEF LA4=%11011111
DEF LA2=%01011000

DEF TEMPO=8
DEF SH=$FF

DEF TAM_CHIP_SONIDO=20

SECTION "SYS_SOUND",ROM0

;;;;;;;;;
; Inicializa sistema de sonido
; ENTRADA: -
; MODIFICA: AF, BC, DE, HL
; SALIDA: -
;
sys_sound_init::
	ld hl,NR10
	ld b,TAM_CHIP_SONIDO
	xor a
	.loop:
		ld [hl+],a ;; Ponemos valor 0 a todos los registros
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
; Tira sonido de salto
; 
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

;sys_sound_init_music::
;	xor a
;	ld [current_score],a
;	ld hl,contadorNotas
;	ld [hl+],a
;	ld [hl],a
;
;	ld hl,nota
;	ld [hl],LOW(OST)
;	inc hl
;	ld [hl],HIGH(OST)
;	;activar sistema de sonido
;	ld a,%10000000
;	ld [rNR52],a
;	;;Iniciar volumen
	;S01 y S02 casi tope de volumen
;	ld a,%01110111
;	ld [rNR50],a
;	; Canal 2,sale por S01 y S02
;	ld a,%10111011
;	ld [rNR51],a
	;Canal 2, longitud 63, ciclo 75%
;	ld a,%11111111
;	ld [rNR21],a
	;Canal 2, envolvente, volumen inicial alto, creciente
;	ld a,%01010100
;	ld [rNR22],a
	;Canal 2, longitud activada y valor de la frecuencia baja
;	ld a,%01000011
;	ld [rNR24],a
;ret


;SECTION "Sound",WRAM0 ;; Reservar espacio disponible en WRAM
;relojMusica: ds 1
;nota: ds 2
;contadorNotas: ds 2