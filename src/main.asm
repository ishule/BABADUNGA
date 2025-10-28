include "consts.inc"
SECTION "Entry point", ROM0[$150]

main::
   ld hl,rBGP
   ld [hl],%11100001
   jp game_loop
   game_loop:

      call init_player_stats
      ; ======== DEBUG =========
      call load_snake_screen
      ;call load_spider_screen
      ; =======================
      call load_title_screen
      call load_tutorial_screen
      call load_gorilla_screen
      jr c,.defeat
      call load_loot_screen
      call load_snake_screen
      jr c,.defeat
      call load_loot_screen
      call load_spider_screen
      jr c,.defeat
      .victory
      call load_win_screen
      jp .end
   .defeat
      call load_defeat_screen
   .end
      jr game_loop


   init_player_stats::
      xor a
      ld [player_bullet],a
      ld a,6
      ld [player_health],a
      ret


   boss_is_dead::
      ld a, [boss_dead]
      or a
      ret z

      ; TODO LO QUE TENGA QUE PASAR AL ACABAR LA ANIMACION DE MUERTE
      call open_door
      
      ret

   player_is_dead::
      ld a,[player_health]
      cp 0
      ret nz
      call player_dies_animation

      scf
      ret

      


   ;; SI EL JUGADOR LLEGA A LA DERECHA (HAY QUE AJUSTARLO MÁS ADELANTE) SE PASA A LA SIGUIENTE PANTALLA
   ;; ESTA FUNCIÓN SE LLAMA DESDE CADA ESCENA
   check_screen_transition::
    ; 1. Get player's X position
    ld a, PLAYER_BODY_ENTITY_ID ; 's main sprite ID
    call man_entity_locate_v2   ; HL points to player's $C0xx
    ld h, CMP_SPRITES_H         ; Switch HL to point to $C1xx
    inc l                       ; Point to PosX
    ld a, [hl]                  ; A = Player's current X position

    ; 2. Compare with the gorilla's right turning point
    cp 150
    jr c, .no_transition        ; If PlayerX < Limit, continue loop

    ; 3. Player has reached or passed the limit, end this screen's loop
    jp .end_screen      ; Jump out of the game loop

   .no_transition:
      ld a,[player_health]
      cp 0
      jr z,.die_player
      scf
      ret                         ; Continue game loop

   .end_screen:  ;; AÑADIR SCREEN FADE
    call wipe_out_right
    ; Esperar unos frames extra para asegurar
    ld b, 10
.extra_wait:
    call wait_vblank
    dec b
    jr nz, .extra_wait
    
    ; Ahora sí, señalizar que se debe cambiar de pantalla
    or a                        ; Limpiar carry (salir del game loop)
    ret
.die_player
   or a
   ret
