SECTION "Snake Screen",ROM0
include "consts.inc"
load_snake_screen::

   
   call turn_screen_off
   call clean_all_tiles
   call draw_map_snake
   
   call InitDmaCopy
   call sys_sound_init
   call sys_sound_init_snake_music
   
   call turn_screen_on
   call init_all_sprites

   call man_entity_init ; Inicializar gestor de entidades

   call init_player
   call init_snake
   call init_verja
   call init_invincibility
   call joypad_init
   call init_bullets
   
   ld a,[player_total_health]
   ld [player_health],a
   call draw_hearts
   .game_loop:
      call wait_vblank
      call man_entity_draw
      call sys_sound_siguienteNota

      call joypad_read
      call process_input

      call update_invincibility
      call sys_collision_check_all

      call sys_snake_movement
      
      call compute_physics
      call check_player_shot
      ;call sys_blink_update
      call draw_hearts
      
      call sys_collision_check_all
      call check_screen_transition
      jp c,.game_loop

      call player_is_dead
    .end
    ret