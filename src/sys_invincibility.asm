INCLUDE "consts.inc"

SECTION "Invincibility System", WRAM0
invincibility_timer: DS 1    ; Contador de frames de invencibilidad
blink_timer: DS 1            ; Contador para parpadeo

SECTION "Invincibility Code", ROM0

init_invincibility::
    xor a                       ; A = 0
    ld [invincibility_timer], a
    ld [blink_timer], a
    ret

update_invincibility::
    ; Verificar si hay invencibilidad activa
    ld a, [invincibility_timer]
    cp 0
    ret z               ; No hay invencibilidad, salir
    
    ; Decrementar timer
    dec a
    ld [invincibility_timer], a
    
    ; Si llegó a 0, reactivar daño
    jr nz, .still_invincible
    
    ; ===== INVENCIBILIDAD TERMINADA =====
    
    ; Reactivar flag de daño
    ld hl, CMP_START_ADDRESS
    inc l 
    inc l               ; FLAGS
    set 0, [hl]         ; FLAG_CAN_TAKE_DAMAGE = 1

    ld a, l 
    add 4 
    ld l, a 
    set 0, [hl]         ; FLAG_CAN_TAKE_DAMAGE = 1
    
    ; IMPORTANTE: Hacer TODOS los sprites del jugador visibles
    ld hl, CMP_SPRITES_ADDRESS
    inc l 
    inc l 
    inc l               ; Sprite 0 - atributos
    res 4, [hl]         ; Hacer visible
    
    ld a, l 
    add 4 
    ld l, a              ; Sprite 1 - atributos          
    res 4, [hl]         ; Hacer visible
    
    ret
    
.still_invincible:
    ; Manejar parpadeo
    ld a, [blink_timer]
    dec a
    ld [blink_timer], a
    ret nz              ; Aún no toca parpadear
    
    ; Reiniciar contador de parpadeo
    ld a, 5
    ld [blink_timer], a
    
    ; Alternar visibilidad de AMBOS sprites
    ld hl, CMP_SPRITES_ADDRESS
    inc l 
    inc l 
    inc l               ; Sprite 0 - atributos
    ld a, [hl]
    xor %00010000       ; Invertir bit 4
    ld [hl], a
    
    ld a, l 
    add 4 
    ld l, a              ; Sprite 1 - atributos 
    ld a, [hl]
    xor %00010000       ; Invertir bit 4
    ld [hl], a
    
    ret