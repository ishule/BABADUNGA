SECTION "Musica", ROM0

;; NUESTRAS NOTAS SACADAS CON UN AFINADOR:
;; DO5 -----------------------------------
DEF DO5 = $05
DEF DO5s = $14
DEF RE5 = $21
DEF RE5s = $2E
DEF MI5 = $39
DEF FA5 = $45
DEF FA5s = $4F
DEF SOL5 = $59
DEF SOL5s = $62
DEF LA5 = $6B
DEF LA5s = $73
DEF SI5 = $7B

;; DO6 -----------------------------------
DEF DO6 = $83
DEF DO6s = $8B
DEF RE6 = $90
DEF RE6s = $97
DEF MI6 = $9D
DEF FA6 = $A2
DEF FA6s = $A7
DEF SOL6 = $AC
DEF SOL6s = $B1
DEF LA6 = $B6
DEF LA6s = $BA
DEF SI6 = $BE

DEF SH = $FF ;Silencio
InicioMusic::
;; JUNGLE FREAKOUT
    ;Intro (Ritmo de tambores) --------------------
    ; Intro rítmica para crear ambiente
    DB DO5, SH, DO5, DO5, SH, SH, DO5, DO5
    DB MI5, SH, MI5, MI5, SH, SH, MI5, MI5
    DB FA5, SH, FA5, FA5, SH, SOL5, SOL5, SH
    DB SH, SH, SH, SH, SH, SH, SH, SH ; Pausa

    ;A (Tema principal "picado") -----------------
    ; El gancho principal, muy staccato
    DB SOL5, SH, SOL5, SH, SOL5, SH, LA5s, SH
    DB LA5s, SH, LA5s, SH, DO6, SH, LA5s, SH
    ; Arpegio rápido
    DB DO6, LA5s, SOL5, MI5, FA5, RE5s, DO5, SH
    DB DO5, SH, SH, SH, SH, SH, SH, SH
    
    ;A' (Repetición del tema) -----------------
    DB SOL5, SH, SOL5, SH, SOL5, SH, LA5s, SH
    DB LA5s, SH, LA5s, SH, DO6, SH, LA5s, SH
    ; Arpegio rápido (variación)
    DB DO6, SI5, LA5s, SOL5, FA5, MI5, RE5, DO5
    DB DO5, SH, SH, SH, SH, SH, SH, SH

    ;Puente (Rítmica de "bajos") --------------
    DB SH, MI5, MI5, MI5, SH, FA5, FA5, FA5
    DB SH, SOL5, SOL5, SOL5, SH, LA5s, LA5s, LA5s
    DB SH, MI5, MI5, MI5, SH, FA5, FA5, FA5
    DB SH, SOL5, SH, LA5s, SH, DO6, SH, SH

    ;B (Melodía ascendente) -------------------
    ; (Es la misma sección B de "Jungle Madness")
    DB SOL5, SOL5, LA5, LA5, SI5, SI5, DO6, SH
    DB DO6, SI5, LA5, SOL5, FA5, MI5, RE5, DO5
    DB SOL5, SOL5, LA5, LA5, SI5, SI5, DO6, SH
    DB DO6, SH, RE6, SH, MI6, SH, FA6, SH
    
    ; Loop de vuelta a A

EndInicioMusic::
GorillaMusic::

;; PRIMAL RAGE
    ;Intro (Tambores de Guerra) -----------------
    ; El ritmo de tambor que te gustó, pero más oscuro
    DB DO5, SH, DO5, DO5, SH, RE5s, RE5s, SH
    DB DO5, SH, DO5, DO5, SH, RE5s, RE5s, SH
    DB FA5, SH, FA5, FA5, SH, SOL5, SOL5, SH
    DB LA5s, SH, LA5s, SH, DO6, SH, SH, SH

    ;A (Tema principal "Amenaza") ----------------
    ; Rítmico y pesado
    DB DO5, SH, RE5s, SH, DO5, SH, RE5s, SH
    DB FA5, SH, SOL5, SH, LA5s, SH, DO6, SH
    ; "El Golpe" (Arpegio rápido descendente)
    DB DO6, LA5s, SOL5, FA5, RE5s, RE5, DO5, SH
    DB DO5, SH, SH, SH, SH, SH, SH, SH
    
    ;A' (Repetición) ---------------------------
    DB DO5, SH, RE5s, SH, DO5, SH, RE5s, SH
    DB FA5, SH, SOL5, SH, LA5s, SH, DO6, SH
    ; "El Golpe" (Variación más aguda)
    DB RE6, DO6, LA5s, SOL5, FA5, RE5s, DO5, SH
    DB DO5, SH, SH, SH, SH, SH, SH, SH

    ;Puente (El Pisotón) -----------------------
    ; Un ritmo sincopado y pesado
    DB SH, DO5, DO5, DO5, SH, RE5, RE5, SH
    DB SH, MI5, MI5, MI5, SH, FA5, FA5, SH
    DB SH, DO5, DO5, DO5, SH, RE5, RE5, SH
    DB SH, FA5, SH, SOL5, SH, LA5s, SH, DO6

    ;B (Modo Furia) ----------------------------
    ; La melodía se vuelve frenética y aguda
    DB DO6, DO6, DO6, SI5, LA5s, SI5, DO6, SH
    DB LA5s, LA5s, LA5s, SOL5, FA5, SOL5, LA5s, SH
    DB SOL5, SOL5, SOL5, LA5s, DO6, RE6, DO6, LA5s
    DB SOL5, FA5, MI5, RE5, DO5, SH, SH, SH
    
    ; Loop de vuelta a A
EndGorillaMusic::

SnakeMusic::
;; VIPER'S DANCE

    ;Intro (El Siseo) ---------------------------
    ; Una escala cromática que sube y baja
    DB DO5, DO5s, RE5, RE5s, MI5, FA5, FA5s, SOL5
    DB SOL5s, SOL5, FA5s, FA5, MI5, RE5s, RE5, DO5s
    DB DO5, DO5s, RE5, RE5s, MI5, FA5, FA5s, SOL5
    DB SH, SH, SH, SH

    ;A (Tema "Hipnótico") -----------------------
    ; Ritmo ondulante y "picado"
    DB MI5, SH, SH, FA5, SH, SH, MI5, SH
    DB RE5s, SH, SH, MI5, SH, SH, RE5s, SH
    ; "El Ataque" (Rápido)
    DB DO5, MI5, SOL5, SI5, DO6, SI5, SOL5, MI5
    DB DO5, SH, SH, SH, SH, SH, SH, SH
    
    ;A' (Repetición) ---------------------------
    DB MI5, SH, SH, FA5, SH, SH, MI5, SH
    DB RE5s, SH, SH, MI5, SH, SH, RE5s, SH
    ; "El Ataque" (Variación)
    DB RE6, DO6, SI5, LA5s, SOL5, FA5, MI5, RE5
    DB RE5, SH, SH, SH, SH, SH, SH, SH

    ;Puente (Tensión Creciente) ----------------
    ; Un ritmo que se acelera
    DB DO5, SH, DO5, SH, DO5, SH, DO5, SH
    DB RE5, SH, RE5, SH, RE5, SH, RE5, SH
    DB MI5, SH, MI5, MI5, SH, FA5, FA5, SH
    DB SOL5, SH, LA5s, SH, DO6, SH, RE6, SH

    ;B (Frenesí Venenoso) ----------------------
    ; Rápido y agudo
    DB DO6, SH, DO6, DO6s, RE6, RE6s, MI6, SH
    DB MI6, RE6s, RE6, DO6s, DO6, SI5, DO6, SH
    DB DO6, SH, DO6, DO6s, RE6, RE6s, MI6, SH
    DB FA6, MI6, RE6s, RE6, DO6s, DO6, SI5, LA5
    
    ; Loop de vuelta a A
EndSnakeMusic::

SpiderMusic::
;Intro (Warning Scuttle) --------------------
    ; Faster, more agitated intro
    DB MI5, SH, FA5, SH, SOL5s, SH, LA5, SH
    DB SI5, SH, LA5s, SH, SOL5s, SH, FA5, SH
    DB MI5, FA5, SOL5s, LA5, SI5, DO6, RE6, MI6
    DB SH, SH, SH, SH, SH, SH, SH, SH

    ;A (Main Threat Theme) ----------------------
    ; Driving, repetitive, minor feel
    DB LA5, SH, LA5, DO6, SH, LA5, DO6, RE6
    DB MI6, SH, RE6, DO6, SH, RE6, DO6, SI5
    DB LA5, SH, LA5, DO6, SH, LA5, DO6, RE6
    DB MI6, RE6, DO6, SI5, LA5, SOL5s, FA5s, MI5 ; Descending threat

    ;B (Tension Build) --------------------------
    ; Rising sequence, increasing urgency
    DB FA5, SH, SOL5, SH, LA5, SH, SI5, SH
    DB DO6, SH, RE6, SH, MI6, SH, FA6, SH
    ; Rapid diminished arpeggio (attack!)
    DB SOL6s, FA6, RE6, DO6, SI5, LA5, SOL5s, FA5
    DB MI5, SH, SH, SH, SH, SH, SH, SH

    ;A' (Return of Threat) ----------------------
    DB LA5, SH, LA5, DO6, SH, LA5, DO6, RE6
    DB MI6, SH, RE6, DO6, SH, RE6, DO6, SI5
    DB LA5, SH, LA5, DO6, SH, LA5, DO6, RE6
    DB MI6, FA6, SOL6s, FA6, MI6, RE6, DO6, SI5 ; Faster descent

    ;Climax (Frenzy) ----------------------------
    ; Highest and fastest part
    DB LA6, SH, SOL6s, SH, FA6, SH, MI6, SH
    DB RE6, SH, DO6, SH, SI5, SH, LA5, SH
    DB LA5, SI5, DO6, RE6, MI6, FA6, SOL6s, LA6
    DB LA6, SH, LA6, SH, LA6, SH, SH, SH ; Final stabs before loop

    ; Loop back to A

EndSpiderMusic::

VictoryMusic::
;Intro (Fanfarria Ascendente) ---------------
    ; Un arpegio rápido y brillante
    DB DO5, MI5, SOL5, DO6, MI6, SOL6, SH, SH
    DB SOL6, MI6, DO6, SOL5, MI5, DO5, SH, SH

    ;A (Tema Principal Victorioso) --------------
    ; La melodía principal, clara y heroica
    DB SOL5, SH, SOL5, LA5, SI5, DO6, SH, SH
    DB SI5, LA5, SOL5, FA5, MI5, RE5, DO5, SH
    DB SOL5, SH, SOL5, LA5, SI5, DO6, SH, SH
    DB DO6, RE6, MI6, FA6, MI6, RE6, DO6, SH

    ;Final (Conclusión Triunfal) ----------------
    ; Resolución final en Do Mayor
    DB SOL5, LA5, SI5, DO6, RE6, MI6, FA6, SOL6
    DB DO6, DO6, DO6, SH, SH, SH, SH, SH ; ¡Victoria!
EndVictoryMusic::

DefeatMusic::
;Intro (Descenso Lento) ---------------------
    ; Un arpegio descendente en La menor
    DB MI6, SH, DO6, SH, LA5, SH, SH, SH
    DB SOL5, SH, MI5, SH, DO5, SH, SH, SH

    ;A (Tema Principal Triste) ------------------
    ; Melodía lenta y descendente
    DB LA5, SH, SOL5, SH, FA5, SH, MI5, SH
    DB RE5, SH, MI5, SH, FA5, SH, MI5, SH
    DB LA5, SH, SOL5, SH, FA5, SH, MI5, SH
    DB RE5, DO5, SI5, LA5, SH, SH, SH, SH ; Nota La grave final
EndDefeatMusic::

RestMusic::
;; CALM OASIS

    ; Phrase 1 (Simple ascending/descending)
    DB DO5, SH, SH, MI5, SH, SH, SOL5, SH
    DB FA5, SH, SH, MI5, SH, SH, RE5, SH
    DB DO5, SH, SH, SH, SH, SH, SH, SH
    DB SH, SH, SH, SH, SH, SH, SH, SH ; Extra pause

    ; Phrase 2 (Slight variation)
    DB MI5, SH, SH, SOL5, SH, SH, LA5, SH
    DB SOL5, SH, SH, FA5, SH, SH, MI5, SH
    DB RE5, SH, DO5, SH, SH, SH, SH, SH
    DB SH, SH, SH, SH, SH, SH, SH, SH ; Extra pause

    ; Phrase 3 (Gentle ending, leading back to start)
    DB SOL5, SH, MI5, SH, FA5, SH, RE5, SH
    DB DO5, SH, RE5, SH, MI5, SH, SH, SH
    DB DO5, SH, SH, SH, SH, SH, SH, SH
    DB SH, SH, SH, SH, SH, SH, SH, SH ; Loop back

EndRestMusic::

SECTION "Mi Nota", WRAM0
miNota:
ds 1