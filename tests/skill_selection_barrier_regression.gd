extends SceneTree

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var failures: Array[String] = []
    var gs: Node = get_root().get_node("GameState")
    var sm: Node = get_root().get_node("SkillManager")
    var rm: Node = get_root().get_node("RaceManager")
    gs.reset_new_game()

    if not gs.learned_skills.has("basic_punch"):
        failures.append("basic_not_started")
    if sm.cooldown("basic_punch") < 0.99 or sm.cooldown("basic_punch") > 1.01:
        failures.append("basic_cooldown")
    if sm.ki_cost("basic_punch") != 1:
        failures.append("basic_ki_cost")
    if not rm.is_allowed("Saiyan", "barrier") or not rm.is_allowed("Namekiano", "barrier"):
        failures.append("barrier_not_universal")
    var barrier_r1: float = sm.barrier_duration("barrier")
    gs.skill_ranks["barrier"] = 10
    if sm.barrier_duration("barrier") <= barrier_r1:
        failures.append("barrier_duration_not_scaling")
    gs.skill_ranks.erase("barrier")

    var player_scene := load("res://scenes/player/player.tscn") as PackedScene
    var player = player_scene.instantiate()
    get_root().add_child(player)
    gs.potential_points = sm.unlock_cost("barrier") + 100
    if not sm.learn("barrier"):
        failures.append("barrier_unlock")
    player.hp = gs.max_hp()
    player.activate_barrier(sm.barrier_duration("barrier"), 1)
    var before: int = player.hp
    player.take_damage(999999)
    if before - player.hp != 1:
        failures.append("barrier_damage_not_one")

    gs.potential_points += sm.unlock_cost("super_saiyan") + 1000
    gs.learned_skills.append("super_saiyan")
    gs.skill_ranks["super_saiyan"] = 1
    gs.transformation = "base"
    if player.selected_skill_id != "basic_punch":
        failures.append("default_selected_skill_should_be_basic")
    if not player.select_skill("super_saiyan"):
        failures.append("skill_select")
    if player.selected_skill_id != "super_saiyan" or gs.transformation != "base":
        failures.append("select_should_not_execute")
    if not player.execute_selected_or_basic():
        failures.append("selected_skill_execute")
    if gs.transformation != "super_saiyan":
        failures.append("selected_skill_not_transformed")
    if player.selected_skill_id != "super_saiyan":
        failures.append("selection_should_persist_after_execution")
    gs.transformation = "base"
    player._skill_lock = 0.0
    player.skill_cooldowns.clear()
    if not player.select_skill("basic_punch"):
        failures.append("basic_reselect")
    if player.selected_skill_id != "basic_punch":
        failures.append("basic_should_be_selectable")
    if not player.try_attack():
        failures.append("attack_button_should_execute_selected_skill")
    if player.selected_skill_id != "basic_punch":
        failures.append("basic_selection_should_persist")

    player.queue_free()
    print("[SKILL_SELECTION_BARRIER_TEST] %s" % ("PASS" if failures.is_empty() else "FAIL " + str(failures)))
    quit(0 if failures.is_empty() else 1)
