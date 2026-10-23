extends Node

signal quest_updated
signal quest_completed(quest: Dictionary)

var quests := {
    "valley_hunt": {"name":"Defiende el Valle", "description":"Derrota 3 Lobos Salvajes.", "type":"main", "target":"wolf_raider", "required":3, "progress":0, "reward_power":8, "reward_potential":6, "reward_zeni":60, "reward_item":"water", "completed":false},
    "forest_hunt": {"name":"Peligro en el bosque", "description":"Derrota 5 enemigos del Bosque Oscuro.", "type":"main", "target":"forest_any", "required":5, "progress":0, "reward_power":14, "reward_potential":10, "reward_zeni":140, "reward_item":"senzu", "completed":false},
    "desert_patrol": {"name":"Ruta Carmesí", "description":"Derrota 5 Bandidos del Desierto.", "type":"zone", "target":"desert_bandit", "required":5, "progress":0, "reward_power":18, "reward_potential":12, "reward_zeni":180, "reward_item":"heavy_gi", "completed":false},
    "kame_raiders": {"name":"Problemas en la costa", "description":"Derrota 6 Piratas de Kame.", "type":"zone", "target":"pirate_raider", "required":6, "progress":0, "reward_power":22, "reward_potential":14, "reward_zeni":220, "reward_item":"pirate_coin", "completed":false},
    "ice_patrol": {"name":"La patrulla glacial", "description":"Derrota 6 enemigos en las Montañas del Norte.", "type":"zone", "target":"ice_any", "required":6, "progress":0, "reward_power":28, "reward_potential":18, "reward_zeni":300, "reward_item":"ice_guard", "completed":false},
    "namek_defense": {"name":"Defiende Namek", "description":"Derrota 5 Asaltantes de Namek.", "type":"zone", "target":"namek_raider", "required":5, "progress":0, "reward_power":32, "reward_potential":22, "reward_zeni":360, "reward_item":"namek_charm", "completed":false},
    "master_training": {"name":"El camino del KI", "description":"Usa 3 técnicas de KI.", "type":"trainer", "target":"skill_use", "required":3, "progress":0, "reward_power":10, "reward_potential":12, "reward_zeni":70, "reward_item":"water", "completed":false},
    "daily_patrol": {"name":"Patrulla diaria", "description":"Derrota 10 enemigos.", "type":"daily", "target":"any_enemy", "required":10, "progress":0, "reward_power":20, "reward_potential":16, "reward_zeni":240, "reward_item":"water", "completed":false},
    "dragon_orbs": {"name":"Las siete esferas", "description":"Reúne 7 Orbes del Dragón repartidos por el mundo.", "type":"collection", "target":"dragon_orb", "required":7, "progress":0, "reward_power":45, "reward_potential":35, "reward_zeni":900, "reward_item":"senzu", "completed":false},
    "red_ribbon_patrol": {"name":"Patrulla Roja","description":"Derrota exploradores del Ejército Red en la base.","target":"rr_scout","required":5,"progress":0,"reward_power":30,"reward_potential":20,"reward_zeni":180,"reward_item":"rr_insignia","completed":false,"type":"hunt"},
    "red_ribbon_commander": {"name":"Comandante de Patrulla","description":"Derrota al comandante de la base.","target":"rr_commander","required":1,"progress":0,"reward_power":55,"reward_potential":38,"reward_zeni":320,"reward_item":"heavy_gi","completed":false,"type":"hunt"},
    "namek_guard": {"name":"Guardianes del Pantano","description":"Derrota guardianes y asaltantes de Namek.","target":"namek_guardian","required":4,"progress":0,"reward_power":40,"reward_potential":28,"reward_zeni":250,"reward_item":"namek_charm","completed":false,"type":"hunt"},
    "ice_commander": {"name":"La Fortaleza de Hielo","description":"Derrota al Comandante Glacial en las montañas.","target":"ice_commander","required":1,"progress":0,"reward_power":72,"reward_potential":48,"reward_zeni":500,"reward_item":"ice_guard","completed":false,"type":"hunt"},
    "temple_trial": {"name":"Prueba del templo", "description":"Derrota al Guardián del Templo.", "type":"boss", "target":"temple_guardian", "required":1, "progress":0, "reward_power":60, "reward_potential":50, "reward_zeni":400, "reward_item":"dragon_orb", "completed":false},
    "tournament_intro": {"name":"Rumbo al torneo", "description":"Derrota 6 enemigos en las Llanuras del Torneo.", "type":"chapter", "target":"plains_any", "required":6, "progress":0, "reward_power":44, "reward_potential":30, "reward_zeni":320, "reward_item":"water", "completed":false},
    "arena_champion": {"name":"El campeón no cae", "description":"Derrota al Campeón de la Arena.", "type":"boss", "target":"arena_champion", "required":1, "progress":0, "reward_power":95, "reward_potential":65, "reward_zeni":700, "reward_item":"heavy_gi", "completed":false},
    "wasteland_overlord": {"name":"Señor de la devastación", "description":"Derrota al Señor de la Tierra Devastada.", "type":"boss", "target":"wasteland_overlord", "required":1, "progress":0, "reward_power":125, "reward_potential":85, "reward_zeni":1000, "reward_item":"galactic_badge", "completed":false},
    "otherworld_judge": {"name":"Juicio final", "description":"Derrota al Juez del Otro Mundo.", "type":"boss", "target":"otherworld_judge", "required":1, "progress":0, "reward_power":170, "reward_potential":110, "reward_zeni":1600, "reward_item":"karin_talisman", "completed":false}
}

func on_enemy_defeated(enemy_id: String) -> void:
    for q in quests.values():
        if q.completed:
            continue
        var target := str(q.target)
        var hit := target == enemy_id
        if target == "forest_any":
            hit = enemy_id in ["saibaman", "wolf_raider", "saibaman_elite"]
        elif target == "ice_any":
            hit = enemy_id in ["ice_wolf", "frost_soldier"]
        elif target == "plains_any":
            hit = enemy_id in ["galactic_raider", "rr_heavy", "saibaman_elite", "namek_raider"]
        elif target == "any_enemy":
            hit = true
        if hit:
            q.progress = mini(int(q.required), int(q.progress) + 1)
            if q.progress >= q.required:
                _complete(q)
    quest_updated.emit()

func on_item_collected(item_id: String, amount: int = 1) -> void:
    var q: Dictionary = quests["dragon_orbs"]
    if q.completed or item_id != "dragon_orb":
        return
    q.progress = mini(q.required, q.progress + amount)
    if q.progress >= q.required:
        _complete(q)
    quest_updated.emit()

func on_skill_used() -> void:
    var q: Dictionary = quests["master_training"]
    if q.completed:
        return
    q.progress = mini(q.required, q.progress + 1)
    if q.progress >= q.required:
        _complete(q)
    quest_updated.emit()

func completed_count() -> int:
    var count := 0
    for q in quests.values():
        if q.completed:
            count += 1
    return count

func _complete(q: Dictionary) -> void:
    q.completed = true
    var achievement_id := "quest_" + str(q.name)
    if not GameState.achievements.has(achievement_id):
        GameState.achievements.append(achievement_id)
    quest_completed.emit(q)
    GameState.changed.emit()
    # Mission five grants the race's second technique for free.
    if completed_count() >= 5:
        SkillManager.unlock_second_skill_after_mission_five()

func get_active() -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    for q in quests.values():
        if not q.completed:
            out.append(q)
    return out

func get_primary_for_zone(zone_id: String, player_power: int = 10) -> Dictionary:
    var zone_targets := {
        "valley": ["valley_hunt", "daily_patrol"], "forest": ["forest_hunt", "master_training"],
        "desert": ["desert_patrol", "daily_patrol"], "kame": ["kame_raiders", "master_training"],
        "ice": ["ice_patrol", "ice_commander"], "namek": ["namek_defense", "namek_guard"],
        "red_ribbon": ["red_ribbon_patrol", "red_ribbon_commander"], "temple": ["temple_trial", "master_training"],
        "karin": ["temple_trial", "master_training"], "plains": ["tournament_intro", "master_training"],
        "arena": ["arena_champion", "tournament_intro"], "wasteland": ["wasteland_overlord", "daily_patrol"],
        "otherworld": ["otherworld_judge", "daily_patrol"], "city": ["master_training", "daily_patrol"]
    }
    var preferred: Array = zone_targets.get(zone_id, ["daily_patrol"])
    var best: Dictionary = {}
    var best_score := -999999
    for id in preferred:
        if not quests.has(id):
            continue
        var q: Dictionary = quests[id]
        if q.completed:
            continue
        var score := 1000
        if q.type == "daily": score -= 30
        if q.type == "trainer": score -= 20
        score -= abs(player_power - _quest_power_hint(str(id)))
        if score > best_score:
            best_score = score
            best = q
    if not best.is_empty():
        return best
    var active := get_active()
    return active[0] if not active.is_empty() else {}

func _quest_power_hint(id: String) -> int:
    var hints := {
        "valley_hunt": 10, "forest_hunt": 25, "desert_patrol": 40, "kame_raiders": 55,
        "ice_patrol": 75, "namek_defense": 100, "master_training": 20, "daily_patrol": 20,
        "dragon_orbs": 70, "red_ribbon_patrol": 65, "red_ribbon_commander": 85, "namek_guard": 110,
        "ice_commander": 135, "temple_trial": 175, "tournament_intro": 80, "arena_champion": 150,
        "wasteland_overlord": 240, "otherworld_judge": 360
    }
    return int(hints.get(id, 10))

func reset() -> void:
    for q in quests.values():
        q.completed = false
        q.progress = 0
    quest_updated.emit()

func serialize_state() -> Dictionary:
    var out := {}
    for id in quests.keys():
        out[id] = {"progress": quests[id].progress, "completed": quests[id].completed}
    return out

func deserialize_state(data) -> void:
    if not (data is Dictionary):
        return
    for id in quests.keys():
        if data.has(id):
            quests[id].progress = int(data[id].get("progress", 0))
            quests[id].completed = bool(data[id].get("completed", false))
