SECTION "Music",ROM0

;;=============================================================================
;; FRECUENCIAS CORREGIDAS PARA GAME BOY
;;=============================================================================

;; DO4 - Octava 4 (Grave)
DEF DO4=$1C
DEF DO4s=$29
DEF RE4=$35
DEF RE4s=$40
DEF MI4=$4A
DEF FA4=$54
DEF FA4s=$5D
DEF SOL4=$66
DEF SOL4s=$6E
DEF LA4=$76
DEF LA4s=$7D
DEF SI4=$84

;; DO5 - Octava 5 (Media)
DEF DO5=$8B
DEF DO5s=$91
DEF RE5=$97
DEF RE5s=$9D
DEF MI5=$A2
DEF FA5=$A7
DEF FA5s=$AC
DEF SOL5=$B1
DEF SOL5s=$B5
DEF LA5=$B9
DEF LA5s=$BD
DEF SI5=$C1

;; DO6 - Octava 6 (Aguda)
DEF DO6=$C5
DEF DO6s=$C9
DEF RE6=$CC
DEF RE6s=$D0
DEF MI6=$D3
DEF FA6=$D6
DEF FA6s=$D9
DEF SOL6=$DC
DEF SOL6s=$DF
DEF LA6=$E1
DEF LA6s=$E4
DEF SI6=$E6

DEF SH=$FF  ; Silencio

;;=============================================================================
;; OST: "HERO'S ADVENTURE" - Tema épico estilo Game Boy clásico
;; Inspirado en: Zelda, Pokémon, Mega Man
;; Estructura: Intro → Verso A → Verso B → Puente → Verso A' → Final
;;=============================================================================

;;=============================================================================
;; OST: "JUNGLE RHYTHM" - Tema rítmico y misterioso
;; Inspirado en: Donkey Kong Country, Adventure Island
;; Estructura: Intro → Verso A → Puente → Verso B → Final
;;=============================================================================

OST::
    ;; DINO BONKER - Formato simple de 1 byte (DB)

    ; Intro ---------------------------------------
    ; Un pequeño llamado para empezar la aventura
    DB DO4, SH, RE4, SH, MI4, FA4, SOL4, SH
    DB SOL4, FA4, MI4, RE4, DO4, SH, SH, SH

    ; Verso A (Ritmo principal) ---------------------
    DB SOL4, SH, SOL4, DO5, SH, SOL4, FA4s, FA4
    DB MI4, SH, MI4, FA4, SH, MI4, RE4s, RE4
    DB SOL4, SH, SOL4, DO5, SH, SOL4, FA4s, FA4
    DB MI4, FA4, MI4, RE4, DO4, SH, SH, SH

    ; Puente ---------------------------------------
    ; Una sección más melódica para variar
    DB LA4s, SH, SH, LA4, SH, SH, SOL4, SH
    DB FA4, SH, SOL4, SH, LA4, SH, SH, SH
    DB LA4s, SH, SH, LA4, SH, SH, SOL4, SH
    DB DO5, SH, LA4s, SH, LA4, SOL4, FA4, MI4

    ; Verso B (Variación rítmica) --------------------
    DB DO4, DO4, SH, MI4, SH, SOL4, SH, MI4
    DB FA4, FA4, SH, LA4, SH, SOL4, SH, FA4
    DB DO4, DO4, SH, MI4, SH, SOL4, SH, MI4
    DB RE4, SH, RE4, SH, MI4, FA4, MI4, RE4

    ; Final ---------------------------------------
    ; Conclusión que resuelve la melodía
    DB DO5, LA4s, SOL4, FA4s, FA4, MI4, RE4, DO4
    DB DO4, SH, SH, SH, SH, SH, SH, SH

EndOST::

SECTION "Current Score",WRAM0
current_score: ds 1