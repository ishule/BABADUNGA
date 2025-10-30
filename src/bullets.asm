INCLUDE "consts.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Structure
;;  [tile_h_ID], [tile_v_ID], [damage],[p_coll_y], [p_coll_x], [height], [width], [v_low], [v_high]
SECTION "Bullet Presets", ROM0
player_bullet_0_preset::
	DB 1
	DB PLAYER_BULLET_TILE_H, PLAYER_BULLET_TILE_V, PLAYER_BULLET_DAMAGE
	DL PLAYER_BULLET_0_H_COLLISION
	DL PLAYER_BULLET_0_V_COLLISION
	DB PLAYER_BULLET_SPEED_LOW, PLAYER_BULLET_SPEED_HIGH
player_bullet_1_preset::
	DB 1
	DB PLAYER_BULLET_1_TILE_H, PLAYER_BULLET_1_TILE_V, PLAYER_BULLET_1_DAMAGE
	DL PLAYER_BULLET_1_H_COLLISION
	DL PLAYER_BULLET_1_V_COLLISION
	DB PLAYER_BULLET_SPEED_LOW, PLAYER_BULLET_SPEED_HIGH
player_bullet_2_preset::
	DB 1
	DB PLAYER_BULLET_2_TILE_H, PLAYER_BULLET_2_TILE_V, PLAYER_BULLET_2_DAMAGE
	DL PLAYER_BULLET_2_H_COLLISION
	DL PLAYER_BULLET_2_V_COLLISION
	DB PLAYER_BULLET_SPEED_LOW, PLAYER_BULLET_SPEED_HIGH
snake_bullet_preset::
	DB 0
	DB SNAKE_BULLET_TILE_H, SNAKE_BULLET_TILE_V, SNAKE_BULLET_DAMAGE
	DL SNAKE_BULLET_H_COLLISION
	DL SNAKE_BULLET_V_COLLISION
	DB SNAKE_BULLET_SPEED_LOW, SNAKE_BULLET_SPEED_HIGH
gorilla_bullet_0_preset::
	DB 0
	DB GORILLA_BULLET_TILE_H, GORILLA_BULLET_TILE_V, GORILLA_BULLET_DAMAGE
	DL GORILLA_BULLET_H_COLLISION
	DL GORILLA_BULLET_V_COLLISION
	DB GORILLA_BULLET_SPEED_LOW, GORILLA_BULLET_SPEED_HIGH
spider_bullet_preset::
	DB 0
	DB SPIDER_BULLET_TILE_H, SPIDER_BULLET_TILE_V, SPIDER_BULLET_DAMAGE
	DL SPIDER_BULLET_H_COLLISION
	DL SPIDER_BULLET_V_COLLISION
	DB SPIDER_BULLET_SPEED_LOW, SPIDER_BULLET_SPEED_HIGH
spider_big_bullet_0_preset::
	DB 0
	DB SPIDER_BIG_BULLET_0_TILE_H, SPIDER_BIG_BULLET_0_TILE_V, SPIDER_BIG_BULLET_0_DAMAGE
	DL SPIDER_BIG_BULLET_0_H_COLLISION
	DL SPIDER_BIG_BULLET_0_V_COLLISION
	DB SPIDER_BIG_BULLET_0_SPEED_LOW, SPIDER_BIG_BULLET_0_SPEED_HIGH
spider_big_bullet_1_preset::
	DB 0
	DB SPIDER_BIG_BULLET_1_TILE_H, SPIDER_BIG_BULLET_1_TILE_V, SPIDER_BIG_BULLET_1_DAMAGE
	DL SPIDER_BIG_BULLET_1_H_COLLISION
	DL SPIDER_BIG_BULLET_1_V_COLLISION
	DB SPIDER_BIG_BULLET_1_SPEED_LOW, SPIDER_BIG_BULLET_1_SPEED_HIGH

SECTION "Bullets Code" , ROM0

; ============= Main method to shot ======================
; INPUT 
;  DE -> preset address
;  BC -> "gun sprite" origin
;  a  -> direction ($00:< | $01:> | $02:^ | $03:v) 
;                  (%00:< | %01:> | %10:^ | %11:v)
;                   ## bit 1 -> 0:Horizontal | 1:Vertical 
;                   ## bit 0 -> 0:Negative   | 1:Positive
;
; MODIFIES: All
shot_bullet_for_preset::
	push af ; Save direction
	
	call man_entity_alloc

	;; Bullet INFO
	ld a, BYTE_ACTIVE
	ld [hl+], a 		

	ld a, TYPE_BULLET 
	ld [hl+], a

	ld a, [de]
	or a
	jr nz, .player_bullet
	.enemy_bullet:
    	ld [hl], FLAG_CAN_DEAL_DAMAGE | FLAG_DESTROY_ON_HIT
	    jr .go_on
	.player_bullet:

	    ld [hl], FLAG_CAN_DEAL_DAMAGE | FLAG_DESTROY_ON_HIT | FLAG_BULLET_PLAYER

	.go_on:
    inc de
    inc h ; Prepare for CMP_SPRITE_TILE

    ; HL = CMP_SPRITE_TILE ($C102)

 	pop af  ; Retrieve direction
 	push af ; Save direction
	bit 1, a
	jr z, .shot_horizontal

	.shot_vertical:
		inc de ; Go to vertical tile of preset
		ld a, [de]  ; Read TILE_V
		ld [hl+], a ; Set entity Tile
		
		; Go to preset damage
		inc de

		; HL = CMP_SPTITE_ATTR ($C103)

		pop af
		push af
		bit 0, a
		jr  nz, .no_flip_y

		.flip_y:                             ;; UP SHOT
			;; Set ATTR
			ld [hl], SPRITE_ATTR_FLIP_Y

			;; Set spawn point
			ld a, b
			sub SPRITE_WIDTH
			ld b, a

			jr .bullet_settings

		.no_flip_y:                          ;; DOWN SHOT
			;; Set ATTR
			ld [hl], SPRITE_ATTR_NO_FLIP
			
			;; Set spawn point
			ld a, b
			add SPRITE_HEIGHT
			ld b, a

			jr .bullet_settings

	.shot_horizontal:
		ld a, [de]  ; Read TILE_H
		ld [hl+], a ; Set entity Tile
		
		; Go to preset damage
		inc de
		inc de

		; HL = CMP_SPTITE_ATTR ($C103)

		pop af
		push af
		bit 0, a
		jr nz, .no_flip_x

		.flip_x:                             ;; LEFT SHOT
			;; Set ATTR
			ld [hl], SPRITE_ATTR_FLIP_X

			;; Set spawn point
			ld a, c
			sub SPRITE_WIDTH
			ld c, a

			jr .bullet_settings

		.no_flip_x:                          ;; RIGHT SHOT
			;; Set ATTR
			ld [hl], SPRITE_ATTR_NO_FLIP

			;; Set spawn point
			ld a, c
			add SPRITE_WIDTH
			ld c, a


	.bullet_settings:
		;; ========== Set Size ==========
		; Set Width
		inc h       ; Go to entity damage
		ld a, [de]
		ld [hl-], a 
		dec l       ; Skip entity health

		; HL = PHYSICS_P_LOW


		;; ========== Set Pos ==========
		; Set pos_x_high
		dec h
		ld [hl], c

		; HL = SPRITE_POS_X

		; Set pos_y_high
		dec l
		ld [hl], b

		; HL = SPRITE_POS_Y

		;; ========== Set Coll =========
		pop af
		push af
		bit 1, a
		jr z, .horizontal_shot
		inc de
		inc de
		inc de
		inc de
		.horizontal_shot: 

		ld h, CMP_COLLISIONS_H ; Go to entity y_coll_offset
		inc de                 ; Go to preset p_y_coll
		ld a, [de]
		ld [hl+], a ; Set y_collision_offset
		inc de
		ld a, [de]
		ld [hl+], a ; Set x_collision_offset
		inc de
		ld a, [de]
		ld [hl+], a ; Set height
		inc de
		ld a, [de]
		ld [hl],  a ; Set width


		pop af
		push af
		bit 1, a
		jr nz, .vertical_shot
		inc de
		inc de
		inc de
		inc de
		.vertical_shot: 
		; HL = PHYSICS_WIDTH

		;; ========== Set Vel ==========
		dec h
		dec h

		;HL = PHYSICS_V_X_LOW

		pop af
		push af
		bit 1, a      ; 0:x | 1:y
		jr z, .vel_x

		.vel_y:
			dec l
			jr .change_vel
		.vel_x: 

		.change_vel:
			; HL = V_LOW (X/Y)
			inc de      ; Go to preset v_low
			ld a, [de]
			ld c, a

			inc de     ; Go to preset v_high
			ld a, [de]
			ld b, a
			
			pop af
			bit 0, a ; 0:- | 1:+
			jr nz, .skip_conversion
			call positive_to_negative_BC
			.skip_conversion:

			ld [hl], c ; Set v_low
			dec l
			dec l
			ld [hl], b ; Set v_high

	ret

check_player_shot::
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
		ld a, PLAYER_BODY_ENTITY_ID
		call man_entity_locate_v2
		inc h
		ld b, [hl]
		inc l
		ld c, [hl]
		ld d, UP_SHOT_DIRECTION
		
		ld a, [player_orientation]
		or a
		jr z, .skip_transform
		ld a, c
		sub 7
		ld c, a
		.skip_transform:

	call_shot:
	push af
	call sys_sound_shoot_effect ;; Se llama aquí por tema de argumentos del preset
	pop af
	;Switch para decidir que bala se llama
	ld a,[player_bullet]
	ld hl,player_bullet_0_preset
	cp 0
	jr z,.fin_shot
	ld hl,player_bullet_1_preset
	cp 1
	jr z,.fin_shot
	ld hl,player_bullet_2_preset

	.fin_shot
	ld a, d
	ld d,h
	ld e,l
	call shot_bullet_for_preset


	ld a, COOLDOWN_SHOT_DELAY
	ld [shot_cooldown], a
	
	xor a
	ld [can_shot_flag], a

	exit:
	ret

; Init bullets sprites and variables
init_bullets::
	ld hl, bullet_0_h
	ld de, $8200 ; MAGIC
	ld b, 16     ; MAGIC
	call memcpy_256

	ld hl, bullet_0_v
	ld de, $8220 ; MAGIC
	ld b, 16     ; MAGIC
	call memcpy_256


	ld hl, bullet_1_h
	ld de, $8240 ; MAGIC
	ld b, 16     ; MAGIC
	call memcpy_256

	ld hl, bullet_1_v
	ld de, $8260 ; MAGIC
	ld b, 16     ; MAGIC
	call memcpy_256


	ld hl, bullet_2_h
	ld de, $8280 ; MAGIC
	ld b, 16     ; MAGIC
	call memcpy_256

	ld hl, bullet_2_v
	ld de, $82A0 ; MAGIC
	ld b, 16     ; MAGIC
	call memcpy_256

	xor a
	ld [shot_cooldown], a
	inc a
	ld [can_shot_flag], a
	ret
