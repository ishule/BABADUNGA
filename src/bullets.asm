INCLUDE "consts.inc"

def COOLDOWN_SHOT equ 40

SECTION "variables", WRAM0
cooldown: ds 1
can_shot_flag: ds 1

SECTION "Bullets utils", ROM0

bullet_update::
	ld a, [can_shot_flag]  ; if can_shot == true => shot:
	bit 0, a
	jr nz, shot

	ld a, [cooldown]       ; if cooldown != 0    => exit
	dec a
	ld [cooldown], a
	jr nz, exit

	xor a
	inc a
	ld [can_shot_flag], a  ; reset flag
	jr exit


	shot:
	call joypad_read
	ld a, [joypad_input]
	bit JOYPAD_A, a
	jr z, exit

	ld hl, $C005
	ld a, [hl]
	add 8
	ld b, a
	ld c, $88
	xor a
	call shot_bullet


	ld a, COOLDOWN_SHOT
	ld [cooldown], a
	
	xor a
	ld [can_shot_flag], a

	exit:
	ret


init_bullets::
	ld hl, Player_bullet
	ld de, $8200
	ld b, 16
	call memcpy_256
	xor a
	ld [cooldown], a
	inc a
	ld [can_shot_flag], a
	ret


; shot_bullet
; Dispara una bala desde la posición indicada hacia la dirección indicada
;
; INPUT
;   bc -> orígen (píxeles X|Y)
;   a  -> dirección ($00:> | $01:< | $02:^ | $03:v)
shot_bullet:
	call man_entity_alloc
	
	ld [hl], c
	inc hl

	ld [hl], b
	inc hl

	ld [hl], $20
	inc hl

	ld [hl], $00

	ret