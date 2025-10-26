include "consts.inc"
SECTION "Entry point", ROM0[$150]

main::
   ld hl,rBGP
   ld [hl],%11100001
   jp provisional_game_loop
   
   call turn_screen_off
   ld hl,map1Tiles
   ld de,$8000
   ld b, 12 * $10
   call memcpy_256
   
   call InitDmaCopy
   call sys_sound_init
   call sys_sound_init_snake_music
   ld hl,map1
   call draw_map
   call turn_screen_on
   call init_all_sprites

   call man_entity_init ; Inicializar gestor de entidades
   
   call init_player
   call init_gorilla
   ;call init_snake
   ;call init_spider
   ;call init_verja
   call init_invincibility

   ;call open_door Esto se llama una vez el boss ha muerto
   call joypad_init

   call init_bullets


   ;debug
   ;ld a, $00
   ;call man_entity_locate
   
   ;ld bc, $8A0A
   ;ld d, $02
   ;call change_entity_group_pos
   
   ;ld a, $00
   ;call man_entity_locate

   ;ld bc, $0001
   ;ld d, $02
   ;call change_entity_group_acc


   game_loop:
      call wait_vblank
      call man_entity_draw
      call sys_sound_siguienteNota

      call joypad_read
      call process_input

      call update_invincibility

      call sys_collision_check_all
      call sys_gorilla_movement
      ;call sys_snake_movement
      ;call spider_logic
      
      call compute_physics
      call check_player_shot

      jr game_loop 

   di
   halt


   provisional_game_loop:
      call init_player_stats
      call load_title_screen
      call load_tutorial_screen
      call load_gorilla_screen
      jr c,.defeat
      call load_loot_screen
      call load_snake_screen
      jr c,.defeat
      call load_loot_screen
      call load_spider_screen
      jr c,.defeat
      .victory
      call load_win_screen
      jp .end
   .defeat
      call load_defeat_screen
   .end
      jr provisional_game_loop


   init_player_stats::
      ld a,2
      ld [player_health],a
      ret
   init_snake_stats::
      xor a
      ld [boss_player_dead],a
      ld a,1
      ld [boss_health],a
      ret
   ;; b = boss size (de momento nada)
   ;;al borrar la verja se borra todo y/o pasan cosas rarisimas
   boss_is_dead::
      ld a,[boss_health]
      cp 0
      ret nz
      ld a ,[boss_player_dead]
      bit 0,a
      ret nz
      set 0,a ; Para que solo entre aquí una vez
      ld [boss_player_dead],a


      call boss_dies_animation
      ; Desactivamos y desplazamos al boss
      call kill_boss

      ld c,14
      .waitLoop
      call wait_time_vblank_24
      dec c
      jr z,.waitLoop

      ;Quitar verja derecha
      call open_door 

      ret

   kill_boss::
      ;Desactivar y desplazar boss
      ld a,TYPE_BOSS
      ld de,_deactivate_and_move_boss_callback
      call man_entity_foreach_type
      ret


; =============================================
; _deactivate_and_move_boss_callback
; Callback function for man_entity_foreach_type.
; Sets the boss entity to inactive and moves ALL its sprites off-screen.
; INPUT: A = Boss Entity ID, DE = Address of Boss Info Component ($C0xx)
; MODIFIES: AF, BC, HL (Memory at boss entity addresses)
; =============================================
_deactivate_and_move_boss_callback:
    ; --- 1. Deactivate the entity ---
    ; DE already points to the Info component ($C0xx + L)
    xor a                     ; A = 0 (Inactive value)
    ld [de], a                ; Set ACTIVE flag to 0

    ; --- 2. Move the sprite(s) off-screen ---
    ; Calculate address of Sprite Component Y position
    ld h, d                   ; Copy $C0xx pointer to HL
    ld l, e
    inc h                     ; HL now points to Sprite Component ($C1xx + L)

    ; Get the number of sprites this boss uses
    push af                   ; Save A (which is 0)
    push hl                   ; Save Sprite Ptr ($C1xx + L)
    ld h, d                   ; Go back to Info Ptr ($C0xx + L)
    ld l, e
    inc l                     ; Point to Type
    inc l                     ; Point to Flags
    inc l                     ; Point to num_sprites
    ld c, [hl]                ; C = number of sprites boss uses (Use C as counter)
    pop hl                    ; Restore Sprite Ptr ($C1xx + L)
    pop af                    ; Restore A (which is 0)

    ; Loop through all sprites of the boss
.move_sprite_loop:
    push bc                   ; Save sprite counter (C) before potentially modifying BC
    ld a, 200                 ; Y value far off-screen
    ld [hl], a                ; Write new Y position
    ; Advance HL to the next sprite's Y position
    ld bc, CMP_SIZE           ; Size of one component entry (4 bytes)
    add hl, bc                ; HL += 4
    pop bc                    ; Restore sprite counter (C)
    dec c                     ; Use DEC C
    jr nz, .move_sprite_loop

    ret

   player_is_dead::
      ld a,[player_health]
      cp 0
      ret nz
      call player_dies_animation

      scf
      ret

      


   ;; SI EL JUGADOR LLEGA A LA DERECHA (HAY QUE AJUSTARLO MÁS ADELANTE) SE PASA A LA SIGUIENTE PANTALLA
   ;; ESTA FUNCIÓN SE LLAMA DESDE CADA ESCENA
   check_screen_transition::
    ; 1. Get player's X position
    ld a, PLAYER_BODY_ENTITY_ID ; 's main sprite ID
    call man_entity_locate_v2   ; HL points to player's $C0xx
    ld h, CMP_SPRITES_H         ; Switch HL to point to $C1xx
    inc l                       ; Point to PosX
    ld a, [hl]                  ; A = Player's current X position

    ; 2. Compare with the gorilla's right turning point
    cp 150
    jr c, .no_transition        ; If PlayerX < Limit, continue loop

    ; 3. Player has reached or passed the limit, end this screen's loop
    jp .end_screen      ; Jump out of the game loop

   .no_transition:
      ld a,[player_health]
      cp 0
      jr z,.die_player
      scf
      ret                         ; Continue game loop

   .end_screen:  ;; AÑADIR SCREEN FADE
    call wipe_out_right
    ; Esperar unos frames extra para asegurar
    ld b, 10
.extra_wait:
    call wait_vblank
    dec b
    jr nz, .extra_wait
    
    ; Ahora sí, señalizar que se debe cambiar de pantalla
    or a                        ; Limpiar carry (salir del game loop)
    ret
.die_player
   or a
   ret
