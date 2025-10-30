SECTION "Spider Screen",ROM0
include "consts.inc"
load_spider_screen::
	 
  call turn_screen_off
  call init_common_data_screen


  call draw_map_spider
  call sys_sound_init_spider_music
  call init_spider

  call init_verja
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

      call spider_logic
      
      call compute_physics
      call check_player_shot
      ;call sys_blink_update
      call draw_hearts
      ;call sys_collision_check_all
      call check_screen_transition
      jp c,.game_loop
    .end
      call player_is_dead
    ret