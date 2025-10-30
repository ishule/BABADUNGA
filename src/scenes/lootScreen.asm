SECTION "Loot Screen",ROM0
include "consts.inc"

draw_map_loot::
   ld [loot_room],a
   bit 0,a
   jr z,.mapGorilla
   call draw_map_spider
   jr .fin
   .mapGorilla
   call draw_map_gorilla
   .fin
   ld a,[loot_room]
   inc a
   ld [loot_room],a
ret
load_loot_screen::
   xor a
   ld [lootFlag],a
   call turn_screen_off
   call clean_all_tiles
   ld a,[loot_room]

   call draw_map_loot
   call InitDmaCopy
   call sys_sound_init
   call sys_sound_init_rest_music

   call turn_screen_on
   call init_all_sprites

   call man_entity_init ; Inicializar gestor de entidades

   call init_player

   call init_verja
   call init_pickups

   call joypad_init

   call init_bullets
   call draw_hearts
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
   xor a
   ld [pickup_anim_timer], a
   ld [animation_flag],a

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
    ld b, $1C                 ; Tile ID
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
    ld [pickup_heart_orig_y],a
    ld [pickup_bullet_orig_y],a
    ld [hl], a
    inc hl
    ld b, 50 + 8              ; X Position
    ld a, b
    ld [hl], a
    inc hl
    ld b, $1D                 ; Tile ID
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
    ld b, 108                 ; Y Position
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
    ld b, %00100000
    ld [hl], b

        ; Sprite 2: Right Half (Tile $13)
    call man_entity_alloc     ; L=new offset, HL=C0xx+L

    ld h, CMP_SPRITES_H       ; HL = C1xx + L
    ld b, 108                 ; Y Position
    ld a, b
    ld [hl], a
    inc hl
    ld b, 120 +2               ; X Position
    ld a, b
    ld [hl], a
    inc hl
    ld b, $10                ; Tile ID
    ld a, b
    ld [hl], a
    inc hl
    ld b, %10100000           ; Attribute (Flip X?)
    ld a, b
    ld [hl], a              ; Write Attr

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
; =============================================
; pickup_animate
; Mueve los pickups arriba y abajo usando VELOCIDAD
; =============================================
.pickup_animate:
    ; --- 1. Gestionar el Contador de Duración Local ---
    ld hl, pickup_anim_timer
    ld a, [hl]
    inc a
    ld [hl], a                ; Incrementa el contador local CADA frame

    cp 40                      ; Compara: ¿Han pasado 8 frames?
    jp c,.pickup_collision                     ; Si A < 8, salta. La física mantiene la velocidad actual.

    ; Si A = 8 (o más), es hora de alternar la dirección.
    xor a
    ld [hl], a                ; Reinicia el temporizador local a 0

    ; --- 2. Alternar la Bandera de Dirección (Subir/Bajar) ---
    ld hl, animation_flag
    ld a, [hl]
    xor 1                     ; Alterna 0 <-> 1
    ld [hl], a                ; Guardar el nuevo estado (0 o 1)

    ; --- 3. Aplicar la VELOCIDAD basada en el estado actual ---
    ; ld a, [hl] ; A ya tiene el valor del animation_flag
    or a                      ; Comprobar si A es 0
    jr z, .offset_down

.offset_up:
    ; [animation_flag] = 1 (subir)
    ld bc, PICKUP_VEL_Y_NEG   ; BC = Velocidad de subida (ej. -$0040)
    jr .apply_offset_to_pickups

.offset_down:
    ; [animation_flag] = 0 (bajar)
    ld bc, PICKUP_VEL_Y       ; BC = Velocidad de bajada (ej. +$0040)

.apply_offset_to_pickups:
    ; BC contiene la velocidad Y.

    ; --- Animar el Corazón (IDs 4 y 5) ---
    ld a, 4                   ; *** ASUMIENDO QUE EL ID DEL CORAZÓN ES 4 ***
    call man_entity_locate_v2 ; HL = offset L para entidad 4
    ld d, 2                   ; *** D = Tamaño Grupo (2 sprites) ***
    ; BC ya tiene la velocidad
    call change_entity_group_vel_y ; <<< USAR VELOCIDAD

    ; --- Animar la Bala (IDs 6 y 7) ---
    ld a, 6                   ; *** ASUMIENDO QUE EL ID DE LA BALA ES 6 ***
    call man_entity_locate_v2 ; HL = offset L para entidad 6
    ld d, 2                   ; *** D = Tamaño Grupo (2 sprites) ***
    ; BC ya tiene la velocidad
    call change_entity_group_vel_y ; <<< USAR VELOCIDAD

    
.pickup_collision:
.pickup_heart:
   ld a,PLAYER_BODY_ENTITY_ID
   call man_entity_locate_v2

   ld h,CMP_SPRITES_H
   ld a,[hl+] ; Y
   

   cp 105
   jr nc,.pickup_bullet

   ld a,[hl] ; X
   cp 50
   jr c,.pickup_bullet

   cp 59
   jr nc,.pickup_bullet
   jr .apply_heart_effect

.pickup_bullet:
   ld a,PLAYER_BODY_ENTITY_ID
   call man_entity_locate_v2

   ld h,CMP_SPRITES_H
   ld a,[hl+] ; Y
   

   cp 105
   jr nc,.no_collision

   ld a,[hl] ; X
   cp 120
   jr c,.no_collision

   cp 129
   jr nc,.no_collision
   jr .apply_bullet_effect

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
    ld a,[player_bullet]
    inc a
    ld [player_bullet],a

    call sys_sound_pickup_effect
    ; Fall through to delete

.delete_collided_pickup:
   ld a,4
   call man_entity_delete

   ld a,4
   call man_entity_delete
   ld a,4
   call man_entity_delete
      ld a,4
   call man_entity_delete
   call open_door
   ld a,[lootFlag]
   set 0,a
   ld [lootFlag],a


    ret                     ; Exit callback for this (now deleted) powerup

.no_collision:
    ret                     ; No collision, continue foreach loop


SECTION "Loot Flag",WRAM0
lootFlag: ds 1

pickup_heart_orig_y::
    ds 1            ; Posición Y original del corazón (sprite principal)

pickup_bullet_orig_y::
    ds 1            ; Posición Y original de la bala (sprite principal)

animation_flag: ds 1

pickup_anim_timer::
    ds 1

loot_room:: ds 1

; Si tienes muchos pickups, esto se haría mejor con un array en tu sistema de entidades,
; pero para 2 tipos específicos, unas variables directas funcionan bien.

DEF PICKUP_VEL_Y equ $0020       ; Velocidad de bajada (+0.25)
DEF PICKUP_VEL_Y_NEG equ $FFE0   ; Velocidad de subida (-0.25)