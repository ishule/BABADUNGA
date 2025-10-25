INCLUDE "consts.inc"
DEF GORILLA_NUM_ENTITIES equ $08

def GORILLA_SPAWN_POINT_Y equ GROUND_Y - SPRITE_HEIGHT
def GORILLA_SPAWN_POINT_X equ $80

def WALL_LEFT_Y equ $A0
def WALL_LEFT_X equ $10

;; Constantes de máscara
DEF SWAP_MASK_SPRITE_STAND_JUMP equ %00010000


DEF GORILLA_LEFT_LIMIT  equ 35     ; Límite izquierdo (posición X mínima)
DEF GORILLA_RIGHT_LIMIT equ 128    ; Límite derecho (160 - 32 de ancho)
def MASK_ANIM_FRAME equ %01000000

; Estados del Gorila 
DEF GORILLA_STAND_STATE           equ $00
DEF GORILLA_JUMP_STATE            equ $01
DEF GORILLA_JUMP_TO_STRIKE_STATE  equ $04
DEF GORILLA_STRIKE_STATE          equ $03

DEF STAND_TIME equ $A0

DEF JUMP_GRAVITY   equ $0030
DEF JUMP_IMPULSE_Y equ $FC00
DEF JUMP_IMPULSE_X equ $0100

DEF STAGE_CHANGE_LIFE equ $10