extends Node

signal chapter_changed(chapter: int)

const CHAPTERS := {
    1: {"title":"Capítulo I — El despertar", "description":"Sobrevive al Valle Azul y consigue tu primera técnica de KI tras completar cinco misiones.", "unlock_zone":"valley", "required_power":10},
    2: {"title":"Capítulo II — El mapa se abre", "description":"Visita Ciudad Capsule y demuestra que puedes sobrevivir fuera del valle.", "unlock_zone":"city", "required_power":40},
    3: {"title":"Capítulo III — Guerreros del cielo", "description":"Desbloquea el vuelo mediante tu crecimiento de poder y atraviesa las rutas aéreas.", "unlock_zone":"namek", "required_power":90},
    4: {"title":"Capítulo IV — Poder más allá", "description":"Supera una zona de élite y derrota un jefe de segunda fase.", "unlock_zone":"temple", "required_power":180},
    5: {"title":"Capítulo V — El universo observa", "description":"Abre el contenido de endgame: raids, PvP y el futuro MMO.", "unlock_zone":"temple", "required_power":350}
}

func current() -> Dictionary:
    return CHAPTERS.get(GameState.chapter, CHAPTERS[1])

func try_advance() -> bool:
    var next := GameState.chapter + 1
    if not CHAPTERS.has(next): return false
    var req := int(CHAPTERS[next].required_power)
    if GameState.power < req: return false
    GameState.chapter = next
    GameState.changed.emit()
    chapter_changed.emit(next)
    SaveManager.save_game()
    return true
