extends Node

signal changed
signal power_changed(value: int)
signal potential_changed(value: int)

var player_name := "Goku"
var race := "Saiyan"

# Dragon Realm has no character levels. Power is the only progression number.
var power := 10
var potential_points := 0

var hp := 140
var ki := 120
var zeni := 80
# Combat attributes purchased with Potential. Each attribute has its own upgrade counter.
var vitality := 10
var attack_stat := 10
var ki_power := 10
var armor := 8
var speed_stat := 8
var crit_chance := 5.0
var crit_damage := 150.0
var ki_regen := 10.0
var dodge_chance := 3.0
# Legacy alias kept for old content/equipment. New systems should use armor.
var defense := 8
var stat_upgrade_counts: Dictionary = {
    "vitality": 0, "attack_stat": 0, "ki_power": 0, "armor": 0,
    "speed_stat": 0, "crit_chance": 0, "crit_damage": 0,
    "ki_regen": 0, "dodge_chance": 0
}
var last_damage_was_critical := false
var flight_unlocked := false
var flight_enabled := false
var chapter := 1
var race_mastery := {}
var current_zone := "valley"
var position_x := 260.0
var position_y := 560.0
var learned_skills: Array[String] = []
var skill_ranks: Dictionary = {}
var transformation := "base"
var equipment := {"armor": "novice_gi", "accessory": "training_band"}
var inventory: Dictionary = {"senzu": 3, "water": 5, "iron": 4, "novice_gi": 1, "training_band": 1}
var achievements: Array[String] = []
var friends: Array[String] = []
var clan_name := "Sin clan"
var clan_level := 0
var collected_orbs: Array[String] = []
var kill_counts: Dictionary = {}
var discovered_zones: Array[String] = ["valley"]
var boss_flags: Dictionary = {}
var music_muted := false
var sfx_muted := false

func reset_new_game() -> void:
    player_name = "Goku"
    race = "Saiyan"
    power = 10
    potential_points = 0
    hp = 140
    ki = 120
    zeni = 80
    vitality = 10
    attack_stat = 10
    ki_power = 10
    armor = 8
    speed_stat = 8
    crit_chance = 5.0
    crit_damage = 150.0
    ki_regen = 10.0
    dodge_chance = 3.0
    defense = 8
    stat_upgrade_counts = {
        "vitality": 0, "attack_stat": 0, "ki_power": 0, "armor": 0,
        "speed_stat": 0, "crit_chance": 0, "crit_damage": 0,
        "ki_regen": 0, "dodge_chance": 0
    }
    last_damage_was_critical = false
    flight_unlocked = false
    flight_enabled = false
    chapter = 1
    race_mastery = {"Saiyan":0,"Humano":0,"Namekiano":0,"Majin":0,"Raza Helada":0}
    current_zone = "valley"
    position_x = 260.0
    position_y = 560.0
    learned_skills.clear()
    skill_ranks.clear()
    learned_skills.append("basic_punch")
    skill_ranks["basic_punch"] = 1
    transformation = "base"
    equipment = {"armor": "novice_gi", "accessory": "training_band"}
    inventory = {"senzu": 3, "water": 5, "iron": 4, "novice_gi": 1, "training_band": 1}
    achievements.clear()
    friends.clear()
    clan_name = "Sin clan"
    clan_level = 0
    collected_orbs.clear()
    kill_counts.clear()
    discovered_zones = ["valley"]
    boss_flags.clear()
    music_muted = false
    sfx_muted = false
    changed.emit()
    power_changed.emit(power)
    potential_changed.emit(potential_points)

func combat_power() -> int:
    return power

func attack_power() -> int:
    # Power is the main combat scale; Potential-funded Attack remains a meaningful build choice.
    return maxi(1, int(round(float(power) * 0.25)) + attack_stat * 2 + InventoryManager.equipment_bonus("strength"))

func ki_damage() -> int:
    return maxi(1, int(round(float(power) * 0.20)) + ki_power * 2 + InventoryManager.equipment_bonus("strength"))

func max_hp() -> int:
    return maxi(1, 100 + int(round(float(power) * 1.60)) + vitality * 5 + InventoryManager.equipment_bonus("hp"))

func max_ki() -> int:
    return maxi(1, 70 + int(round(float(power) * 0.35)) + ki_power * 8 + InventoryManager.equipment_bonus("ki"))

func move_speed() -> float:
    return 188.0 + speed_stat * 3.0 + log(float(power) + 1.0) * 18.0

func armor_value() -> int:
    return armor + InventoryManager.equipment_bonus("defense") + int((vitality - 10) * 0.25)

func armor_rating() -> float:
    return maxf(1.0, sqrt(float(power)) * 2.5 + float(armor_value()) * 10.0)

func damage_reduction_from_armor(rating: float) -> float:
    # Soft-cap at 45% so armor remains valuable without making high-Power fights invulnerable.
    return clampf(0.45 * rating / (rating + 180.0), 0.0, 0.45)

func ki_regen_rate() -> float:
    return 7.0 + ki_regen * 0.55 + log(float(power) + 1.0) * 2.5

func critical_damage(base_damage: int) -> int:
    var effective_crit := crit_chance + SkillManager.transformation_crit_bonus(transformation)
    last_damage_was_critical = randf() * 100.0 < effective_crit
    if last_damage_was_critical:
        return maxi(base_damage + 1, int(round(float(base_damage) * (crit_damage / 100.0))))
    return base_damage

func stat_upgrade_cost(stat: String) -> int:
    if not stat_upgrade_counts.has(stat):
        return 999999
    return 1 + int(stat_upgrade_counts.get(stat, 0))

func spend_stat(stat: String) -> bool:
    if not stat_upgrade_counts.has(stat):
        return false
    var cost := stat_upgrade_cost(stat)
    if potential_points < cost:
        return false
    potential_points -= cost
    stat_upgrade_counts[stat] = int(stat_upgrade_counts.get(stat, 0)) + 1
    set(stat, get(stat) + 1)
    if stat == "armor":
        defense = armor
    elif stat == "speed_stat":
        speed_stat = int(speed_stat)
    changed.emit()
    potential_changed.emit(potential_points)
    return true

func stat_display_name(stat: String) -> String:
    return {
        "vitality": "Vida", "attack_stat": "Ataque", "ki_power": "KI",
        "armor": "Armadura", "speed_stat": "Velocidad", "crit_chance": "Crítico %",
        "crit_damage": "Daño crítico %", "ki_regen": "Regeneración KI",
        "dodge_chance": "Evasión %"
    }.get(stat, stat)

func stat_value_text(stat: String) -> String:
    var value = get(stat)
    if stat in ["crit_chance", "crit_damage", "dodge_chance", "ki_regen"]:
        return "%.1f" % float(value)
    return str(int(value))

func stat_effect_text(stat: String) -> String:
    match stat:
        "vitality": return "+12 HP máximo por punto"
        "attack_stat": return "+2 daño físico por punto"
        "ki_power": return "+8 KI máximo / +2 daño KI"
        "armor": return "+1 reducción de daño"
        "speed_stat": return "+3 velocidad"
        "crit_chance": return "+1% probabilidad de crítico"
        "crit_damage": return "+1% multiplicador de crítico"
        "ki_regen": return "+0.55 KI/s"
        "dodge_chance": return "+1% evasión"
    return ""

# Power earned from a hit uses both the enemy's power and how much of its body
# was actually damaged by the player's attack. The relative-power factor makes
# early mobs converge to ~1 power per hit once they become trivial.
func calculate_hit_gain(enemy_power: int, damage: int, target_max_hp: int) -> int:
    if enemy_power <= 0 or damage <= 0 or target_max_hp <= 0:
        return 0
    var relative := clampf(float(enemy_power) / maxf(float(power), 10.0), 0.05, 2.5)
    var damage_share := clampf(float(damage) / float(target_max_hp), 0.01, 0.50)
    var difficulty_factor := pow(relative, 0.45)
    var raw := float(enemy_power) * damage_share * difficulty_factor * 0.12
    return maxi(1, int(round(raw)))

func gain_power(amount: int, potential_amount: int = -1) -> void:
    if amount <= 0:
        return
    power += amount
    var pot := amount if potential_amount < 0 else maxi(0, potential_amount)
    potential_points += pot
    if not flight_unlocked and power >= 250:
        flight_unlocked = true
    changed.emit()
    power_changed.emit(power)
    potential_changed.emit(potential_points)

func spend_potential(amount: int) -> bool:
    if amount <= 0 or potential_points < amount:
        return false
    potential_points -= amount
    changed.emit()
    potential_changed.emit(potential_points)
    return true

func potential_cost_for_stat(stat: String) -> int:
    return stat_upgrade_cost(stat)

func record_kill(mob_id: String) -> void:
    kill_counts[mob_id] = int(kill_counts.get(mob_id, 0)) + 1
    changed.emit()

func record_zone(zone_id: String) -> void:
    if not discovered_zones.has(zone_id):
        discovered_zones.append(zone_id)
        changed.emit()
