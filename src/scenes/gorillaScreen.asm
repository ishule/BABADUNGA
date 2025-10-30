SECTION "Gorilla Screen",ROM0
include "consts.inc"
load_gorilla_screen::
      
   call turn_screen_off
   call init_common_data_screen
   
   call draw_map_gorilla
   call sys_sound_init_gorilla_music
   call init_gorilla
   
   call init_verja
   call init_stalactites
   call turn_screen_on
   
   call draw_hearts
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
      
      call check_screen_transition
      jp c,.game_loop 
      
      call player_is_dead
     .end
    ret