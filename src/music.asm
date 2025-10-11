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

OST::
    ;; ========== INTRO ÉPICA (8 compases) ==========
    ; Fanfarria heroica ascendente
    DB DO5, DO5, DO5, SH, MI5, MI5, MI5, SH
    DB SOL5, SOL5, SOL5, SH, DO6, DO6, SH, SH
    
    ; Melodía de presentación
    DB SOL5, LA5, SI5, DO6, SI5, LA5, SOL5, FA5
    DB MI5, FA5, SOL5, LA5, SOL5, FA5, MI5, RE5
    
    ;; ========== VERSO A - Melodía principal (16 compases) ==========
    ; Frase 1: Melódica y pegadiza
    DB DO5, SH, MI5, SH, SOL5, LA5, SOL5, FA5
    DB MI5, RE5, DO5, SH, RE5, MI5, FA5, SH
    
    DB SOL5, SH, LA5, SH, SI5, DO6, SI5, LA5
    DB SOL5, FA5, MI5, SH, FA5, SOL5, LA5, SH
    
    ; Frase 2: Con más energía
    DB DO6, SI5, LA5, SOL5, LA5, SI5, DO6, RE6
    DB MI6, SH, RE6, SH, DO6, SI5, LA5, SOL5
    
    DB FA5, SOL5, LA5, SI5, LA5, SOL5, FA5, MI5
    DB RE5, MI5, FA5, SOL5, FA5, MI5, RE5, DO5
    
    ;; ========== VERSO B - Sección rítmica (16 compases) ==========
    ; Patrón de saltos (estilo Mario/Kirby)
    DB MI5, MI5, SH, MI5, SOL5, SOL5, SH, SOL5
    DB DO6, DO6, SH, DO6, SI5, LA5, SOL5, SH
    
    DB RE5, RE5, SH, RE5, FA5, FA5, SH, FA5
    DB LA5, LA5, SH, LA5, SOL5, FA5, MI5, SH
    
    ; Variación con staccato
    DB DO5, SH, DO5, SH, MI5, SH, MI5, SH
    DB SOL5, SH, SOL5, SH, DO6, SH, SH, SH
    
    DB SI5, SH, SI5, SH, LA5, SH, LA5, SH
    DB SOL5, SH, FA5, SH, MI5, SH, SH, SH
    
    ;; ========== PUENTE DRAMÁTICO (8 compases) ==========
    ; Ascenso cromático épico
    DB DO5, DO5s, RE5, RE5s, MI5, FA5, FA5s, SOL5
    DB SOL5s, LA5, LA5s, SI5, DO6, RE6, MI6, FA6
    
    ; Caída melódica
    DB FA6, MI6, RE6, DO6, SI5, LA5, SOL5, FA5
    DB MI5, RE5, DO5, SH, SH, SH, SH, SH
    
    ;; ========== VERSO A' - Reprise con variación (16 compases) ==========
    ; Frase 1 octavada (más aguda)
    DB DO6, SH, MI6, SH, SOL6, LA6, SOL6, FA6
    DB MI6, RE6, DO6, SH, RE6, MI6, FA6, SH
    
    DB SOL6, SH, LA6, SH, SI6, DO6, SI6, LA6
    DB SOL6, FA6, MI6, SH, FA6, SOL6, LA6, SH
    
    ; Descenso armónico
    DB DO6, SI5, LA5, SOL5, FA5, MI5, RE5, DO5
    DB SI4, LA4, SOL4, FA4, MI4, RE4, DO4, SH
    
    ; Reafirmación del tema
    DB DO5, MI5, SOL5, DO6, SOL5, MI5, DO5, SH
    DB SOL5, SI5, RE6, SOL6, RE6, SI5, SOL5, SH
    
    ;; ========== FINAL ÉPICO (8 compases) ==========
    ; Resolución triunfal
    DB DO6, DO6, DO6, SH, MI6, MI6, MI6, SH
    DB SOL6, SOL6, SOL6, SH, DO6, SH, SH, SH
    
    ; Acorde final (arpegio)
    DB DO5, MI5, SOL5, DO6, MI6, SOL6, DO6, SOL5
    DB MI5, DO5, SH, SH, DO5, SH, SH, SH

EndOST::

SECTION "Current Score",WRAM0
current_score: ds 1