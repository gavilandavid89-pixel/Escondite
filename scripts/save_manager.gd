extends Node

const SAVE_PATH := "user://dragon_realm_save.json"
const SAVE_VERSION := 8

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func save_game() -> bool:
    var data := {
        "version": SAVE_VERSION,
        "player_name": GameState.player_name,
        "race": GameState.race,
        "power": GameState.power,
        "potential_points": GameState.potential_points,
        "hp": GameState.hp,
        "ki": GameState.ki,
        "zeni": GameState.zeni,
        "vitality": GameState.vitality,
        "attack_stat": GameState.attack_stat,
        "ki_power": GameState.ki_power,
        "armor": GameState.armor,
        "speed_stat": GameState.speed_stat,
        "crit_chance": GameState.crit_chance,
        "crit_damage": GameState.crit_damage,
        "ki_regen": GameState.ki_regen,
        "dodge_chance": GameState.dodge_chance,
        "stat_upgrade_counts": GameState.stat_upgrade_counts,
        "flight_unlocked": GameState.flight_unlocked,
        "chapter": GameState.chapter,
        "race_mastery": GameState.race_mastery,
        "current_zone": GameState.current_zone,
        "position_x": GameState.position_x,
        "position_y": GameState.position_y,
        "learned_skills": GameState.learned_skills,
        "skill_ranks": GameState.skill_ranks,
        "transformation": GameState.transformation,
        "equipment": GameState.equipment,
        "inventory": GameState.inventory,
        "achievements": GameState.achievements,
        "friends": GameState.friends,
        "clan_name": GameState.clan_name,
        "clan_level": GameState.clan_level,
        "collected_orbs": GameState.collected_orbs,
        "kill_counts": GameState.kill_counts,
        "discovered_zones": GameState.discovered_zones,
        "boss_flags": GameState.boss_flags,
        "quests": QuestManager.serialize_state()
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data))
    file.close()
    return true

func load_game() -> bool:
    if not has_save():
        return false
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return false
    var raw := file.get_as_text()
    file.close()
    var data = JSON.parse_string(raw)
    if not (data is Dictionary):
        return false

    GameState.player_name = str(data.get("player_name", "Goku"))
    GameState.race = str(data.get("race", "Saiyan"))

    # Migration from the old prototype. Legacy level/XP saves are converted once into
    # Power so existing players keep their progress; character levels no longer exist.
    var migrated_power := int(data.get("power", 0))
    if migrated_power <= 0:
        var old_level := int(data.get("level", 1))
        migrated_power = 10 + maxi(0, old_level - 1) * 12 + int(data.get("xp", 0) / 100)
    GameState.power = maxi(10, migrated_power)
    GameState.potential_points = int(data.get("potential_points", data.get("skill_points", 0) + data.get("stat_points", 0)))
    GameState.hp = int(data.get("hp", GameState.max_hp()))
    GameState.ki = int(data.get("ki", GameState.max_ki()))
    GameState.zeni = int(data.get("zeni", 80))
    GameState.vitality = int(data.get("vitality", 10))
    GameState.attack_stat = int(data.get("attack_stat", data.get("strength", 10)))
    GameState.ki_power = int(data.get("ki_power", 10))
    GameState.armor = int(data.get("armor", data.get("defense", 8)))
    GameState.speed_stat = int(data.get("speed_stat", 8))
    GameState.crit_chance = float(data.get("crit_chance", 5.0))
    GameState.crit_damage = float(data.get("crit_damage", 150.0))
    GameState.ki_regen = float(data.get("ki_regen", 10.0))
    GameState.dodge_chance = float(data.get("dodge_chance", 3.0))
    GameState.stat_upgrade_counts = Dictionary(data.get("stat_upgrade_counts", {"vitality":0,"attack_stat":0,"ki_power":0,"armor":0,"speed_stat":0,"crit_chance":0,"crit_damage":0,"ki_regen":0,"dodge_chance":0}))
    GameState.defense = GameState.armor
    GameState.flight_unlocked = bool(data.get("flight_unlocked", GameState.power >= 250))
    GameState.chapter = int(data.get("chapter", 1))
    GameState.race_mastery = data.get("race_mastery", GameState.race_mastery) if data.get("race_mastery", {}) is Dictionary else GameState.race_mastery
    GameState.current_zone = str(data.get("current_zone", "valley"))
    GameState.position_x = float(data.get("position_x", 260.0))
    GameState.position_y = float(data.get("position_y", 560.0))
    GameState.learned_skills.clear()
    var loaded_skills: Array = Array(data.get("learned_skills", []))
    for raw_skill in loaded_skills:
        GameState.learned_skills.append(str(raw_skill))
    if not GameState.learned_skills.has("basic_punch"):
        GameState.learned_skills.append("basic_punch")
    GameState.skill_ranks = Dictionary(data.get("skill_ranks", {}))
    for learned_id in GameState.learned_skills:
        if not GameState.skill_ranks.has(learned_id):
            GameState.skill_ranks[learned_id] = 1
    RaceManager.validate_loadout()
    GameState.transformation = str(data.get("transformation", "base"))
    GameState.equipment = Dictionary(data.get("equipment", {"armor": "novice_gi"}))
    GameState.inventory = Dictionary(data.get("inventory", {"senzu": 3, "water": 5}))
    GameState.achievements.clear()
    for raw_achievement in Array(data.get("achievements", [])):
        GameState.achievements.append(str(raw_achievement))
    GameState.friends.clear()
    for raw_friend in Array(data.get("friends", [])):
        GameState.friends.append(str(raw_friend))
    GameState.clan_name = str(data.get("clan_name", "Sin clan"))
    GameState.clan_level = int(data.get("clan_level", 0))
    GameState.collected_orbs.clear()
    for raw_orb in Array(data.get("collected_orbs", [])):
        GameState.collected_orbs.append(str(raw_orb))
    GameState.kill_counts = Dictionary(data.get("kill_counts", {}))
    GameState.discovered_zones.clear()
    for raw_zone in Array(data.get("discovered_zones", ["valley"])):
        GameState.discovered_zones.append(str(raw_zone))
    GameState.boss_flags = Dictionary(data.get("boss_flags", {}))
    QuestManager.deserialize_state(data.get("quests", {}))
    GameState.changed.emit()
    GameState.power_changed.emit(GameState.power)
    GameState.potential_changed.emit(GameState.potential_points)
    return true

func delete_save() -> void:
    if has_save():
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
