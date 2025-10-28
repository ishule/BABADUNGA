INCLUDE "snake/snake_consts.inc"

SECTION "Snake Variables", WRAM0
snake_state::             DS 1 ; 0:roof | 1:falling | 2:stunned | 3:jump_to_stand | 4:stand | 5:jumping | 6:going_up
snake_shot_cooldown::     DS 1
snake_state_counter::     DS 1
snake_animation_counter:: DS 1 
snake_stage::             DS 1 ; 0:fase 0 | 1:fase 1

SECTION "Snake Code", ROM0

sys_snake_movement::
	; === Check state ==
	ld a, [snake_state]

	ret