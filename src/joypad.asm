INCLUDE "consts.inc"

SECTION "Joypad Variables", WRAM0
joypad_input:: DS 1  ; Estado actual de los botones

SECTION "Joypad Code", ROM0

;;======================================================
;; joypad_init
;; Inicializa el joypad
;;
;; MODIFICA: A
joypad_init::
    xor a 
    ld [joypad_input], a 
    ret 

;;======================================================
;; joypad_read
;; Lee el estado actual del joypad
;;
;; OUTPUT:
;;   joypad_input -> Botones actualmente presionados
;;
;; MODIFICA: A, B
joypad_read::
    ; Leer D-pad
    ld a, P1_GET_DPAD
    ldh [rP1], a
    
    ; Esperamos estabilización
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    
    ; Leer y almacenar D-pad (invertimos los bits y nos quedamos con los 4 bajos)
    ldh a, [rP1]
    cpl     ; Invertir bits (0 = presionado -> 1 = presionado)
    and $0F ; Nos quedamos solo con los 4 bits bajos
    ld b, a ; B = D-pad en bits 0 - 3
    
    ; Leemos los botones y hacemos lo mismo
    ld a, P1_GET_BTN
    ldh [rP1], a
    
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    
  
    ldh a, [rP1]
    cpl
    and $0F
    swap a  ; Botones a bits 4 - 7
    or b    ; Combinamos con D-pad (en los bits altos)
    
    ; Lo que hemos hecho ha sido combinar en un byte todos los posibles inputs
    ; Bits 0-3: D-pad
    ; Bits 4-7: Botones
    ; Bit: 7     6      5   4   3    2   1     0
    ;    Start Select   B   A  Down  Up Left Right
    ; De esta forma cobran sentido las constantes 


    ; Guardamos estado actual del joypad
    ld [joypad_input], a
    
    ; Resetear
    ld a, $30
    ldh [$FF00], a
    
    ret