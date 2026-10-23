extends SceneTree

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var failures: Array[String] = []
    var gs: Node = get_root().get_node("GameState")
    var sm: Node = get_root().get_node("SkillManager")
    var rm: Node = get_root().get_node("RaceManager")
    var qm: Node = get_root().get_node("QuestManager")
    gs.reset_new_game()
    rm.set_race_defaults("Saiyan", false)
    qm.reset()

    var expected := [5000,10000,25000,60000,100000,160000,250000,500000,1250000,2000000]
    for r in range(1, 11):
        if sm.base_cost_for_rank(r) != expected[r-1]:
            failures.append("base_cost_%d" % r)

    for id in sm.SKILLS.keys():
        var sid := str(id)
        if sm.max_rank(sid) != 10:
            failures.append("max_rank_%s" % sid)
        if sm.icon_path(sid) == "" or not ResourceLoader.exists(sm.icon_path(sid)):
            failures.append("icon_%s" % sid)
        if sm.effect_dir(sid) == "":
            failures.append("effect_dir_%s" % sid)

    var ssj_unlock: int = sm.unlock_cost("super_saiyan")
    var ssj_rank2: int = sm.rank_cost("super_saiyan", 2)
    var burst_unlock: int = sm.unlock_cost("saiyan_ki_burst")
    if ssj_unlock <= burst_unlock:
        failures.append("transform_cost_not_higher")
    if ssj_rank2 <= sm.rank_cost("galick_gun", 2):
        failures.append("transform_upgrade_not_higher")

    if sm.can_learn("saiyan_ki_burst"):
        failures.append("ki_unlocked_early")
    for id in ["valley_hunt","forest_hunt","desert_patrol","kame_raiders","master_training"]:
        if qm.quests.has(id):
            qm.quests[id].completed = true
    if not sm.can_learn("saiyan_ki_burst"):
        failures.append("ki_not_unlocked_at_5")
    if not sm.learn("saiyan_ki_burst"):
        failures.append("ki_free_unlock")

    gs.potential_points = sm.rank_cost("super_saiyan", 2) + sm.unlock_cost("super_saiyan") + 50
    if not sm.learn("super_saiyan"):
        failures.append("ssj_unlock")
    var rank1_heal: float = sm.active_transform_heal_percent("super_saiyan")
    var rank1_damage: float = sm.transformation_damage_multiplier("super_saiyan")
    while sm.rank("super_saiyan") < 10:
        var cost: int = sm.upgrade_cost("super_saiyan")
        if cost <= 0:
            failures.append("upgrade_cost_zero_%d" % sm.rank("super_saiyan"))
            break
        gs.potential_points += cost
        if not sm.upgrade("super_saiyan"):
            failures.append("upgrade_rank_%d" % sm.rank("super_saiyan"))
            break
    if sm.rank("super_saiyan") != 10:
        failures.append("ssj_not_rank10")
    if sm.unlock_cost("super_saiyan") <= sm.unlock_cost("galick_gun"):
        failures.append("ssj_unlock_should_cost_more")
    if sm.unlock_cost("solar_flare") <= sm.unlock_cost("human_ki_burst"):
        failures.append("control_effect_not_priced")
    if sm.unlock_cost("regeneration") <= sm.unlock_cost("masenko"):
        failures.append("heal_effect_not_priced")
    if sm.damage_at_rank("galick_gun", 10) <= sm.damage_at_rank("galick_gun", 1):
        failures.append("rank10_damage_not_higher")
    if sm.active_transform_heal_percent("super_saiyan") <= rank1_heal:
        failures.append("ssj_heal_not_scaling")
    if sm.transformation_damage_multiplier("super_saiyan") <= rank1_damage:
        failures.append("ssj_damage_not_scaling")

    print("[SKILL_PROGRESSION_TEST] %s" % ("PASS" if failures.is_empty() else "FAIL " + str(failures)))
    quit(0 if failures.is_empty() else 1)
