include "consts.inc"
SECTION "Entry point", ROM0[$150]

main::
   ld hl,rBGP
   ld [hl],%11100001
   ;jp provisional_game_loop
   
   call turn_screen_off
   ld hl,map1Tiles
   ld de,$8000
   ld b, 12 * $10
   call memcpy_256
   
   call InitDmaCopy
   call sys_sound_init
   call sys_sound_init_snake_music
   ld hl,map1
   call draw_map
   call turn_screen_on
   call init_all_sprites

   call man_entity_init ; Inicializar gestor de entidades
   call man_collision_init ; Inicializar array de colisiones
   call man_collision_create_all_collisions  ; Crear colisiones de arena (PROVISIONAL, SE DEBERIA CREAR UNO PARA CADA ESCENA)

   call init_player

   call init_gorilla
   ;call init_snake
   ;call init_spider
   call init_verja
   call init_invincibility
   ;call open_door Esto se llama una vez el boss ha muerto
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

   ;ld bc, $0001
   ;ld d, $02
   ;call change_entity_group_acc


   game_loop:
      call wait_vblank
      call man_entity_draw
      call sys_sound_siguienteNota

      call joypad_read
      call process_input

      call update_invincibility
      call sys_collision_check_all
      ;call sys_gorilla_movement
      ;call sys_snake_movement
      ;call spider_logic
      
      call compute_physics
      call check_player_shot

      jr game_loop 

   di
   halt


   provisional_game_loop:
      call load_title_screen
      call load_gorilla_screen
      call load_snake_screen
      call load_spider_screen
      .victory
      call load_win_screen
      jp .end
   .defeat
      call load_defeat_screen
   .end
      jr provisional_game_loop

   ;; SI EL JUGADOR LLEGA A LA DERECHA (HAY QUE AJUSTARLO MÁS ADELANTE) SE PASA A LA SIGUIENTE PANTALLA
   ;; ESTA FUNCIÓN SE LLAMA DESDE CADA ESCENA
   check_screen_transition::
    ; 1. Get player's X position
    ld a, PLAYER_BODY_ENTITY_ID ; Player's main sprite ID
    call man_entity_locate_v2   ; HL points to player's $C0xx
    ld h, CMP_SPRITES_H         ; Switch HL to point to $C1xx
    inc l                       ; Point to PosX
    ld a, [hl]                  ; A = Player's current X position

    ; 2. Compare with the gorilla's right turning point
    cp 120
    jr c, .no_transition        ; If PlayerX < Limit, continue loop

    ; 3. Player has reached or passed the limit, end this screen's loop
    jp .end_gorilla_screen      ; Jump out of the game loop

   .no_transition:
      scf
      ret                         ; Continue game loop

   .end_gorilla_screen:  ;; AÑADIR SCREEN FADE
    or a ;;Limpamos carry
    ; (Optional: Add screen fade out or other transition effects here)
    ret                         ; Return from load_gorilla_screen