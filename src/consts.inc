;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GENERAL
DEF VBLANK_START equ $90

DEF LCD_CONTROL equ $FF40

DEF rP1 equ $FF00

;; Modos de lectura del Joypad
DEF P1_GET_BTN equ $10
DEF P1_GET_DPAD equ $20
DEF P1_GET_NONE equ $30

;; Bits del joypad combinado en joypad_current
DEF JOYPAD_RIGHT 	equ 0
DEF JOYPAD_LEFT 	equ 1
DEF JOYPAD_UP 		equ 2
DEF JOYPAD_DOWN 	equ 3
DEF JOYPAD_A 		equ 4
DEF JOYPAD_B 		equ 5
DEF JOYPAD_SELECT 	equ 6
DEF JOYPAD_START 	equ 7

DEF rLY equ $FF44

DEF rBGP equ $FF47
DEF rOBP0 equ $FF48
DEF rOBP1 equ $FF49

DEF OAM_START equ $FE00
DEF OAM_TOTAL_SPRITES equ 160

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ECS
DEF CMP_START_H  = $C0
DEF CMP_START_ADDRESS  = $C000
DEF NUM_ENTITIES = 40
DEF CMP_SIZE  = 4
DEF CMP_TOTALBYTES = NUM_ENTITIES * CMP_SIZE

;; Info Component
DEF CMP_INFO_H = $C0

;; Sprites Component
DEF CMP_SPRITES_H = $C1
DEF CMP_SPRITES_ADDRESS = $C100

DEF VRAM_TILE_DATA_START equ $8000
DEF VRAM_TILE_SIZE equ $10

DEF SPRITE_SIZE = 4
DEF SPRITE_OFFSET_Y    equ 0
DEF SPRITE_OFFSET_X    equ 1
DEF SPRITE_OFFSET_TILE equ 2 
DEF SPRITE_OFFSET_ATTR equ 3 

DEF SPRITE_ATTR_FLIP_X  equ %10100000  ; Flip horizontal activado
DEF SPRITE_ATTR_NO_FLIP	equ %10000000  ; Sin flip

DEF SPRITE_WIDTH equ 8
DEF SPRITE_HEIGHT equ 16

;;;;;;;;;;;;;;;;;;;;;;;;;
;; Physics Component
DEF CMP_PHYSICS_0_H = $C2
DEF CMP_PHYSICS_0_ADDRESS = $C200

DEF CMP_PHYSICS_BYTE_Pd_Y equ 0
DEF CMP_PHYSICS_BYTE_Pd_X equ 1
DEF CMP_PHYSICS_BYTE_V_Y  equ 2
DEF CMP_PHYSICS_BYTE_V_X  equ 3


DEF CMP_PHYSICS_1_H = $C3
DEF CMP_PHYSICS_1_ADDRESS = $C300

DEF CMP_PHYSICS_BYTE_FREE_0 equ 0
DEF CMP_PHYSICS_BYTE_FREE_1 equ 1
DEF CMP_PHYSICS_BYTE_A_Y    equ 2
DEF CMP_PHYSICS_BYTE_A_X    equ 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Física del jugador (Q5.3, C2)
DEF PLAYER_SPEED			equ %00001000	; +1
DEF PLAYER_SPEED_NEGATIVE 	equ %11111000 	; -1
DEF PLAYER_JUMP_SPEED		equ %10110000	; -10
DEF PLAYER_GRAVITY			equ %00001000 	; +1 

DEF PLAYER_INITIAL_POS_X  	equ $13 ; Posición inicial del jugador en X

; Física del gorila (Q5.3, C2)
DEF GORILLA_JUMP_SPEED 		equ %00011000   ; -3
DEF GORILLA_SPEED   		equ %00010000	; +2 
DEF GORILLA_SPEED_NEGATIVE  equ %11110000	; -2 
DEF GORILLA_GRAVITY     	equ %00001000   ; +1

DEF GROUND_Y equ 124	; Altura del suelo
