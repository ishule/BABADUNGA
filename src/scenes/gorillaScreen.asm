SECTION "Gorilla Screen",ROM0
include "consts.inc"
load_gorilla_screen::
   call wait_vblank
   ld hl,map1Tiles
   ld de,$8010
   ld b, 4 * $10
   call memcpy_256
   call turn_screen_off
   call clean_all_tiles
   
   call InitDmaCopy
   call sys_sound_init
   call sys_sound_init_gorilla_music
   ld hl,map1
   call draw_map
   call turn_screen_on
   call init_all_sprites

   call man_entity_init ; Inicializar gestor de entidades
   call man_collision_init ; Inicializar array de colisiones
   call man_collision_create_all_collisions  ; Crear colisiones de arena (PROVISIONAL, SE DEBERIA CREAR UNO PARA CADA ESCENA)

   call init_player
   call init_gorilla
   call joypad_init

   call init_bullets


   .game_loop:
      call wait_vblank
      call man_entity_draw
      call sys_sound_siguienteNota

      call joypad_read
      call process_input
      call sys_gorilla_movement
      
      call compute_physics
      call check_player_shot
      ;call sys_blink_update

      ;call sys_collision_check_all
      call joypad_read
		; Comprobar si se presionó START
	  ld a, [joypad_input]
	  bit JOYPAD_START, a       ; Comprobar bit 7 (START)
	  jr z, .game_loop               ; Si no está presionado, continuar loop

      jp game_loop 
    ret