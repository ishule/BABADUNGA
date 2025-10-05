INCLUDE "consts.inc"

SECTION "Joypad Prueba Variables", WRAM0
joypad_current:: DS 1	; Estado actual de los botones
joypad_previous:: DS 1	; Estado de los botones en el frame anterior
joypad_pressed:: DS 1	; Botones al ser presionados (flanco ascendente)
joypad_released:: DS 1	; Botones al ser soltados (flanco inferior)

;; Guardamos los botones que han sido presionados y los que han sido soltados
;; para distinguir entre acciones continuas y únicas, como por ejemplo, el salto
;; current: movimiento, apuntar
;; pressed: saltar, disparar
;; released: mecańicas de carga (si se llegan a incorporar)

SECTION "Joypad Prueba Code", ROM0

;;======================================================
;; joypad_init
;; Inicializa los valores del joypad
;;
;; MODIFICA: A, HL
joypad_prueba_init::
	xor a 
	ld [joypad_current], a 
	ld [joypad_previous], a 
	ld [joypad_pressed], a 
	ld [joypad_released], a

	ret 


;;======================================================
;; joypad_read
;; Lee el estado del joypad y actualiza variables de joypad
;; Debe llamarse después de VBlank 
;;
;; OUTPUT:
;;	joypad_current 	-> Botones actualmente presionados
;;	joypad_pressed 	-> Botones que acaban de ser presionados en el frame actual
;; 	joypad_released -> Botones que acaban de ser soltados en el frame actual
;;
;; MODIFICA: A, B, C
joypad_prueba_read::
    ; Guardamos el estado anterior
    ld a, [joypad_current]
    ld [joypad_previous], a 
    
    ; Leer D-pad 
    ld a, P1_GET_DPAD 
    ld [rP1], a 
    
    ; Esperamos estabilización
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    
    ; Leer y almacenar D-pad
    ld a, [rP1]
    cpl 
    and $0F
    ld b, a  ; B = D-pad
    
    ; Leer botones
    ld a, P1_GET_BTN 
    ld [rP1], a 
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    cpl
    and $0F 
    swap a
    or b  ; A = estado completo del joypad
    
    ; Guardar estado actual
    ld [joypad_current], a
    ld c, a  ; ← GUARDAR en C antes de resetear
    
    ; Resetear joypad
    ld a, P1_GET_NONE
    ld [rP1], a
    
    ; Calcular botones presionados: current AND (NOT previous)
    ld a, [joypad_previous]
    cpl              ; NOT previous
    and c            ; AND current (que guardamos en C)
    ld [joypad_pressed], a
    
    ; Calcular botones liberados: previous AND (NOT current)
    ld a, c          ; current
    cpl              ; NOT current
    ld b, a
    ld a, [joypad_previous]
    and b            ; previous AND (NOT current)
    ld [joypad_released], a
    
    ret
