SECTION "Loot Screen",ROM0
include "consts.inc"

load_loot_screen::
   xor a
   ld [lootFlag],a
   call turn_screen_off
   call clean_all_tiles
   ld hl,map1Tiles
   ld de,$8000
   ld b, 12 * $10
   call memcpy_256
   
   call InitDmaCopy
   call sys_sound_init
   call sys_sound_init_rest_music
   ld hl,map1
   call draw_map
   call turn_screen_on
   call init_all_sprites

   call man_entity_init ; Inicializar gestor de entidades

   call init_player

   call init_verja
   call init_pickups

   call joypad_init

   call init_bullets

   .game_loop:
      call wait_vblank
      call man_entity_draw
      call sys_sound_siguienteNota

      call joypad_read
      call process_input

      call sys_collision_check_all
      
      
      call compute_physics
      call check_player_shot
      call player_pickup
      call draw_hearts
      call check_screen_transition
      jp c,.game_loop 
     .end
    ret


SECTION "Pickup Code", ROM0


; =============================================
; init_pickups
; Creates pickups, including setting collision dimensions.
; CORRECTED to use valid Game Boy instructions.
; MODIFICA: AF, BC, DE, HL
; =============================================
init_pickups::

    ; --- Heart Pickup (Two Sprites, treat collision as one 16x8 block) ---
    ; Sprite 1: Left Half (Tile $12)
    call man_entity_alloc     ; L=offset, HL=C0xx+L
    push hl                   ; Save Info Ptr
    ld a, l                   ; Keep offset in A for later components

    ; Set Info: Active=1, Type=POWERUP
    ld [hl], BYTE_ACTIVE
    inc l
    ld b, TYPE_POWERUP      ; Use B temporarily
    ld a, b                 ; *** Load B into A ***
    ld [hl], a              ; Set Type
    ; ** HL still points to Type byte **

    ; Set Sprite Data: Y, X, Tile, Attr
    pop hl                    ; HL = C0xx + L (Info address)
    ld h, CMP_SPRITES_H       ; HL = C1xx + L (Sprite address)
    ld b, 105                 ; Y Position
    ld a, b                 ; *** Load B into A ***
    ld [hl], a              ; Write Y
    inc hl                    ; *** Manually increment HL ***
    ld b, 50                  ; X Position
    ld a, b                 ; *** Load B into A ***
    ld [hl], a              ; Write X
    inc hl                    ; *** Manually increment HL ***
    ld b, $12                 ; Tile ID
    ld a, b                 ; *** Load B into A ***
    ld [hl], a              ; Write Tile
    inc hl                    ; *** Manually increment HL ***
    xor a                     ; Attribute = 0 (A is already 0, but xor is safer)
    ld [hl], a              ; Write Attr

    ; Sprite 2: Right Half (Tile $13)
    call man_entity_alloc     ; L=new offset, HL=C0xx+L

    ld h, CMP_SPRITES_H       ; HL = C1xx + L
    ld b, 105                 ; Y Position
    ld a, b
    ld [hl], a
    inc hl
    ld b, 50 + 8              ; X Position
    ld a, b
    ld [hl], a
    inc hl
    ld b, $13                 ; Tile ID
    ld a, b
    ld [hl], a
    inc hl
    ld b, %10100000           ; Attribute (Flip X?)
    ld a, b
    ld [hl], a              ; Write Attr


    ; --- Bullet Pickup (One Sprite, treat as 8x8) ---
    call man_entity_alloc     ; L=new offset, HL=C0xx+L
    push hl                   ; Save Info Ptr
    ld a, l                   ; Keep offset

    ; Set Info: Active=1, Type=POWERUP
    ld [hl], BYTE_ACTIVE
    inc l
    ld b, TYPE_POWERUP
    ld a, b
    ld [hl], a

    ; Set Sprite Data: Y, X, Tile, Attr
    pop hl                    ; HL = C0xx + L
    ld h, CMP_SPRITES_H       ; HL = C1xx + L
    ld b, 100                 ; Y Position
    ld a, b
    ld [hl], a
    inc hl
    ld b, 120                 ; X Position
    ld a, b
    ld [hl], a
    inc hl
    ld b, $10                 ; Tile ID
    ld a, b
    ld [hl], a
    inc hl
    ld b, %10100000
    ld [hl], b

    ret

    ; =============================================
; player_pickups
; Si el jugador está en la posición del corazón se lleva el corazón e igual con la bala
; MODIFICA: AF, BC, DE, HL (and potentially player_health, player_ammo)
; =============================================
player_pickup::
   ld a,[lootFlag]
   cp 0
   ret nz
; --- Internal Callback for foreach loop ---
.pickup_collision:
   ld a,PLAYER_BODY_ENTITY_ID
   call man_entity_locate_v2

   ld h,CMP_SPRITES_H
   ld a,[hl+] ; Y
   

   cp 105
   jr nc,.no_collision

   ld a,[hl] ; X
   cp 50
   jr c,.no_collision

   cp 59
   jr nc,.no_collision

.apply_heart_effect:
   ;Action: Increase Health by 2 ( 1 heart)
   ld a,[player_health]
   inc a
   inc a
   ld [player_health],a
    ; (Optional: Play sound)
    call sys_sound_pickup_effect
    jr .delete_collided_pickup

.apply_bullet_effect:
    ; Action: Change ammo


    call sys_sound_pickup_effect
    ; Fall through to delete

.delete_collided_pickup:
   ld a,3
   call man_entity_delete

   ld a,3
   call man_entity_delete
   ld a,3
   call man_entity_delete
   ld a,3
   call man_entity_delete

   ld a,3
   call man_entity_delete

   ld a,[lootFlag]
   set 0,a
   ld [lootFlag],a

    ret                     ; Exit callback for this (now deleted) powerup

.no_collision:
    ret                     ; No collision, continue foreach loop


SECTION "Loot Flag",WRAM0
lootFlag: ds 1