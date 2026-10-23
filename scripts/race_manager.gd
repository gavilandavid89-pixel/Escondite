extends Node

signal changed

const RACES := {
    "Saiyan": {
        "description": "Guerreros adaptativos. Su poder crece bajo presión y sus técnicas favorecen ráfagas ofensivas y explosiones de fuerza.",
        "stats": {"vitality": 9, "attack_stat": 12, "ki_power": 10, "armor": 7, "speed_stat": 10, "crit_chance": 6.0, "crit_damage": 155.0, "ki_regen": 9.0, "dodge_chance": 4.0},
        "starter_ki": "saiyan_ki_burst",
        "skills": ["saiyan_ki_burst", "galick_gun", "kaioken", "meteor_crash", "super_saiyan", "super_saiyan_2"],
        "transformation": "super_saiyan",
        "color": "#ff9a37"
    },
    "Humano": {
        "description": "Especialistas marciales. Sus técnicas recompensan precisión, control y recuperación de recursos.",
        "stats": {"vitality": 10, "attack_stat": 9, "ki_power": 11, "armor": 9, "speed_stat": 11, "crit_chance": 8.0, "crit_damage": 150.0, "ki_regen": 11.0, "dodge_chance": 5.0},
        "starter_ki": "human_ki_burst",
        "skills": ["human_ki_burst", "kamehameha", "solar_flare", "wolf_fang_fist", "spirit_focus", "potential_unleashed"],
        "transformation": "potential_unleashed",
        "color": "#67b7ff"
    },
    "Namekiano": {
        "description": "Guerreros regenerativos. Pueden recuperar vida, extender el cuerpo y convertir el terreno en una zona de control.",
        "stats": {"vitality": 12, "attack_stat": 9, "ki_power": 12, "armor": 12, "speed_stat": 7, "crit_chance": 4.0, "crit_damage": 155.0, "ki_regen": 12.0, "dodge_chance": 2.0},
        "starter_ki": "namek_ki_burst",
        "skills": ["namek_ki_burst", "masenko", "demon_hand", "regeneration", "namek_burst", "giant_namek"],
        "transformation": "giant_namek",
        "color": "#5ad27e"
    },
    "Majin": {
        "description": "Cuerpos elásticos y absurdamente resistentes. Sus técnicas deforman, controlan y regeneran el cuerpo.",
        "stats": {"vitality": 13, "attack_stat": 10, "ki_power": 10, "armor": 11, "speed_stat": 8, "crit_chance": 5.0, "crit_damage": 155.0, "ki_regen": 9.0, "dodge_chance": 3.0},
        "starter_ki": "majin_ki_burst",
        "skills": ["majin_ki_burst", "majin_beam", "body_stretch", "majin_regeneration", "candy_beam", "pure_majin"],
        "transformation": "pure_majin",
        "color": "#e08ab6"
    },
    "Raza Helada": {
        "description": "Especialistas en precisión y control. Sus rayos perforantes y barreras compensan una defensa base moderada.",
        "stats": {"vitality": 9, "attack_stat": 10, "ki_power": 13, "armor": 9, "speed_stat": 11, "crit_chance": 7.0, "crit_damage": 165.0, "ki_regen": 12.0, "dodge_chance": 4.0},
        "starter_ki": "frost_ki_burst",
        "skills": ["frost_ki_burst", "death_beam", "telekinesis", "tail_strike", "frost_barrier", "golden_frost"],
        "transformation": "golden_frost",
        "color": "#d9efff"
    }
}

func get_data(race: String) -> Dictionary:
    return RACES.get(race, RACES["Saiyan"])

func names() -> Array[String]:
    var out: Array[String] = []
    for r in RACES.keys(): out.append(str(r))
    return out

func is_allowed(race: String, skill_id: String) -> bool:
    if SkillManager.SKILLS.has(skill_id) and str(SkillManager.SKILLS[skill_id].get("race", "")) == "Universal":
        return true
    var data: Dictionary = get_data(race)
    return skill_id in data.get("skills", [])

func starter_ki_skill(race: String) -> String:
    return str(get_data(race).get("starter_ki", "saiyan_ki_burst"))

func starter_skill(race: String) -> String:
    # Kept as a compatibility alias for older tools. The actual game begins with punch only.
    return starter_ki_skill(race)

func allowed_skills(race: String) -> Array:
    var out: Array = ["basic_punch"]
    out.append_array(get_data(race).get("skills", []).duplicate())
    out.append("barrier")
    return out

func set_race_defaults(race: String, preserve_progress := true) -> void:
    var old_power := GameState.power
    var old_potential := GameState.potential_points
    GameState.race = race
    var data := get_data(race)
    for stat in ["vitality", "attack_stat", "ki_power", "armor", "speed_stat"]:
        GameState.set(stat, int(data.stats.get(stat, GameState.get(stat))))
    for stat in ["crit_chance", "crit_damage", "ki_regen", "dodge_chance"]:
        GameState.set(stat, float(data.stats.get(stat, GameState.get(stat))))
    GameState.defense = GameState.armor
    for stat in GameState.stat_upgrade_counts.keys():
        GameState.stat_upgrade_counts[stat] = 0
    if preserve_progress:
        GameState.power = old_power
        GameState.potential_points = old_potential
    GameState.learned_skills.clear()
    GameState.skill_ranks.clear()
    GameState.learned_skills.append("basic_punch")
    GameState.skill_ranks["basic_punch"] = 1
    GameState.transformation = "base"
    GameState.changed.emit()
    changed.emit()

func validate_loadout() -> void:
    var allowed := allowed_skills(GameState.race)
    var clean: Array[String] = []
    for id in GameState.learned_skills:
        if id in allowed:
            clean.append(id)
    GameState.learned_skills = clean
