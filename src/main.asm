;;----------LICENSE NOTICE-------------------------------------------------------------------------------------------------------;;
;;  This file is part of GBTelera: A Gameboy Development Framework                                                               ;;
;;  Copyright (C) 2024 ronaldo / Cheesetea / ByteRealms (@FranGallegoBR)                                                         ;;
;;                                                                                                                               ;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    ;;
;; files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy,    ;;
;; modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the         ;;
;; Softwareis furnished to do so, subject to the following conditions:                                                           ;;
;;                                                                                                                               ;;
;; The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.;;
;;                                                                                                                               ;;
;; THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          ;;
;; WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         ;;
;; COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   ;;
;; ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         ;;
;;-------------------------------------------------------------------------------------------------------------------------------;;
include "consts.inc"
SECTION "Entry point", ROM0[$150]

main::
   ;; Cambiar paleta
   ld hl,rBGP
   ld [hl],%11100001
   call wait_vblank
   ld hl,map1Tiles
   ld de,$8010
   ld b, 4 * $10 ;; Nº Tiles * Tamaño
   call memcpy_256
   call wait_vblank
   call turn_screen_off
   ld hl,map1
   call draw_map
   call turn_screen_on

   call init_all_sprites

   call init_player
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

      call joypad_read
      call process_input
      
      call compute_physics
      ;call bullet_update
      call man_entity_draw

      jr game_loop 


   di     ;; Disable Interrupts
   halt   ;; Halt the CPU (stop procesing here)
