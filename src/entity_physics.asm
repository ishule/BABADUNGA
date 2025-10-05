INCLUDE "consts.inc"

SECTION "Entity Physics Code", ROM0

;;====================================================
;; entity_physics_init
;; Inicializa el componente de física de una entidad
;;
;; INPUT
;;	DE -> Dirección del componente de física de una entidad
;;	B  -> Posición X inicial (píxeles)
;;	C  -> Posición Y inicial (píxeles)
;;
;; MODIFICA: A, DE
entity_physics_init::
	; Escribir posicion X
	ld a, b
	ld [de], a 
	inc de 

	; Escribir posición Y
	ld a, c 
	ld [de], a 
	inc de 

	; Inicializar velocidades a 0
	xor a 
	ld [de], a ; VX = 0
	inc de 
	ld [de], a ; VY = 0
		
	ret


;;==================================================
;; entity_physics_get_position
;; Obtiene la posición de una entidad
;;
;; INPUT:
;;	DE -> Dirección del componente de física
;;	B  -> Posición X (píxeles)
;;  C  -> Posición Y (píxeles)
;;
;; MODIFICA: A, B, C
entity_physics_get_position::
	; Leer posición X
	ld a, [de]
	ld b, a 
	inc de 

	; Leer posición Y
	ld a, [de]
	ld c, a 

	ret


;;==================================================
;; entity_physics_get_velocity
;; Obtiene la velocidad de una entidad
;;
;; INPUT:
;;	DE -> Dirección del componente de física
;;	B  -> Velocidad X 
;;  C  -> Velocidad Y 
;;
;; MODIFICA: A, B, C
entity_physics_get_velocity::
	; Avanzamos hasta el byte 2
	inc de 
	inc de

	; Leer velocidad X
	ld a, [de]
	ld b, a 
	inc de 

	; Leer velocidad Y
	ld a, [de]
	ld c, a 

	ret


;;===============================================
;; entity_physics_set_position
;; Establece la posición de una entidad
;;
;; INPUT:
;;	DE -> Dirección del componente de física
;;	B  -> Nueva posición X (píxeles)
;;  C  -> Nueva posición Y (píxeles)
;;
;; MODIFICA: A, DE
entity_physics_set_position::
	; Escribir posición X
	ld a, b 
	ld [de], a 
	inc de 

	; Escribir posición Y
	ld a, c 
	ld [de], a 

	ret


;;==================================================
;; entity_physics_set_velocity
;; Establece la velocidad de una entidad
;;
;; INPUT:
;;	DE -> Dirección del componente de física
;;	B  -> Nueva velocidad X (con signo: -128 a +127)
;;  C  -> Nueva velocidad Y (con signo: -128 a +127)
;;
;; MODIFICA: A, DE
entity_physics_set_velocity::
	; Avanzar al offset de velocidad (saltar X e Y = 2 bytes)
	inc de 
	inc de 

	; Escribir velocidad X
	ld a, b 
	ld [de], a 
	inc de 

	; Escribir velocidad Y
	ld a, c 
	ld [de], a 

	ret


;;===============================================
;; entity_physics_apply_velocity
;; Aplica la velcoidad actual a la posicion (posicion += velocidad)
;; 
;; INPUT:
;;	DE -> Dirección del componente de física
;;
;; MODIFICA: A, BC, DE, HL
entity_physics_apply_velocity::
	; Guardamos la dirección base
	push de 

	; Podríamos usar los getters y setters pero sería mas lenta y usaríamos más la pila
	; Leer posicion X
	ld a, [de]
	ld l, a ; Guardamos posición X en l
	inc de 

	; Leer posicion Y 
	ld a, [de]
	ld h, a ; Guardamos posición Y en h
	inc de

	; Leer velocidad X
	ld a, [de]
	ld c, a 
	inc de

	; Leer velocidad Y 
	ld a, [de]
	ld b, a

	; Sumar velocidad X a posición X 
	ld a, l 
	add c
	ld l, a

	; Sumar velocidad Y a posición Y 
	ld a, h 
	add b 
	ld h, a

	; Recuperamos nuevas posiciones
	pop de 

	; Escribir nueva X
	ld a, l 
	ld [de], a 
	inc de 

	; Escribir nueva Y
	ld a, h 
	ld [de], a 

	ret



;;===============================================
;; entity_physics_add_velocity
;; Suma una velocidad a la velocidad actual
;; En caso de necesitar aceleración/gravedad será la función que usaremos
;;
;; INPUT:
;;	DE -> Dirección del componente de física
;;	B  -> Delta velocidad X
;;  C  -> Delta velocidad Y
;;
;; MODIFICA: A, BC, DE
entity_physics_add_velocity::
	; Guardamos dirección base
	push de 

	; Avanzar 2 bytes para ir a los bytes de velocidad
	inc de 
	inc de 

	; Leer velocidad X actual 
	ld a, [de]
	
	; Sumar delta VX (que está en B)
	add b

	; Escribir nueva VX 
	ld [de], a 
	inc de 

	; Leer velocidad Y actual
	ld a, [de]

	; Sumar delta VY (que está en C)
	add c 

	; Escribir nueva VY
	ld [de], a 

	; Resturamos la dirección base 
	pop de 
	ret

	

;;===============================================
;; entity_physics_stop 
;; Detiene el movimiento de una entidad (velocidad = 0)
;;
;; INPUT:
;;	DE -> Dirección del componente de física
;;
;; MODIFICA: A, DE
entity_physics_stop::
	; Avanzamos hasta el byte 2
	inc de 
	inc de 

	; Ponemos velocidades a 0
	xor a 
	ld [de], a ; VX = 0
	inc de 
	ld [de], a ; VY = 0

	ret

