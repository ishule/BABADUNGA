SECTION "Title Screen",ROM0
include "consts.inc"
load_title_screen::
	
   	call turn_screen_off
   	call sys_sound_init
   	call sys_sound_init_inicio_music
	call init_title_screen
	call draw_title_screen
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