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
def MOUTH_ENTITY_ID equ 7
def HEAD_ENTITY_ID  equ 6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GENERAL
def SNAKE_NUM_ENTITIES equ 9
def SNAKE_HEALTH equ 10
def SNAKE_STAGE_CHANGE_HEALTH equ 5
def SNAKE_DAMAGE equ 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; STATES
def SNAKE_STAND_STATE equ 0
def SNAKE_WALK_STATE equ 1
def SNAKE_STAGE_TRANSITION_STATE equ 2
def SNAKE_DEAD_STATE equ $FF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; TIMERS
def STAND_TIME equ $E0
def SNAKE_SHOT_COOLDOWN equ $40
def SNAKE_WALK_ANIM_TIME equ $10
def STAGE_TRANSITION_TIME equ $30
def SNAKE_YELL_ANIM_TIME equ $20
def SHOT_ANIM_TIME       equ $10
def DEAD_ANIM_TIME       equ $FF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SWAP MASKS
def SWAP_MASK_IDLE_WALK equ %00001100
def SWAP_MASK_TAILS     equ %00001110
; Open mouth
def SWAP_MASK_HEAD      equ %00001110
def SWAP_MASK_MOUTH     equ %00010010
def SWAP_MASK_NECK_L    equ %00011100
def SWAP_MASK_NECK_R    equ %00100000
def SWAP_MASK_BODY_NECK equ %00011110

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MOVEMENT
def SPIDER_MOVE_ACCELERATION equ $0008

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BULLETS
def BULLETS_GRAVITY equ $0010
;; First shot
def SNAKE_SHOT_1_V_X equ $0200
def SNAKE_SHOT_1_V_Y equ $FF00
;; Second shot
def SNAKE_SHOT_2_V_X equ $01F0
def SNAKE_SHOT_2_V_Y equ $FFF0
;; Third shot
def SNAKE_SHOT_3_V_X equ $00F0
def SNAKE_SHOT_3_V_Y equ $FFF8
