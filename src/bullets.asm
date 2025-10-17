INCLUDE "consts.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Structure
;;  [tile_ID], [v_high], [v_low], [height], [width]
SECTION "Bullet Presets", ROM0
player_bullet_preset_h::
	DB PLAYER_BULLET_TILE_HORIZONTAL, PLAYER_BULLET_SPEED_HIGH, PLAYER_BULLET_SPEED_LOW, PLAYER_BULLET_HEIGHT, PLAYER_BULLET_WIDTH
player_bullet_preset_v::
	DB PLAYER_BULLET_TILE_VERTICAL,   PLAYER_BULLET_SPEED_HIGH, PLAYER_BULLET_SPEED_LOW, PLAYER_BULLET_HEIGHT, PLAYER_BULLET_WIDTH
snake_bullet_preset::
	DB SNAKE_BULLET_TILE,             SNAKE_BULLET_SPEED_HIGH,  SNAKE_BULLET_SPEED_LOW,  SNAKE_BULLET_HEIGHT,  SNAKE_BULLET_WIDTH
spider_bullet_preset::
	DS 5

SECTION "Bullets Code" , ROM0

; ============ ESTÁ SIN HACER ===============
; Falta ver como hago para no necesitar tantos registros
; INPUT 
;  HL -> preset address
;  BC -> "gun sprite" origin
;  D  -> direction
;
; MODIFIES:
shot_bullet_for_preset::
	


	ret

; INPUT
;  BC -> "gun sprite" origin
;  D  -> direction   ($00:< | $01:>)
;
; MODIFIES:
shot_bullet_for_snake::
	call man_entity_alloc

	;; Bullet INFO
	ld a, BYTE_ACTIVE
	ld [hl+], a 		; Active = 1 

	ld a, TYPE_BULLET 	; Bullet = 3 
	ld [hl+], a

	xor a
    or FLAG_CAN_DEAL_DAMAGE | FLAG_DESTROY_ON_HIT
    ld [hl+], a                     ; guarda el nuevo valor y se posiciona para actualizar ATTR
 
 	ld a, d
	cp RIGHT_SHOT_DIRECTION
	jr z, .shot_right

	.shot_left:
		; Set origin
		ld a, c
		sub SPRITE_WIDTH + 4 ; 4 = offset para evitar colision con nosotros mismos
		ld c, a

		; Set velocity
		ld de, SNAKE_BULLET_SPEED
		call positive_to_negative_DE

		; Set ATTR -> Flip sprite
		inc h
		ld [hl], SPRITE_ATTR_FLIP_X
		
		jr .spawn_bullet

	.shot_right:
		; Set origin
		ld a, c
		add SPRITE_WIDTH + 4 ; 4 = offset
		ld c, a

		; Set velocity
		ld de, SNAKE_BULLET_SPEED

		; Set ATTR -> No flip Sprite
		inc h
		ld [hl], SPRITE_ATTR_NO_FLIP


	.spawn_bullet:
	; === Set tile ===
	dec l
	ld [hl], SNAKE_BULLET_TILE

	; === Set Position ===
	; set pos x
	dec l
	ld [hl], c

	; set pos y
	dec l
	ld [hl], b

	;; === Set Size === 
	inc h
	inc l
	inc l

	ld a, SNAKE_BULLET_HEIGHT 
	ld [hl+], a 

	ld a, SNAKE_BULLET_WIDTH 
	ld [hl], a

	; === Set Velocity ===
	inc h
	ld [hl], e ; vel_x_low
	dec l
	dec l
	ld [hl], d ; vel_x_high

	ret

bullet_update::
	ld a, [can_shot_flag]  ; if can_shot == true => shot:
	bit 0, a
	jr nz, shot

	ld a, [shot_cooldown]       ; if shot_cooldown != 0    => exit
	dec a
	ld [shot_cooldown], a
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

	; Check up shot
	bit JOYPAD_UP, a
	jr nz, .looking_up

	; Check direction
	ld a, PLAYER_GUN_ENTITY_ID
	call man_entity_locate_v2
	inc h
	ld b, [hl] ; Y pos -> B
	inc l
	ld c, [hl] ; X pos -> C
	inc l
	inc l
	ld a, [hl] ; Read Sprite ATTR
	bit 5, a   ; Check flip
	jr z, .looking_right

	.looking_left:
		ld d, LEFT_SHOT_DIRECTION
		jr call_shot

	.looking_right:
		ld d, RIGHT_SHOT_DIRECTION
		jr call_shot

	.looking_up:
		ld a, PLAYER_GUN_ENTITY_ID
		call man_entity_locate_v2
		inc h
		ld b, [hl]
		inc l
		ld c, [hl]
		ld d, UP_SHOT_DIRECTION

	call_shot:
	call shot_bullet


	ld a, COOLDOWN_SHOT_DELAY
	ld [shot_cooldown], a
	
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
	ld [shot_cooldown], a
	inc a
	ld [can_shot_flag], a
	ret


; shot_bullet
; Dispara una bala desde la posición indicada hacia la dirección indicada
;
; INPUT
;   bc -> gun origin  (píxeles Y|X)
;   d  -> direction   ($00:< | $01:> | $02:^ | $03:v)
;
; MODIFIED: hl
shot_bullet:
	call man_entity_alloc

	;; Bullet INFO
	ld a, BYTE_ACTIVE
	ld [hl+], a 		; Active = 1 

	ld a, TYPE_BULLET 	; Bullet = 3 
	ld [hl+], a

	xor a
    or FLAG_CAN_DEAL_DAMAGE | FLAG_DESTROY_ON_HIT
    ld [hl+], a                     ; guarda el nuevo valor y se posiciona para actualizar ATTR
 
 	ld a, d
	cp RIGHT_SHOT_DIRECTION
	jr z, .shot_right

	cp UP_SHOT_DIRECTION
	jr z, .shot_up

	.shot_left:
		; Set origin
		ld a, c
		sub SPRITE_WIDTH + 4 ; 4 = offset para evitar colision con nosotros mismos
		ld c, a

		; Set velocity
		ld de, PLAYER_BULLET_SPEED
		call positive_to_negative_DE

		; Set ATTR -> Flip sprite
		inc h
		ld [hl], SPRITE_ATTR_FLIP_X
		
		jr .spawn_bullet_horizontal

	.shot_right:
		; Set origin
		ld a, c
		add SPRITE_WIDTH + 4 ; 4 = offset
		ld c, a

		; Set velocity
		ld de, PLAYER_BULLET_SPEED

		; Set ATTR -> No flip Sprite
		inc h
		ld [hl], SPRITE_ATTR_NO_FLIP

		jr .spawn_bullet_horizontal

	.shot_up:
		; Set origin
		ld a, b
		add SPRITE_HEIGHT / 2 ; 4 = offset
		ld b, a

		; Set velocity
		ld de, PLAYER_BULLET_SPEED
		call positive_to_negative_DE

		; Set ATTR -> No flip Sprite
		inc h
		ld [hl], SPRITE_ATTR_NO_FLIP

		jr .spawn_bullet_vertical

	.spawn_bullet_horizontal:
	; === Set tile ===
	dec l
	ld [hl], PLAYER_BULLET_TILE_HORIZONTAL

	; === Set Position ===
	; set pos x
	dec l
	ld [hl], c

	; set pos y
	dec l
	ld [hl], b

	;; === Set Size === 
	inc h
	inc l
	inc l

	ld a, PLAYER_BULLET_HEIGHT 
	ld [hl+], a 

	ld a, PLAYER_BULLET_WIDTH 
	ld [hl], a

	; === Set Velocity ===
	inc h
	ld [hl], e ; vel_x_low
	dec l
	dec l
	ld [hl], d ; vel_x_high

	jr .finish

	.spawn_bullet_vertical:
	; === Set tile ===
	dec l
	ld [hl], PLAYER_BULLET_TILE_VERTICAL

	; === Set Position ===
	; set pos x
	dec l
	ld [hl], c

	; set pos y
	dec l
	ld [hl], b

	;; === Set Size === 
	inc h
	inc l
	inc l

	ld a, PLAYER_BULLET_HEIGHT 
	ld [hl+], a 

	ld a, PLAYER_BULLET_WIDTH 
	ld [hl], a

	; === Set Velocity ===
	inc h
	dec l
	ld [hl], e ; vel_y_low
	dec l
	dec l
	ld [hl], d ; vel_y_high

	.finish:

	ret