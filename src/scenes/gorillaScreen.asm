SECTION "Gorilla Screen",ROM0
include "consts.inc"
load_gorilla_screen::

   call turn_screen_off
   call clean_all_tiles
   ld hl,map1Tiles
   ld de,$8000
   ld b, 12 * $10
   call memcpy_256
   
   call InitDmaCopy
   call sys_sound_init
   call sys_sound_init_gorilla_music
   ld hl,map1
   call draw_map
   call turn_screen_on
   call init_all_sprites

   call man_entity_init ; Inicializar gestor de entidades

   call init_player
   call init_gorilla
   call init_verja
   call init_invincibility
   call joypad_init

   call init_bullets
   ld a,2
   ld [boss_health],a
   .game_loop:
      call wait_vblank
      call man_entity_draw
      call sys_sound_siguienteNota

      call joypad_read
      call process_input
      
      call update_invincibility
      call sys_collision_check_all

      call sys_gorilla_movement
      
      call compute_physics
      call check_player_shot
      ;call sys_blink_update
      call draw_hearts
      call player_is_dead
      ld b,8
      call boss_is_dead
      call check_screen_transition
      jp c,.game_loop 
      
      call player_is_dead
     .end
    ret