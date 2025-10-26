include "consts.inc"
SECTION "Snake Movement Vars",WRAM0

SECTION "Snake Logic",ROM0

; -----------------------
; sys_snake_movement
; Máquina de estados: INIT → MOVE → (al tocar borde) → TURN -> IDLE → SHOOT → MOVE
; -----------------------
sys_snake_movement::

    ret