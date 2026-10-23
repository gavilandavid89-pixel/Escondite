extends SceneTree

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var failures: Array[String] = []
    var mob_catalog: Node = get_root().get_node("MobCatalog")
    var gs: Node = get_root().get_node("GameState")
    var normal: Dictionary = mob_catalog.derived_stats("wolf_raider", mob_catalog.lookup("wolf_raider"))
    var ranged: Dictionary = mob_catalog.derived_stats("frost_soldier", mob_catalog.lookup("frost_soldier"))
    var boss: Dictionary = mob_catalog.derived_stats("arena_champion", mob_catalog.lookup("arena_champion"))
    var synthetic: Dictionary = mob_catalog.derived_stats("janemba_like", {"power": 500000, "type": "boss", "boss": true, "speed": 120.0})

    if int(normal.hp) < 80 or int(normal.hp) > 110: failures.append("normal_hp_scale")
    if int(normal.attack) < 8 or int(normal.attack) > 13: failures.append("normal_attack_scale")
    if int(ranged.hp) < 350 or int(ranged.hp) > 430: failures.append("ranged_hp_scale")
    if int(boss.hp) < 1700 or int(boss.hp) > 2000: failures.append("boss_hp_scale")
    if int(boss.attack) < 90 or int(boss.attack) > 115: failures.append("boss_attack_scale")
    if int(boss.armor_rating) <= int(normal.armor_rating): failures.append("boss_armor_hidden_stat")
    if float(boss.crit_chance) <= float(normal.crit_chance): failures.append("boss_crit_hidden_stat")
    if int(synthetic.hp) < 3300000 or int(synthetic.hp) > 3500000: failures.append("500k_power_boss_hp")
    if int(synthetic.attack) < 185000 or int(synthetic.attack) > 195000: failures.append("500k_power_boss_attack")

    var player_attack := int(round(500000.0 * 0.25)) + 10 * 2
    var reduced_hit := maxi(1, int(round(float(player_attack) * (1.0 - gs.damage_reduction_from_armor(float(synthetic.armor_rating))))))
    var hits := int(ceil(float(synthetic.hp) / float(reduced_hit)))
    if hits < 20 or hits > 90: failures.append("equal_power_ttk_%d" % hits)

    print("[MOB_BALANCE_TEST] %s" % ("PASS" if failures.is_empty() else "FAIL " + str(failures)))
    quit(0 if failures.is_empty() else 1)
