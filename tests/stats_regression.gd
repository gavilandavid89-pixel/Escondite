extends SceneTree

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var failures: Array[String] = []
    var gs: Node = get_root().get_node("GameState")
    var save: Node = get_root().get_node("SaveManager")
    gs.reset_new_game()
    gs.potential_points = 30

    for stat in ["vitality","attack_stat","ki_power","armor","crit_chance","crit_damage","speed_stat","ki_regen","dodge_chance"]:
        if gs.stat_upgrade_cost(stat) != 1:
            failures.append("initial_cost_%s" % stat)

    var old_hp: int = int(gs.max_hp())
    if not gs.spend_stat("vitality"): failures.append("buy_vitality")
    if gs.stat_upgrade_cost("vitality") != 2: failures.append("vitality_next_cost")
    if gs.max_hp() <= old_hp: failures.append("vitality_effect")

    var old_attack: int = int(gs.attack_power())
    if not gs.spend_stat("attack_stat"): failures.append("buy_attack")
    if gs.attack_power() <= old_attack: failures.append("attack_effect")

    var old_armor: int = int(gs.armor_value())
    if not gs.spend_stat("armor"): failures.append("buy_armor")
    if gs.armor_value() <= old_armor: failures.append("armor_effect")

    var old_ki: int = int(gs.max_ki())
    if not gs.spend_stat("ki_power"): failures.append("buy_ki")
    if gs.max_ki() <= old_ki: failures.append("ki_effect")

    if not gs.spend_stat("crit_chance"): failures.append("buy_crit")
    if gs.crit_chance != 6.0: failures.append("crit_effect")
    if not gs.spend_stat("crit_damage"): failures.append("buy_crit_damage")
    if gs.crit_damage != 151.0: failures.append("crit_damage_effect")

    var pot_after: int = int(gs.potential_points)
    if gs.spend_stat("dodge_chance") == false: failures.append("buy_dodge")
    if gs.potential_points >= pot_after: failures.append("potential_spent")

    var saved: bool = bool(save.save_game())
    if not saved: failures.append("save")
    var before_vitality: int = int(gs.vitality)
    gs.vitality = 1
    if not save.load_game(): failures.append("load")
    if gs.vitality != before_vitality: failures.append("stat_persistence")

    print("[STATS_TEST] %s" % ("PASS" if failures.is_empty() else "FAIL " + str(failures)))
    quit(0 if failures.is_empty() else 1)
