include "consts.inc"
SECTION "Entry point", ROM0[$150]

main::
   ld hl,rBGP
   ld [hl],%11100001
   call wait_vblank
   ld hl,map1Tiles
   ld de,$8010
   ld b, 4 * $10
   call memcpy_256
   call turn_screen_off
   call sys_sound_init
   call sys_sound_init_music
   ld hl,map1
   call draw_map
   call turn_screen_on
   call init_all_sprites
   call init_player
   call init_gorilla
   call open_door
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

   ;ld bc, $0081
   ;ld d, $02
   ;call change_entity_group_acc


   game_loop:
      call wait_vblank
      call man_entity_draw
      call sys_sound_siguienteNota

      call joypad_read
      call process_input
      call sys_gorilla_movement

      
      call compute_physics
      call bullet_update
      jr game_loop 

   di
   halt