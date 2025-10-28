INCLUDE "consts.inc"

def SNAKE_SPAWN_POINT_Y equ GROUND_Y - SPRITE_HEIGHT
def SNAKE_SPAWN_POINT_X equ $40

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; TILES
def SNAKE_HEAD_TILE_ID equ $80

def SNAKE_IDLE_NECK_TILE_ID equ $84
def SNAKE_WALK_NECK_TILE_ID equ $88

def SNAKE_BODY_TILE_ID equ $8C

def SNAKE_SHOT_HEAD_TILE_ID equ $8E

def SNAKE_SHOT_BODY_TILE_ID equ $92

def SNAKE_TAIL_UP_TILE_ID equ $96

def SNAKE_HEAD_EDGE_TILE_ID equ $9A

def SNAKE_BULLET_TILE_ID equ $9C
def EMPTY_TILE_ID equ $A0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GENERAL
def SNAKE_NUM_ENTITIES equ 9