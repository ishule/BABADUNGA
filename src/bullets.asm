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

	ld a, [$C105] ; MAGIC
	add 8         ; MAGIC
	ld b, a

	ld a, [$C104] ; MAGIC
	ld c, a

	ld a, [$C107] ; MAGIC
	bit 5, a      ; MAGIC
	jr z, looking_right
	looking_left: 
		ld a, $01 ; MAGIC
		jr call_shot

	looking_right:
		xor a

	call_shot:
	call shot_bullet


	ld a, COOLDOWN_SHOT
	ld [cooldown], a
	
	xor a
	ld [can_shot_flag], a

	exit:
	ret


init_bullets::
	ld hl, Player_bullet
	ld de, $8200 ; MAGIC
	ld b, 16     ; MAGIC
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
;
; MODIFIED: hl
shot_bullet:
	push af
	call man_entity_alloc
	pop af
	push af

	;; Bullet INFO
	push hl
	dec h 
	ld a, BYTE_ACTIVE
	ld [hl+], a 		; Active = 1 

	ld a, TYPE_BULLET 	; Bullet = 3 
	ld [hl+], a

	ld a, [hl]                     ; carga el byte actual
    or FLAG_CAN_DEAL_DAMAGE | FLAG_DESTROY_ON_HIT
    ld [hl], a                     ; guarda el nuevo valor

	pop hl

	pop af 
	push af 
	cp 01 	; Si va hacia la izquierda desplazamos origen de la bala
	jr z, .move_bullet_left

.move_bullet_left:
	;; CMP_SPRITE
	ld [hl], c
	inc hl

	ld a, b 
	sub 4  	; Offset para ajustar posicion bala (así evitamos que nos toque)
	ld [hl], a
	inc hl
	
	jr .continue

.move_bullet_right:	
	;; CMP_SPRITE
	ld [hl], c
	inc hl

	ld [hl], b
	inc hl

	.continue:
	ld [hl], $20 ; MAGIC
	inc hl

	ld [hl], $00 ; MAGIC



	;; ADD WIDTH AND HEIGHT
	inc h
	inc h
	dec l 
	dec l 
	dec l  

	ld a, BULLET_HEIGHT 
	ld [hl+], a 

	ld a, BULLET_WIDTH 
	ld [hl+], a


	;; APPLY VELOCITY
	dec h
	pop af

	cp 0 ; MAGIC
	jr z, right_shot

	cp 1 ; MAGIC
	jr z, left_shot

	cp 2 ; MAGIC
	jr z, up_shot




	down_shot:


	right_shot:
		inc l
		ld [hl], $10 ; MAGIC
		dec l
		jr spawn_bullet

	left_shot:
		inc l
		ld [hl], $F8 ; MAGIC
		dec l
		jr spawn_bullet

	up_shot:

	spawn_bullet:
	ret