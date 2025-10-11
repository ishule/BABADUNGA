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
   call wait_vblank
   call turn_screen_off
   call sys_sound_init
   call sys_sound_init_music
   ld hl,map1
   call draw_map
   call turn_screen_on
   call init_all_sprites
   call init_player
   call open_door
   call joypad_init

   game_loop:
      call wait_vblank
      call sys_sound_siguienteNota
      call joypad_read
      call player_update_movement
      call man_entity_draw
      jr game_loop 

   di
   halt