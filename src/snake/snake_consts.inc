INCLUDE "consts.inc"

def SNAKE_SPAWN_POINT_Y equ GROUND_Y - SPRITE_HEIGHT
def SNAKE_SPAWN_POINT_X equ WALL_RIGHT_X - SPRITE_WIDTH * 5 - 3

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
;; ENTITIES IDs
def TAIL_ENTITY_ID equ 10
def BODY_ENTITY_ID equ 4
def NECK_ENTITY_ID equ 8

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GENERAL
def SNAKE_NUM_ENTITIES equ 9
def SNAKE_HEALTH equ 10
def SNAKE_DAMAGE equ 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; STATES
def SNAKE_STAND_STATE equ 0
def SNAKE_WALK_STATE equ 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; TIMERS
def STAND_TIME equ $A0
def SNAKE_SHOT_COOLDOWN equ $40
def SNAKE_WALK_ANIM_TIME equ $10

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SWAP MASKS
def SWAP_MASK_IDLE_WALK equ %00001100
def SWAP_MASK_TAILS     equ %00001110

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MOVEMENT
def SPIDER_MOVE_ACCELERATION equ $0008