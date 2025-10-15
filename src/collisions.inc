DEF MAX_COLLISIONS 		equ 10 
DEF SIZEOF_COLLISION 	equ 4
DEF COLLISION_ARRAY_SIZE = SIZEOF_COLLISION * MAX_COLLISIONS

;; Estructura de la colisión
DEF C_POSY 		equ 0 
DEF C_POSX 		equ 1
DEF C_HEIGHT 	equ 2
DEF C_WIDTH 	equ 3

;; Estructura del intervalo
DEF I_POS 	= 0 	; Posición (Y o X)
DEF I_SIZE 	= 1  	; Tamaño (Height o Width)