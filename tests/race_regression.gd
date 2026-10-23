extends SceneTree

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var failures: Array[String] = []
    var gs: Node = get_root().get_node("GameState")
    var rm: Node = get_root().get_node("RaceManager")
    var sm: Node = get_root().get_node("SkillManager")
    var qm: Node = get_root().get_node("QuestManager")
    var expected := {
        "Saiyan": ["saiyan_ki_burst","galick_gun","kaioken","super_saiyan"],
        "Humano": ["human_ki_burst","kamehameha","solar_flare","potential_unleashed"],
        "Namekiano": ["namek_ki_burst","masenko","demon_hand","giant_namek"],
        "Majin": ["majin_ki_burst","majin_beam","candy_beam","pure_majin"],
        "Raza Helada": ["frost_ki_burst","death_beam","telekinesis","golden_frost"]
    }
    for race in rm.names():
        gs.reset_new_game()
        rm.set_race_defaults(race, false)
        rm.validate_loadout()
        if gs.power != 10: failures.append("%s_start_power" % race)
        if gs.potential_points != 0: failures.append("%s_start_potential" % race)
        if gs.learned_skills != ["basic_punch"]: failures.append("%s_should_start_basic_punch_only" % race)
        for id in expected[race]:
            if not rm.is_allowed(race, id): failures.append("%s_allowed_%s" % [race,id])
    gs.reset_new_game()
    rm.set_race_defaults("Saiyan", false)
    qm.reset()
    if sm.can_learn("saiyan_ki_burst"): failures.append("starter_ki_early")
    for id in ["valley_hunt","forest_hunt","desert_patrol","kame_raiders"]:
        qm.quests[id].completed = true
    if sm.can_learn("saiyan_ki_burst"): failures.append("starter_ki_before_5")
    qm.quests["master_training"].completed = true
    if not sm.can_learn("saiyan_ki_burst"): failures.append("starter_ki_after_5")
    if not sm.learn("saiyan_ki_burst"): failures.append("starter_ki_free_learn")
    gs.potential_points = sm.unlock_cost("galick_gun") + sm.rank_cost("galick_gun", 2) + 20
    if not sm.learn("galick_gun"): failures.append("advanced_learn")
    var before: int = int(gs.potential_points)
    if not sm.can_upgrade("galick_gun"): failures.append("upgrade_gate")
    if not sm.upgrade("galick_gun"): failures.append("upgrade_action")
    if gs.potential_points >= before: failures.append("upgrade_no_cost")
    if sm.rank("galick_gun") != 2: failures.append("upgrade_rank")
    for id in sm.SKILLS.keys():
        var data: Dictionary = sm.data(str(id))
        if str(data.get("race", "")) != "Saiyan" and sm.can_learn(str(id)):
            failures.append("illegal_skill_%s" % str(id))
    print("[RACE_REGRESSION] %s" % ("PASS" if failures.is_empty() else "FAIL "+str(failures)))
    quit(0 if failures.is_empty() else 1)
