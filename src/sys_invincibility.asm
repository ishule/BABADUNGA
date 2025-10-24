INCLUDE "consts.inc"

SECTION "Invincibility System", WRAM0
; Jugador
player_invincibility_timer: DS 1
player_blink_timer: DS 1

; Boss
boss_invincibility_timer: DS 1
boss_blink_timer: DS 1


SECTION "Invincibility Code", ROM0

init_invincibility::
    xor a
    ld [player_invincibility_timer], a
    ld [player_blink_timer], a
    ld [boss_invincibility_timer], a
    ld [boss_blink_timer], a
    ret


update_invincibility::
    ; Actualizar jugador
    ld hl, CMP_START_ADDRESS        ; Offset jugador (0)
    ld de, player_invincibility_timer
    call update_entity_invincibility
    
    ; Actualizar boss
    ld a, TYPE_BOSS
    call man_entity_locate_first_type
    ld de, boss_invincibility_timer
    call update_entity_invincibility
    
    ret

; INPUT:
;   HL = offset de la entidad ($C0xx)
;   DE = dirección del timer de invencibilidad
update_entity_invincibility::
    push hl
    push de
    
    ; Cargar timer
    ld a, [de]
    cp 0
    jr z, .no_invincibility
    
    ; Decrementar
    dec a
    ld [de], a
    jr nz, .still_invincible
    
    ; ===== TERMINÓ INVENCIBILIDAD =====
    pop de
    pop hl
    push hl
    
    ; Reactivar flag
    inc l
    inc l               ; FLAGS
    set 0, [hl]
    
    ; Obtener número de sprites
    inc l               ; NUM_SPRITES
    ld a, [hl]
    ld b, a             ; B = número de sprites
    
    pop hl
    push hl
    
    ; Hacer todos los sprites visibles
    ld h, CMP_SPRITES_H
    
.restore_loop:
    push bc
    inc l
    inc l
    inc l               ; Atributos del sprite
    res 4, [hl]         ; Hacer visible
    pop bc
    
    inc l               ; Avanzar al siguiente sprite (4 bytes después del inicio)
    dec b
    jr nz, .restore_loop
    
    pop hl
    ret
    
.still_invincible:
    pop de
    push de
    
    ; Manejar parpadeo (DE+1 = blink_timer)
    inc de
    ld a, [de]
    dec a
    ld [de], a
    jr nz, .no_blink_yet
    
    ; Reiniciar blink timer
    ld a, 5
    ld [de], a
    
    ; Alternar visibilidad de TODOS los sprites
    pop de
    pop hl
    push hl
    
    ; Obtener número de sprites
    inc l
    inc l
    inc l               ; NUM_SPRITES
    ld a, [hl]
    ld b, a             ; B = número de sprites
    
    dec l
    dec l
    dec l               ; Volver al inicio
    
    ld h, CMP_SPRITES_H
    
.blink_loop:
    push bc
    inc l
    inc l
    inc l               ; Atributos del sprite
    ld a, [hl]
    xor %00010000       ; Alternar bit 4 (paleta)
    ld [hl], a
    pop bc
    
    inc l               ; Siguiente sprite
    dec b
    jr nz, .blink_loop
    
    pop hl
    ret
    
.no_blink_yet:
    pop de
    pop hl
    ret
    
.no_invincibility:
    pop de
    pop hl
    ret