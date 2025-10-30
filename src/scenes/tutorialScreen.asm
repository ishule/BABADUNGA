SECTION "Tutorial Screen",ROM0
include "consts.inc"

load_tutorial_screen::
   call init_player_stats

   call turn_screen_off
   call init_common_data_screen

   call draw_map_snake
   call sys_sound_init_rest_music

   call init_verja
   call turn_screen_on

   
   call open_door

   call draw_hearts
   .game_loop:
      call wait_vblank
      call man_entity_draw
      call sys_sound_siguienteNota

      call joypad_read
      call process_input

      call sys_collision_check_all
      
      call update_invincibility
      call sys_collision_check_all
      call draw_hearts

      call compute_physics
      call check_player_shot
      ;call sys_blink_update

      ;call sys_collision_check_all
      call check_screen_transition
      jp c,.game_loop 
     .end
    ret