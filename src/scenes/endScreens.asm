SECTION "End Screens",ROM0
include "consts.inc"
load_defeat_screen::
	
   ld hl,rBGP
   ld [hl],%11100001
   	call turn_screen_off

   	call clean_all_tiles
   	call init_OAM
   	call sys_sound_init
   	call sys_sound_init_defeat_music
	
	call init_defeat_screen
	call joypad_init
	call turn_screen_on
	.loop:
		;ld b,3
		call wait_vblank
		call sys_sound_siguienteNota
		call joypad_read
		; Comprobar si se presionó START
		ld a, [joypad_input]
		bit JOYPAD_START, a       ; Comprobar bit 7 (START)
		jr z, .loop               ; Si no está presionado, continuar loop
	ret

load_win_screen::
	call turn_screen_off

   	call clean_all_tiles
	call init_OAM
   	call sys_sound_init
   	call sys_sound_init_victory_music
	
	call init_win_screen
	call joypad_init
	call turn_screen_on
	.loop:
		;ld b,3
		call wait_vblank
		call sys_sound_siguienteNota
		call joypad_read
		; Comprobar si se presionó START
		ld a, [joypad_input]
		bit JOYPAD_START, a       ; Comprobar bit 7 (START)
		jr z, .loop               ; Si no está presionado, continuar loop
	ret