INCLUDE "consts.inc"
INCLUDE "spider/spider_consts.inc"

SECTION "Spider Code", ROM0

spider_logic::
	; === Check shot cooldown ===
	ld a, [spider_shot_cooldown]
	cp 0
	jr z, .shot
	.decrease_cooldown:
	dec a
	ld [spider_shot_cooldown], a
	jr .do_not_shot

	.shot:
		ld a, ENEMY_START_ENTITY_ID
		call man_entity_locate_v2
		inc h
		ld b, [hl]
		inc l
		ld c, [hl]

		ld a, b
		add SPRITE_HEIGHT
		ld b, a

		ld a, c
		add SPRITE_WIDTH + SPRITE_WIDTH/2
		ld c, a

		ld de, spider_bullet_preset
		ld a, DOWN_SHOT_DIRECTION
		call shot_bullet_for_preset

		ld hl, spider_shot_cooldown
		ld [hl], SPIDER_ROOF_STATE_SHOT_COOLDOWN

	.do_not_shot:
	call move_spider_towards_player

	ret


move_spider_towards_player:
	; === READ PLAYER POS ===
	; Read body pos
	ld a, PLAYER_BODY_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	ld b, [hl]

	; Read gun pos
	ld a, PLAYER_GUN_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	ld a, [hl]

	; Compare to use middle
	cp b
	jr c, .use_player_body_pos

	.use_player_gun_pos:
		ld b, a

	.use_player_body_pos:

	; B = PLAYER_POS_MID

	; === READ SPIDER POS ===
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2
	inc h
	inc l
	ld a, [hl]
	add SPRITE_WIDTH*2 ; Calculate middle

	; A = SPIDER_POS_MID

	; === CHECK IF SAME POS ===
	cp b
	jr nz, .move
	.not_move:
	ld bc, 0
	jr .skip_conversion
	.move:

	; === CALCULATE DIRECTION ===
	ld bc, SPIDER_ROOF_SPEED
	; Player_pos < Spider_pos
	jr c, .skip_conversion
	call positive_to_negative_BC
	.skip_conversion:

	; MOVE TOWARDS PLAYER
	ld a, ENEMY_START_ENTITY_ID
	call man_entity_locate_v2

	ld d, SPIDER_ROOF_NUM_ENTITIES
	call change_entity_group_vel_x
	ret