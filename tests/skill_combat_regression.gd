extends SceneTree

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var failures: Array[String] = []
    var sm: Node = get_root().get_node("SkillManager")
    var gs: Node = get_root().get_node("GameState")
    var race_manager: Node = get_root().get_node("RaceManager")
    var enemy_scene := load("res://scenes/enemies/enemy.tscn") as PackedScene
    var player_scene := load("res://scenes/player/player.tscn") as PackedScene

    for raw_id in sm.SKILLS.keys():
        var id := str(raw_id)
        var d: Dictionary = sm.data(id)
        var typ := str(d.get("type", ""))
        if typ in ["projectile", "beam", "area", "melee", "ranged_melee", "control"]:
            if int(d.get("damage", 0)) <= 0:
                failures.append("offensive_skill_without_damage_%s" % id)
        if id != "solar_flare" and sm.enemy_effect(id) != "":
            failures.append("unexpected_enemy_effect_%s" % id)

    if sm.enemy_effect("solar_flare") != "blind":
        failures.append("solar_flare_not_blind")
    if sm.damage_at_rank("solar_flare", 10) <= sm.damage_at_rank("solar_flare", 1):
        failures.append("solar_flare_damage_not_scaling")
    if sm.blind_duration("solar_flare") <= 0.0:
        failures.append("solar_flare_no_blind_duration")
    if absf(sm.effect_range("solar_flare") - 165.0) > 0.1:
        failures.append("solar_flare_range_r1")
    var solar_range_r1: float = sm.effect_range("solar_flare")
    gs.skill_ranks["solar_flare"] = 10
    if sm.effect_range("solar_flare") <= solar_range_r1:
        failures.append("solar_flare_range_not_scaling")
    gs.skill_ranks["solar_flare"] = 1

    var test_player = player_scene.instantiate()
    get_root().add_child(test_player)
    var enemy = enemy_scene.instantiate()
    get_root().add_child(enemy)
    enemy.target = test_player
    enemy.velocity = Vector2(250, 0)
    enemy.apply_blind(1.5)
    if not enemy.is_blinded():
        failures.append("blind_state_not_activated")
    enemy._physics_process(0.05)
    if enemy.velocity.length() > 0.01:
        failures.append("blind_does_not_stop_enemy")
    enemy.queue_free()
    test_player.queue_free()

    if sm.enemy_effect("namek_burst") != "":
        failures.append("namek_burst_has_enemy_effect")
    if sm.enemy_effect("telekinesis") != "":
        failures.append("telekinesis_has_enemy_effect")

    gs.reset_new_game()
    for race in race_manager.names():
        gs.race = race
        var starter: String = race_manager.starter_ki_skill(race)
        if starter == "" or sm.damage(starter) <= 0:
            failures.append("starter_ki_no_damage_%s" % race)

    if failures.is_empty():
        print("[SKILL_COMBAT_TEST] PASS")
    else:
        print("[SKILL_COMBAT_TEST] FAIL ", failures)
    quit(0 if failures.is_empty() else 1)
