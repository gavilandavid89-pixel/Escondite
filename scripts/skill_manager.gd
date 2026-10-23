extends Node

signal changed

const SKILLS := {
    # Universal skills. Basic punch is the default execution skill; Barrier is available to every race.
    "basic_punch": {"name":"Puño Básico", "cost":1, "cooldown":1.0, "type":"basic_melee", "damage":1, "potential_cost":0, "race":"Universal", "description":"Ataque físico simple. Consume 1 KI y se recupera cada segundo.", "cost_mult":1.0, "tags":"básico • físico • 1s", "icon":"res://assets/skills/icons/basic_punch.svg", "effect_dir":"res://assets/skills/effects/basic_punch"},
    "barrier": {"name":"Barrera", "cost":24, "cooldown":12.0, "type":"barrier", "damage":0, "potential_cost":0, "race":"Universal", "description":"Escudo que cubre al guerrero. Mientras dura, cada golpe de un mob o jefe inflige exactamente 1 daño. Solo el rango aumenta su duración.", "cost_mult":1.45, "barrier_duration":4.0, "tags":"universal • escudo • 1 daño", "icon":"res://assets/skills/icons/barrier.svg", "effect_dir":"res://assets/skills/effects/barrier"},
    # Saiyan: explosive offense, momentum and transformations.
    "saiyan_ki_burst": {"name":"Ráfaga Saiyan", "cost":12, "cooldown":0.6, "type":"projectile", "damage":46, "potential_cost":0, "race":"Saiyan", "description":"Ráfaga corta y agresiva. Golpea más fuerte tras un combo aéreo.", "cost_mult": 0.85, "tags":"KI • ofensiva", "icon":"res://assets/skills/icons/saiyan_ki_burst.svg", "effect_dir":"res://assets/skills/effects/saiyan_ki_burst"},
    "galick_gun": {"name":"Galick Gun", "cost":48, "cooldown":4.8, "type":"beam", "damage":150, "potential_cost":18, "race":"Saiyan", "description":"Haz violeta de alta presión; daño alto y directo.", "cost_mult": 1.18, "tags":"KI • haz • daño alto", "icon":"res://assets/skills/icons/galick_gun.svg", "effect_dir":"res://assets/skills/effects/galick_gun"},
    "kaioken": {"name":"Kaioken", "cost":36, "cooldown":9.0, "type":"buff", "damage":0, "potential_cost":24, "race":"Saiyan", "description":"Fuerza y velocidad extremas. Consume vida lentamente mientras está activo.", "cost_mult": 1.55, "tags":"buff • riesgo HP • velocidad", "icon":"res://assets/skills/icons/kaioken.svg", "transform_damage_bonus": 0.20, "transform_speed_bonus": 0.26, "transform_armor_bonus": 0.00, "transform_crit_bonus": 0.00, "effect_dir":"res://assets/skills/effects/kaioken"},
    "meteor_crash": {"name":"Meteor Crash", "cost":44, "cooldown":5.5, "type":"melee", "damage":125, "potential_cost":28, "race":"Saiyan", "description":"Combo cuerpo a cuerpo que recompensa atacar desde el aire.", "cost_mult": 1.12, "tags":"combo • aéreo • melee", "icon":"res://assets/skills/icons/meteor_crash.svg", "effect_dir":"res://assets/skills/effects/meteor_crash"},
    "super_saiyan": {"name":"Super Saiyan", "cost":70, "cooldown":20.0, "type":"transform", "damage":0, "potential_cost":55, "race":"Saiyan", "transform":"super_saiyan", "description":"Aumenta daño y velocidad; aura dorada.", "cost_mult": 2.00, "tags":"transformación • curación por golpe", "icon":"res://assets/skills/icons/super_saiyan.svg", "on_hit_heal_pct": 2.50, "transform_damage_bonus": 0.22, "transform_speed_bonus": 0.16, "transform_armor_bonus": 0.08, "transform_crit_bonus": 2.00, "effect_dir":"res://assets/skills/effects/super_saiyan"},
    "super_saiyan_2": {"name":"Super Saiyan 2", "cost":95, "cooldown":26.0, "type":"transform", "damage":0, "potential_cost":95, "race":"Saiyan", "transform":"super_saiyan_2", "description":"Forma avanzada con descarga eléctrica y gran poder.", "cost_mult": 2.25, "tags":"transformación • aura • curación por golpe", "icon":"res://assets/skills/icons/super_saiyan_2.svg", "on_hit_heal_pct": 3.50, "transform_damage_bonus": 0.34, "transform_speed_bonus": 0.24, "transform_armor_bonus": 0.12, "transform_crit_bonus": 3.00, "effect_dir":"res://assets/skills/effects/super_saiyan_2"},

    # Human: precision, technique, control and potential.
    "human_ki_burst": {"name":"Ráfaga Humana", "cost":12, "cooldown":0.6, "type":"projectile", "damage":42, "potential_cost":0, "race":"Humano", "description":"Disparo preciso; ligeramente mejor rendimiento contra enemigos de poder similar.", "cost_mult": 0.85, "tags":"KI • precisión", "icon":"res://assets/skills/icons/human_ki_burst.svg", "effect_dir":"res://assets/skills/effects/human_ki_burst"},
    "kamehameha": {"name":"Kamehameha", "cost":42, "cooldown":4.2, "type":"beam", "damage":128, "potential_cost":18, "race":"Humano", "description":"Haz cargado de gran estabilidad y alcance.", "cost_mult": 1.15, "tags":"haz • carga • alcance", "icon":"res://assets/skills/icons/kamehameha.svg", "effect_dir":"res://assets/skills/effects/kamehameha"},
    "solar_flare": {"name":"Taiyōken", "cost":28, "cooldown":6.0, "type":"single_control", "damage":34, "potential_cost":22, "race":"Humano", "description":"Destello cegador de un solo objetivo; el rango aumenta al subir de nivel.", "cost_mult": 1.42, "tags":"objetivo único • ceguera • rango", "enemy_effect":"blind", "blind_duration":1.8, "icon":"res://assets/skills/icons/solar_flare.svg", "effect_dir":"res://assets/skills/effects/solar_flare"},
    "wolf_fang_fist": {"name":"Puño Lobo", "cost":30, "cooldown":3.4, "type":"melee", "damage":102, "potential_cost":27, "race":"Humano", "description":"Cadena marcial rápida con gran bonificación aérea.", "cost_mult": 1.12, "tags":"combo • aéreo • crítico", "icon":"res://assets/skills/icons/wolf_fang_fist.svg", "effect_dir":"res://assets/skills/effects/wolf_fang_fist"},
    "spirit_focus": {"name":"Concentración Espiritual", "cost":38, "cooldown":8.0, "type":"heal", "damage":0, "potential_cost":35, "race":"Humano", "description":"Recupera HP y KI. El estilo humano convierte control en supervivencia.", "cost_mult": 1.45, "tags":"curación • KI", "icon":"res://assets/skills/icons/spirit_focus.svg", "effect_dir":"res://assets/skills/effects/spirit_focus"},
    "potential_unleashed": {"name":"Potencial Liberado", "cost":72, "cooldown":22.0, "type":"transform", "damage":0, "potential_cost":70, "race":"Humano", "transform":"potential_unleashed", "description":"Desata el potencial dormido sin depender de una transformación Saiyan.", "cost_mult": 1.90, "tags":"transformación • daño", "icon":"res://assets/skills/icons/potential_unleashed.svg", "transform_damage_bonus": 0.26, "transform_speed_bonus": 0.14, "transform_armor_bonus": 0.10, "transform_crit_bonus": 2.00, "effect_dir":"res://assets/skills/effects/potential_unleashed"},

    # Namekian: regeneration, reach and area control.
    "namek_ki_burst": {"name":"Ráfaga Namekiana", "cost":12, "cooldown":0.6, "type":"projectile", "damage":44, "potential_cost":0, "race":"Namekiano", "description":"KI verde concentrado; daño estable y eficiente.", "cost_mult": 0.85, "tags":"KI • eficiente", "icon":"res://assets/skills/icons/namek_ki_burst.svg", "effect_dir":"res://assets/skills/effects/namek_ki_burst"},
    "masenko": {"name":"Masenko", "cost":38, "cooldown":3.7, "type":"beam", "damage":112, "potential_cost":18, "race":"Namekiano", "description":"Haz concentrado con alcance largo.", "cost_mult": 1.10, "tags":"haz • alcance", "icon":"res://assets/skills/icons/masenko.svg", "effect_dir":"res://assets/skills/effects/masenko"},
    "demon_hand": {"name":"Brazo Demonio", "cost":34, "cooldown":5.5, "type":"ranged_melee", "damage":118, "potential_cost":25, "race":"Namekiano", "description":"Extiende el brazo para golpear a distancia sin abandonar el control terrestre.", "cost_mult": 1.18, "tags":"alcance • melee", "icon":"res://assets/skills/icons/demon_hand.svg", "effect_dir":"res://assets/skills/effects/demon_hand"},
    "regeneration": {"name":"Regeneración", "cost":44, "cooldown":9.0, "type":"heal", "damage":0, "potential_cost":30, "race":"Namekiano", "description":"Regenera una gran cantidad de HP, identidad central de la raza.", "cost_mult": 1.45, "tags":"curación • tanque", "icon":"res://assets/skills/icons/regeneration.svg", "effect_dir":"res://assets/skills/effects/regeneration"},
    "namek_burst": {"name":"Explosión Namekiana", "cost":58, "cooldown":7.0, "type":"area", "damage":165, "potential_cost":48, "race":"Namekiano", "description":"Explosión circular de gran daño que golpea a todos los enemigos cercanos.", "cost_mult": 1.35, "tags":"área • daño alto", "icon":"res://assets/skills/icons/namek_burst.svg", "effect_dir":"res://assets/skills/effects/namek_burst"},
    "giant_namek": {"name":"Gigante Namekiano", "cost":82, "cooldown":24.0, "type":"transform", "damage":0, "potential_cost":78, "race":"Namekiano", "transform":"giant_namek", "description":"Aumenta tamaño, alcance y resistencia.", "cost_mult": 1.85, "tags":"transformación • armadura • alcance", "icon":"res://assets/skills/icons/giant_namek.svg", "transform_damage_bonus": 0.28, "transform_speed_bonus": -0.20, "transform_armor_bonus": 0.28, "transform_crit_bonus": 0.00, "effect_dir":"res://assets/skills/effects/giant_namek"},

    # Majin: body manipulation, control and regeneration.
    "majin_ki_burst": {"name":"Ráfaga Majin", "cost":12, "cooldown":0.6, "type":"projectile", "damage":45, "potential_cost":0, "race":"Majin", "description":"Disparo rosado elástico; buen equilibrio entre daño y coste.", "cost_mult": 0.85, "tags":"KI • elástico", "icon":"res://assets/skills/icons/majin_ki_burst.svg", "effect_dir":"res://assets/skills/effects/majin_ki_burst"},
    "majin_beam": {"name":"Majin Beam", "cost":42, "cooldown":4.4, "type":"beam", "damage":132, "potential_cost":18, "race":"Majin", "description":"Haz rosado concentrado que inflige daño directo.", "cost_mult": 1.15, "tags":"haz • daño directo", "icon":"res://assets/skills/icons/majin_beam.svg", "effect_dir":"res://assets/skills/effects/majin_beam"},
    "body_stretch": {"name":"Cuerpo Elástico", "cost":28, "cooldown":3.0, "type":"ranged_melee", "damage":88, "potential_cost":22, "race":"Majin", "description":"Ataque cuerpo a cuerpo a distancia con enorme alcance horizontal.", "cost_mult": 1.10, "tags":"alcance • melee", "icon":"res://assets/skills/icons/body_stretch.svg", "effect_dir":"res://assets/skills/effects/body_stretch"},
    "majin_regeneration": {"name":"Regeneración Majin", "cost":48, "cooldown":8.0, "type":"heal", "damage":0, "potential_cost":28, "race":"Majin", "description":"Regenera rápidamente HP y reduce temporalmente el retroceso recibido.", "cost_mult": 1.45, "tags":"curación • resistencia", "icon":"res://assets/skills/icons/majin_regeneration.svg", "effect_dir":"res://assets/skills/effects/majin_regeneration"},
    "candy_beam": {"name":"Candy Beam", "cost":66, "cooldown":9.0, "type":"beam", "damage":95, "potential_cost":52, "race":"Majin", "description":"Haz de conversión que inflige daño directo; su valor está en el daño y no en aplicar control.", "cost_mult": 1.60, "tags":"haz • daño directo", "icon":"res://assets/skills/icons/candy_beam.svg", "effect_dir":"res://assets/skills/effects/candy_beam"},
    "pure_majin": {"name":"Pure Majin", "cost":84, "cooldown":24.0, "type":"transform", "damage":0, "potential_cost":80, "race":"Majin", "transform":"pure_majin", "description":"Forma Majin extrema centrada en velocidad y regeneración.", "cost_mult": 1.95, "tags":"transformación • curación • velocidad", "icon":"res://assets/skills/icons/pure_majin.svg", "on_hit_heal_pct": 2.00, "transform_damage_bonus": 0.20, "transform_speed_bonus": 0.12, "transform_armor_bonus": 0.22, "transform_crit_bonus": 1.00, "effect_dir":"res://assets/skills/effects/pure_majin"},

    # Frost race: precision, beam damage and defensive control.
    "frost_ki_burst": {"name":"Ráfaga Helada", "cost":12, "cooldown":0.6, "type":"projectile", "damage":47, "potential_cost":0, "race":"Raza Helada", "description":"Disparo preciso y rápido de KI frío.", "cost_mult": 0.90, "tags":"KI • precisión", "icon":"res://assets/skills/icons/frost_ki_burst.svg", "effect_dir":"res://assets/skills/effects/frost_ki_burst"},
    "death_beam": {"name":"Death Beam", "cost":46, "cooldown":3.8, "type":"beam", "damage":145, "potential_cost":20, "race":"Raza Helada", "description":"Haz perforante con alcance y precisión extremos.", "cost_mult": 1.35, "tags":"haz • perforación • precisión", "icon":"res://assets/skills/icons/death_beam.svg", "effect_dir":"res://assets/skills/effects/death_beam"},
    "telekinesis": {"name":"Telequinesis", "cost":38, "cooldown":5.8, "type":"projectile", "damage":84, "potential_cost":28, "race":"Raza Helada", "description":"Descarga psíquica concentrada que inflige daño directo.", "cost_mult": 1.38, "tags":"KI • daño directo", "icon":"res://assets/skills/icons/telekinesis.svg", "effect_dir":"res://assets/skills/effects/telekinesis"},
    "tail_strike": {"name":"Golpe de Cola", "cost":30, "cooldown":3.2, "type":"melee", "damage":112, "potential_cost":25, "race":"Raza Helada", "description":"Latigazo de cola con excelente alcance y velocidad.", "cost_mult": 1.12, "tags":"melee • alcance", "icon":"res://assets/skills/icons/tail_strike.svg", "effect_dir":"res://assets/skills/effects/tail_strike"},
    "frost_barrier": {"name":"Barrera Helada", "cost":42, "cooldown":8.0, "type":"defense", "damage":0, "potential_cost":34, "race":"Raza Helada", "description":"Escudo que reduce el daño recibido y refleja parte del empuje.", "cost_mult": 1.52, "tags":"defensa • reducción", "icon":"res://assets/skills/icons/frost_barrier.svg", "effect_dir":"res://assets/skills/effects/frost_barrier"},
    "golden_frost": {"name":"Golden Form", "cost":90, "cooldown":25.0, "type":"transform", "damage":0, "potential_cost":90, "race":"Raza Helada", "transform":"golden_frost", "description":"Forma dorada de velocidad y precisión máximas.", "cost_mult": 2.05, "tags":"transformación • crítico • velocidad", "icon":"res://assets/skills/icons/golden_frost.svg", "transform_damage_bonus": 0.31, "transform_speed_bonus": 0.25, "transform_armor_bonus": 0.08, "transform_crit_bonus": 4.00, "effect_dir":"res://assets/skills/effects/golden_frost"},
}


const RANK_COSTS := [5000, 10000, 25000, 60000, 100000, 160000, 250000, 500000, 1250000, 2000000]
const MAX_RANK := 10

func is_learned(id: String) -> bool:
    return GameState.learned_skills.has(id)

func is_allowed_for_race(id: String) -> bool:
    if not SKILLS.has(id):
        return false
    return RaceManager.is_allowed(GameState.race, id)

func ensure_basic_skill() -> void:
    if not GameState.learned_skills.has("basic_punch"):
        GameState.learned_skills.append("basic_punch")
        GameState.skill_ranks["basic_punch"] = 1

func is_universal_skill(id: String) -> bool:
    return SKILLS.has(id) and str(SKILLS[id].get("race", "")) == "Universal"

func is_free_second_skill(id: String) -> bool:
    return id == RaceManager.starter_ki_skill(GameState.race) and QuestManager.completed_count() >= 5

func cost_multiplier(id: String) -> float:
    if not SKILLS.has(id):
        return 1.0
    return maxf(0.50, float(SKILLS[id].get("cost_mult", 1.0)))

func unlock_cost(id: String) -> int:
    if not SKILLS.has(id):
        return 0
    return maxi(1, int(round(float(RANK_COSTS[0]) * cost_multiplier(id))))

func rank_cost(id: String, target_rank: int) -> int:
    if not SKILLS.has(id) or target_rank < 1 or target_rank > MAX_RANK:
        return 0
    return maxi(1, int(round(float(RANK_COSTS[target_rank - 1]) * cost_multiplier(id))))

func base_cost_for_rank(target_rank: int) -> int:
    if target_rank < 1 or target_rank > MAX_RANK:
        return 0
    return RANK_COSTS[target_rank - 1]

func can_learn(id: String) -> bool:
    if not SKILLS.has(id) or not is_allowed_for_race(id) or is_learned(id):
        return false
    if id == "basic_punch":
        return true
    if id == RaceManager.starter_ki_skill(GameState.race):
        return QuestManager.completed_count() >= 5
    return GameState.potential_points >= unlock_cost(id)

func learn(id: String) -> bool:
    if not can_learn(id):
        return false
    var cost := 0 if id == "basic_punch" or is_free_second_skill(id) else unlock_cost(id)
    if cost > 0 and not GameState.spend_potential(cost):
        return false
    GameState.learned_skills.append(id)
    GameState.skill_ranks[id] = 1
    GameState.race_mastery[GameState.race] = int(GameState.race_mastery.get(GameState.race, 0)) + 1
    GameState.changed.emit()
    changed.emit()
    SaveManager.save_game()
    return true

func unlock_second_skill_after_mission_five() -> String:
    var id := RaceManager.starter_ki_skill(GameState.race)
    if is_learned(id) or QuestManager.completed_count() < 5:
        return ""
    GameState.learned_skills.append(id)
    GameState.skill_ranks[id] = 1
    GameState.race_mastery[GameState.race] = int(GameState.race_mastery.get(GameState.race, 0)) + 1
    GameState.changed.emit()
    changed.emit()
    SaveManager.save_game()
    return id

func data(id: String) -> Dictionary:
    return SKILLS.get(id, {})

func rank(id: String) -> int:
    return clampi(int(GameState.skill_ranks.get(id, 0)), 0, MAX_RANK)

func max_rank(id: String) -> int:
    return MAX_RANK if SKILLS.has(id) else 0

func upgrade_cost(id: String) -> int:
    var r := rank(id)
    if r <= 0 or r >= MAX_RANK:
        return 0
    return rank_cost(id, r + 1)

func can_upgrade(id: String) -> bool:
    if not is_learned(id):
        return false
    var cost := upgrade_cost(id)
    return cost > 0 and GameState.potential_points >= cost

func upgrade(id: String) -> bool:
    if not can_upgrade(id):
        return false
    var cost := upgrade_cost(id)
    if not GameState.spend_potential(cost):
        return false
    GameState.skill_ranks[id] = rank(id) + 1
    GameState.changed.emit()
    changed.emit()
    SaveManager.save_game()
    return true

func rank_strength(id: String) -> float:
    var r := rank(id)
    return 1.0 if r <= 1 else 1.0 + 0.085 * float(r - 1)

func damage_at_rank(id: String, target_rank: int) -> int:
    var base := int(data(id).get("damage", 0))
    if base <= 0 or target_rank <= 0:
        return base
    var strength := 1.0 if target_rank <= 1 else 1.0 + 0.085 * float(target_rank - 1)
    return maxi(1, int(round(float(base) * strength)))

func effect_summary(id: String) -> String:
    if not SKILLS.has(id):
        return ""
    var d := data(id)
    var tags_text := str(d.get("tags", ""))
    var desc := str(d.get("description", ""))
    return "%s\n%s" % [tags_text, desc] if tags_text != "" else desc

func damage(id: String) -> int:
    var base := int(data(id).get("damage", 0))
    if base <= 0 or rank(id) <= 0:
        return base
    return maxi(1, int(round(float(base) * rank_strength(id))))

func ki_cost(id: String) -> int:
    var base := int(data(id).get("cost", 0))
    var r := rank(id)
    if base <= 0 or r <= 1:
        return base
    return maxi(1, int(round(float(base) * (1.0 - 0.028 * float(r - 1)))))

func cooldown(id: String) -> float:
    var base := float(data(id).get("cooldown", 0.0))
    var r := rank(id)
    if base <= 0.0 or r <= 1:
        return base
    return maxf(0.22, base * (1.0 - 0.034 * float(r - 1)))

func effect_strength(id: String) -> float:
    return rank_strength(id)

func transformation_skill_id(transform_name: String) -> String:
    if transform_name == "base" or transform_name == "":
        return ""
    for raw_id in SKILLS.keys():
        var id := str(raw_id)
        if str(SKILLS[id].get("transform", "")) == transform_name:
            return id
    return ""

func transformation_damage_multiplier(transform_name: String) -> float:
    var id := transformation_skill_id(transform_name)
    if id == "":
        return 1.0
    var d := data(id)
    var bonus := float(d.get("transform_damage_bonus", 0.0))
    return 1.0 + bonus * effect_strength(id)

func transformation_speed_multiplier(transform_name: String) -> float:
    var id := transformation_skill_id(transform_name)
    if id == "":
        return 1.0
    var d := data(id)
    var bonus := float(d.get("transform_speed_bonus", 0.0))
    return maxf(0.45, 1.0 + bonus * effect_strength(id))

func transformation_armor_multiplier(transform_name: String) -> float:
    var id := transformation_skill_id(transform_name)
    if id == "":
        return 1.0
    var d := data(id)
    var bonus := float(d.get("transform_armor_bonus", 0.0))
    return 1.0 + bonus * effect_strength(id)

func transformation_crit_bonus(transform_name: String) -> float:
    var id := transformation_skill_id(transform_name)
    if id == "":
        return 0.0
    var d := data(id)
    return float(d.get("transform_crit_bonus", 0.0)) * effect_strength(id)

func active_transform_heal_percent(transform_name: String) -> float:
    var id := transformation_skill_id(transform_name)
    if id == "":
        return 0.0
    var pct := float(data(id).get("on_hit_heal_pct", 0.0))
    return pct * effect_strength(id)

func enemy_effect(id: String) -> String:
    return str(data(id).get("enemy_effect", ""))

func blind_duration(id: String) -> float:
    var base := float(data(id).get("blind_duration", 0.0))
    if base <= 0.0:
        return 0.0
    return base * (0.82 + 0.065 * float(maxi(1, rank(id)) - 1))

func barrier_duration(id: String) -> float:
    if id != "barrier":
        return 0.0
    var r := maxi(1, rank(id))
    # Only duration scales. Damage taken stays exactly 1 at every rank.
    return float(data(id).get("barrier_duration", 4.0)) + 0.70 * float(r - 1)

func effect_range(id: String) -> float:
    if id != "solar_flare":
        return 0.0
    var r := maxi(1, rank(id))
    # Taiyōken is intentionally single-target; rank increases reach, not target count.
    return 165.0 + 34.0 * float(r - 1)

func tags(id: String) -> String:
    return str(data(id).get("tags", ""))

func icon_path(id: String) -> String:
    return str(data(id).get("icon", ""))

func effect_dir(id: String) -> String:
    return str(data(id).get("effect_dir", ""))

func learned_list() -> Array[String]:
    return GameState.learned_skills.duplicate()

func race_skills(race: String) -> Array[String]:
    var out: Array[String] = []
    for id in SKILLS.keys():
        if str(SKILLS[id].get("race", "")) == race:
            out.append(str(id))
    return out