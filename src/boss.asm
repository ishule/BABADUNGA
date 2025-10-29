INCLUDE "consts.inc"

def ENTER_STATE equ $00
def DEAD_STATE equ $FF

SECTION "General boss variables", WRAM0
boss_looking_dir:: ds 1 ; 0:rigth | 1:left
boss_health: ds 1 
boss_dead:: ds 1 ; 0:alive | 1:dead

boss_state_counter::     DS 1
boss_animation_counter:: DS 1 
boss_stage::             DS 1 ; 0:fase 0 | 1:fase 1
boss_state::             DS 1
SECTION "General boss code", ROM0

; INPUT 
;  e -> dead animation timer
;  d -> num_entities
; RETURN
;  flags c: boss died
check_dead_state:
    ld a, [boss_state]
    cp DEAD_STATE
    ret z

    ld a, [boss_health]
    or a
    ret nz
    
    ld hl, boss_state_counter
    ld [hl], e
    
    push de
    call reset_group_vel
    pop de
    call reset_group_acc

    scf
    ret

; RETURN
;  a -> entity id
take_mid_boss_entity::
	ld a, [boss_looking_dir]
    or a
    jr nz, .looking_left
    .looking_right:
        ld a, ENEMY_START_ENTITY_ID + 4
        ret
    .looking_left:
        ld a, ENEMY_START_ENTITY_ID + 1
        ret

; RETURN
;  flags -> c:not_on_ground | nc:on_ground
check_ground_for_boss::
    ld a, ENEMY_START_ENTITY_ID + 2
    call man_entity_locate_v2
    inc h
    inc h
    inc h
    ld a, [hl]
    bit 7, a
    jr z, .falling
    scf
    ret

    .falling:
    dec h
    dec h
    ld a, [hl]
    cp GROUND_Y
    ret

; INPUT
;  a -> mid_entity_id
; RETURN
;  
check_wall_for_boss::
    call man_entity_locate_v2
    inc h
    inc l
    ld c, [hl]
    ld a, [boss_looking_dir]
    or a
    jr nz, .looking_left
    .looking_right:
        ld a, c
        add SPRITE_WIDTH*2
        ld c, WALL_RIGHT_X
        cp c
        ret

    .looking_left:
        ld a, c
        sub SPRITE_WIDTH*2
        ld c, a
        ld a, WALL_LEFT_X
        cp c
        ret

; ======= ANIMATIONS =========
; INPUT
;  b -> swap_mask
;  c -> num_entities
;  a -> entity_id
swap_sprite_by_mask::
    ld de, CMP_SIZE
    ; Llamar desde fuera
    ;add ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    inc h
    inc l
    inc l
    .loop:
        ld a, [hl]
        xor b
        ld [hl], a

        add hl, de
        dec c
        jr nz, .loop

    ret

; INPUT
;  c-> num_entities
rotate_boss_x::
    ;Llamar desde fuera
    ;ld c, GORILLA_NUM_ENTITIES
    ld a, ENEMY_START_ENTITY_ID
    call flip_boss_x
    call swap_x_boss_entity

    ld a, [boss_looking_dir]
    xor 1
    ld [boss_looking_dir], a

    ret

; INPUT
;  c-> num_entities
rotate_boss_y::
    ld a, ENEMY_START_ENTITY_ID
    call flip_boss_y
    call swap_y_boss_entity

    ret

; INPUT
;  c -> num_entities
;  a -> entity_id
flip_boss_x::
    call man_entity_locate_v2
    inc h
    inc l
    inc l
    inc l
    
    .loop:
        ld a, [hl]
        xor SPRITE_ATTR_FLIP_X_MASK
        ld [hl], a       
         
        ld de, CMP_SIZE
        add hl, de

        dec c
        jr nz, .loop

    ret

; INPUT
;  c -> num_entities
;  a -> entity_id
flip_boss_y::
    call man_entity_locate_v2
    inc h
    inc l
    inc l
    inc l
    
    .loop:
        ld a, [hl]
        xor SPRITE_ATTR_FLIP_Y_MASK
        ld [hl], a       
         
        ld de, CMP_SIZE
        add hl, de

        dec c
        jr nz, .loop

    ret

swap_x_right_half_boss_entity::
    ld a, ENEMY_START_ENTITY_ID + 4
    call man_entity_locate_v2
    ld d, h
    ld e, l

    ld a, ENEMY_START_ENTITY_ID + 5
    call man_entity_locate_v2

    call swap_2_entities_positions 

    ld a, ENEMY_START_ENTITY_ID + 6
    call man_entity_locate_v2
    ld d, h
    ld e, l

    ld a, ENEMY_START_ENTITY_ID + 7
    call man_entity_locate_v2

    call swap_2_entities_positions 
    ret

swap_x_boss_entity::
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld d, h
    ld e, l

    ld a, ENEMY_START_ENTITY_ID + 5
    call man_entity_locate_v2

    call swap_2_entities_positions

    ld a, ENEMY_START_ENTITY_ID + 1
    call man_entity_locate_v2
    ld d, h
    ld e, l

    ld a, ENEMY_START_ENTITY_ID + 4
    call man_entity_locate_v2

    call swap_2_entities_positions 

    ld a, ENEMY_START_ENTITY_ID + 2
    call man_entity_locate_v2
    ld d, h
    ld e, l

    ld a, ENEMY_START_ENTITY_ID + 7
    call man_entity_locate_v2

    call swap_2_entities_positions 

    ld a, ENEMY_START_ENTITY_ID + 3
    call man_entity_locate_v2
    ld d, h
    ld e, l

    ld a, ENEMY_START_ENTITY_ID + 6
    call man_entity_locate_v2

    call swap_2_entities_positions 

    ret


swap_y_boss_entity::
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld d, h
    ld e, l

    ld a, ENEMY_START_ENTITY_ID + 2
    call man_entity_locate_v2

    call swap_2_entities_positions

    ld a, ENEMY_START_ENTITY_ID + 1
    call man_entity_locate_v2
    ld d, h
    ld e, l

    ld a, ENEMY_START_ENTITY_ID + 3
    call man_entity_locate_v2

    call swap_2_entities_positions 

    ld a, ENEMY_START_ENTITY_ID + 4
    call man_entity_locate_v2
    ld d, h
    ld e, l

    ld a, ENEMY_START_ENTITY_ID + 6
    call man_entity_locate_v2

    call swap_2_entities_positions 

    ld a, ENEMY_START_ENTITY_ID + 5
    call man_entity_locate_v2
    ld d, h
    ld e, l

    ld a, ENEMY_START_ENTITY_ID + 7
    call man_entity_locate_v2

    call swap_2_entities_positions 

    ret

; INPUT
;  HL -> collisions preset address
;  C  -> Entity size
change_boss_collisions::
    push hl
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    ld d, h
    ld e, l
    pop hl
    ld d, CMP_COLLISIONS_H
    
    .loop:
    ld b, CMP_SIZE
    call memcpy_256

    dec c
    jr nz, .loop

    ret


;; INPUT 
;;  d -> num_entities
;;  e -> damage
init_boss_info:: 
    ld a, ENEMY_START_ENTITY_ID
    call man_entity_locate_v2
    
    ;; Gorilla INFO 
    ld b, d
    .info_loop:
        ld a, BYTE_ACTIVE
        ld [hl+], a         ; Active = 1

        ld a, TYPE_BOSS
        ld [hl+], a         ; Type = 1

        ld a, [hl]                     ; carga el byte actual
        or FLAG_CAN_TAKE_DAMAGE | FLAG_CAN_DEAL_DAMAGE
        ld [hl+], a                     ; guarda el nuevo valor

        ld a, d
        ld [hl], a  ; Número sprites

        inc h
        inc h
        ld [hl], e
        dec h
        dec h
        inc l

        dec b 
        jr nz, .info_loop 
    

    ld hl, boss_dead
    ld [hl], 0

    ld hl, boss_stage
    ld [hl], 0

    ret