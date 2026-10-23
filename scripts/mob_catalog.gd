extends Node

const MOBS := {
    "arena_champion": {"name":"Campeón de la Arena","power":270,"hp":2400,"speed":104.0,"damage":108,"zeni":650,"type":"boss","boss":true,"color":Color("#e69f46"),"accent":Color("#4d2d64"),"loot":["heavy_gi","zenicoin","dragon_orb"]},
    "wasteland_overlord": {"name":"Señor de la Tierra Devastada","power":430,"hp":3400,"speed":88.0,"damage":134,"zeni":900,"type":"boss","boss":true,"color":Color("#7e5a55"),"accent":Color("#e0bc68"),"loot":["dino_hide","galactic_badge","zenicoin"]},
    "otherworld_judge": {"name":"Juez del Otro Mundo","power":780,"hp":4600,"speed":115.0,"damage":168,"zeni":1300,"type":"boss","boss":true,"color":Color("#8f83e8"),"accent":Color("#f2d77c"),"loot":["karin_talisman","namek_crystal","zenicoin"]},
    "wolf_raider": {"name":"Lobo Salvaje","power":18,"hp":85,"speed":108.0,"damage":12,"zeni":8,"type":"melee","color":Color("#b8a58f"),"accent":Color("#6f5847"),"loot":["raw_meat","iron"]},
    "saibaman": {"name":"Saibaman","power":24,"hp":120,"speed":96.0,"damage":17,"zeni":12,"type":"melee","color":Color("#70d84d"),"accent":Color("#286d28"),"loot":["saibaman_seed","iron"]},
    "desert_bandit": {"name":"Bandido del Desierto","power":40,"hp":175,"speed":92.0,"damage":22,"zeni":18,"type":"melee","color":Color("#d2a15d"),"accent":Color("#5c3923"),"loot":["bandit_cloth","zenicoin"]},
    "dino_scavenger": {"name":"Dino Carroñero","power":48,"hp":230,"speed":78.0,"damage":26,"zeni":22,"type":"melee","color":Color("#c96d51"),"accent":Color("#61372f"),"loot":["dino_hide","raw_meat"]},
    "pirate_raider": {"name":"Pirata de Kame","power":58,"hp":250,"speed":102.0,"damage":29,"zeni":30,"type":"melee","color":Color("#5c89d6"),"accent":Color("#1c2f59"),"loot":["pirate_coin","bandit_cloth"]},
    "ice_wolf": {"name":"Lobo de Hielo","power":78,"hp":360,"speed":116.0,"damage":35,"zeni":36,"type":"melee","color":Color("#d6f1ff"),"accent":Color("#5c8fb8"),"loot":["ice_shard","raw_meat"]},
    "frost_soldier": {"name":"Soldado Glacial","power":90,"hp":430,"speed":82.0,"damage":38,"zeni":45,"type":"ranged","color":Color("#d9e9ff"),"accent":Color("#7657c8"),"loot":["ice_shard","galactic_badge"]},
    "namek_raider": {"name":"Asaltante de Namek","power":105,"hp":480,"speed":94.0,"damage":43,"zeni":52,"type":"ranged","color":Color("#64d1a0"),"accent":Color("#235f4b"),"loot":["namek_crystal","water"]},
    "saibaman_elite": {"name":"Saibaman Élite","power":120,"hp":600,"speed":108.0,"damage":50,"zeni":68,"type":"melee","color":Color("#b6e84c"),"accent":Color("#4c2a71"),"loot":["saibaman_seed","zenicoin","iron"]},
    "boar_brute": {"name":"Jabalí Montés","power":32,"hp":150,"speed":118.0,"damage":20,"zeni":14,"type":"melee","color":Color("#9a694f"),"accent":Color("#3f2b25"),"loot":["raw_meat","dino_hide"]},
    "dino_matriarch": {"name":"Dinosaurio Alfa","power":58,"hp":980,"speed":76.0,"damage":62,"zeni":180,"type":"boss","boss":true,"color":Color("#d87551"),"accent":Color("#5b3026"),"loot":["dino_hide","zenicoin","dragon_orb"]},
    "rr_scout": {"name":"Explorador del Ejército Red","power":68,"hp":280,"speed":92.0,"damage":34,"zeni":38,"type":"ranged","color":Color("#d83e4b"),"accent":Color("#202531"),"loot":["rr_insignia","iron"]},
    "rr_heavy": {"name":"Soldado Pesado Red","power":78,"hp":520,"speed":72.0,"damage":58,"zeni":75,"type":"melee","color":Color("#596473"),"accent":Color("#c13c43"),"loot":["rr_insignia","heavy_gi","iron"]},
    "rr_commander": {"name":"Comandante de Patrulla","power":90,"hp":1250,"speed":88.0,"damage":72,"zeni":260,"type":"boss","boss":true,"color":Color("#e4473f"),"accent":Color("#202531"),"loot":["rr_insignia","heavy_gi","zenicoin"]},
    "ice_commander": {"name":"Comandante Glacial","power":165,"hp":1700,"speed":92.0,"damage":86,"zeni":420,"type":"boss","boss":true,"color":Color("#b8e8ff"),"accent":Color("#5f4fc4"),"loot":["ice_shard","ice_guard","zenicoin"]},
    "namek_guardian": {"name":"Guardián Namekiano","power":140,"hp":760,"speed":84.0,"damage":64,"zeni":140,"type":"melee","color":Color("#55c58a"),"accent":Color("#203f35"),"loot":["namek_crystal","namek_charm"]},
    "galactic_raider": {"name":"Saqueador Galáctico","power":195,"hp":560,"speed":101.0,"damage":71,"zeni":130,"type":"ranged","color":Color("#7f8be8"),"accent":Color("#2c2f57"),"loot":["galactic_badge","ice_shard"]}
}

func role_for(id: String, data: Dictionary = {}) -> String:
    if bool(data.get("boss", false)) or str(data.get("type", "")) == "boss":
        return "boss"
    if str(data.get("type", "")) == "ranged":
        return "ranged"
    if str(data.get("elite", false)).to_lower() == "true" or id.contains("elite") or id.contains("commander"):
        return "elite"
    return "melee"

func derived_stats(id: String, data: Dictionary = {}) -> Dictionary:
    var power := maxi(1, int(data.get("power", 1)))
    var role := role_for(id, data)
    var hp_mult := 4.7
    var attack_mult := 0.55
    var armor_mult := 1.0
    var crit_chance := 3.0
    var crit_damage := 150.0
    var dodge := 1.5
    var ki_mult := 0.22
    match role:
        "ranged":
            hp_mult = 4.4
            attack_mult = 0.50
            armor_mult = 0.85
            crit_chance = 5.0
            crit_damage = 160.0
            dodge = 3.5
            ki_mult = 0.34
        "elite":
            hp_mult = 5.7
            attack_mult = 0.49
            armor_mult = 1.15
            crit_chance = 5.0
            crit_damage = 165.0
            dodge = 2.5
            ki_mult = 0.28
        "boss":
            hp_mult = 6.8
            attack_mult = 0.38
            armor_mult = 1.35
            crit_chance = 7.0
            crit_damage = 175.0
            dodge = 3.5
            ki_mult = 0.42
    var max_hp := maxi(1, int(round(float(power) * hp_mult)))
    var attack := maxi(1, int(round(float(power) * attack_mult)))
    var armor_rating := maxi(1, int(round((sqrt(float(power)) * 4.0 + float(power) * 0.0015) * armor_mult)))
    var ki := maxi(1, int(round(float(power) * ki_mult))
    crit_chance += minf(5.0, log(float(power) + 1.0) * 0.65)
    dodge += minf(3.0, log(float(power) + 1.0) * 0.30)
    return {"role":role,"power":power,"hp":max_hp,"attack":attack,"armor_rating":armor_rating,"ki_power":ki,"crit_chance":clampf(crit_chance,1.0,15.0),"crit_damage":crit_damage,"dodge_chance":clampf(dodge,1.0,10.0),"speed":float(data.get("speed",100.0))}

func power_to_expected_boss_hp(power: int) -> int:
    return int(round(float(power) * 6.8))

func lookup(id: String) -> Dictionary:
    return MOBS.get(id, {})

func name(id: String) -> String:
    return str(lookup(id).get("name", id))
