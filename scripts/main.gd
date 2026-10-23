extends Node

const WORLD_SCENE = preload("res://scenes/world/world.tscn")
var world: GameWorld
var overlay: Control
var name_edit: LineEdit
var race_option: OptionButton
var continue_button: Button

func _ready() -> void:
	if "--self-test" in OS.get_cmdline_user_args():
		_start_test_world()
		return
	if "--race-test" in OS.get_cmdline_user_args():
		call_deferred("_run_race_test")
		return
	if "--preview" in OS.get_cmdline_user_args() or "--city-preview" in OS.get_cmdline_user_args() or "--stats-preview" in OS.get_cmdline_user_args() or _has_arg_prefix("--stats-capture=") or "--network-test" in OS.get_cmdline_user_args() or _has_arg_prefix("--zone-preview=") or _has_arg_prefix("--race-preview=") or _has_arg_prefix("--boss-preview=") or _has_arg_prefix("--skill-preview=") or _has_arg_prefix("--skill-capture=") or "--transform-preview" in OS.get_cmdline_user_args() or "--flight-preview" in OS.get_cmdline_user_args():
		GameState.reset_new_game()
		var race_preview := _get_arg_prefix("--race-preview=")
		if race_preview != "":
			GameState.race = race_preview
			RaceManager.set_race_defaults(GameState.race, false)
			GameState.hp = GameState.max_hp(); GameState.ki = GameState.max_ki()
		if "--all-skills" in OS.get_cmdline_user_args() or "--transform-preview" in OS.get_cmdline_user_args() or "--flight-preview" in OS.get_cmdline_user_args() or _has_arg_prefix("--skill-preview=") or _has_arg_prefix("--skill-capture="):
			GameState.power = 420
			GameState.potential_points = 210
			var preview_skills: Array[String] = []
			GameState.skill_ranks.clear()
			for preview_id in RaceManager.allowed_skills(GameState.race):
				var pid := str(preview_id)
				preview_skills.append(pid)
				GameState.skill_ranks[pid] = 3
			GameState.learned_skills = preview_skills
			GameState.flight_unlocked = true
			GameState.hp = GameState.max_hp(); GameState.ki = GameState.max_ki()
		if "--city-preview" in OS.get_cmdline_user_args():
			GameState.current_zone = "city"
			GameState.position_x = 430
			GameState.position_y = 560
		if "--stats-preview" in OS.get_cmdline_user_args() or _has_arg_prefix("--stats-capture="):
			GameState.power = 35
			GameState.potential_points = 15
			RaceManager.set_race_defaults(GameState.race, true)
			GameState.potential_points = 15
			GameState.spend_stat("attack_stat")
			GameState.spend_stat("crit_chance")
		var preview_zone := _get_arg_prefix("--zone-preview=")
		if preview_zone != "":
			GameState.current_zone = preview_zone
			GameState.position_x = 420
			GameState.position_y = 560
		_enter_world()
		if "--stats-preview" in OS.get_cmdline_user_args() or _has_arg_prefix("--stats-capture="):
			call_deferred("_open_stats_preview")
		if "--network-test" in OS.get_cmdline_user_args():
			NetworkClient.connect_to_server()
		if _has_arg_prefix("--skill-capture="):
			call_deferred("_open_skill_preview")
		return
	_create_menu()

func _start_test_world() -> void:
	GameState.reset_new_game()
	world = WORLD_SCENE.instantiate()
	add_child(world)

func _has_arg_prefix(prefix: String) -> bool:
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with(prefix):
			return true
	return false

func _get_arg_prefix(prefix: String) -> String:
	for arg in OS.get_cmdline_user_args():
		var value := str(arg)
		if value.begins_with(prefix):
			return value.trim_prefix(prefix)
	return ""


func _open_stats_preview() -> void:
	if world != null and is_instance_valid(world) and world.hud != null:
		world.hud.open_named_menu("estadisticas")
	if _has_arg_prefix("--stats-capture="):
		await get_tree().create_timer(1.0).timeout
		if world != null and is_instance_valid(world) and world.hud != null:
			world.hud.open_named_menu("estadisticas")
		_capture_stats_preview()


func _open_skill_preview() -> void:
	for _i in range(24):
		if world != null and is_instance_valid(world) and world.hud != null:
			world.hud.open_named_menu("habilidades")
			break
		await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout
	if world != null and is_instance_valid(world) and world.hud != null:
		world.hud.open_named_menu("habilidades")
	var path := _get_arg_prefix("--skill-capture=")
	if path != "":
		get_viewport().get_texture().get_image().save_png(path)
		get_tree().quit(0)

func _capture_stats_preview() -> void:
	var path := _get_arg_prefix("--stats-capture=")
	if path == "":
		return
	var image := get_viewport().get_texture().get_image()
	image.save_png(path)
	get_tree().quit(0)

func _create_menu() -> void:
	overlay=Control.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(overlay)
	var bg:=ColorRect.new(); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.color=Color("#0a1326"); bg.mouse_filter=Control.MOUSE_FILTER_IGNORE; overlay.add_child(bg)
	# decorative energy circles
	var art:=ColorRect.new(); art.position=Vector2(0,450); art.size=Vector2(1280,270); art.color=Color("#142b3c"); art.mouse_filter=Control.MOUSE_FILTER_IGNORE; overlay.add_child(art)
	var title:=Label.new(); title.text="DRAGON BALL\nDRAGON REALM"; title.position=Vector2(70,80); title.size=Vector2(600,170); title.add_theme_font_size_override("font_size",52); title.add_theme_color_override("font_color",Color("#ffe37a")); title.add_theme_color_override("font_shadow_color",Color(0,0,0,0.7)); title.add_theme_constant_override("shadow_offset_x",4); title.add_theme_constant_override("shadow_offset_y",4); overlay.add_child(title)
	var sub:=Label.new(); sub.text="Crónicas del guerrero • RPG 2D • 14 zonas • 21+ mobs • 5 razas"; sub.position=Vector2(76,260); sub.size=Vector2(520,40); sub.add_theme_font_size_override("font_size",21); sub.add_theme_color_override("font_color",Color("#8fd2ff")); overlay.add_child(sub)
	var card:=Panel.new(); card.position=Vector2(720,80); card.size=Vector2(450,590); card.add_theme_stylebox_override("panel",style(Color(0.025,0.04,0.075,0.96),Color(0.28,0.60,0.92),18)); overlay.add_child(card)
	var head:=Label.new(); head.text="ENTRAR AL MUNDO"; head.position=Vector2(28,24); head.size=Vector2(394,42); head.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; head.add_theme_font_size_override("font_size",27); head.add_theme_color_override("font_color",Color(0.9,0.95,1)); card.add_child(head)
	var nl:=Label.new(); nl.text="Nombre"; nl.position=Vector2(38,90); nl.size=Vector2(160,30); nl.add_theme_font_size_override("font_size",14); card.add_child(nl)
	name_edit=LineEdit.new(); name_edit.text=GameState.player_name; name_edit.position=Vector2(38,120); name_edit.size=Vector2(374,46); name_edit.placeholder_text="Tu guerrero"; card.add_child(name_edit)
	var rl:=Label.new(); rl.text="Raza inicial"; rl.position=Vector2(38,186); rl.size=Vector2(160,30); rl.add_theme_font_size_override("font_size",14); card.add_child(rl)
	race_option=OptionButton.new(); race_option.position=Vector2(38,216); race_option.size=Vector2(374,44);
	for race_name in RaceManager.names():
		race_option.add_item(race_name)
	card.add_child(race_option)
	var race_info:=Label.new(); race_info.name="RaceInfo"; race_info.position=Vector2(38,265); race_info.size=Vector2(374,60); race_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; race_info.add_theme_font_size_override("font_size",12); race_info.add_theme_color_override("font_color",Color(0.68,0.80,0.93)); card.add_child(race_info)
	race_option.item_selected.connect(func(_i): race_info.text=RaceManager.get_data(race_option.get_item_text(race_option.selected)).description)
	race_info.text=RaceManager.get_data(race_option.get_item_text(race_option.selected)).description
	var new_game:=button("NUEVA PARTIDA",Vector2(38,334),Vector2(374,52),18); card.add_child(new_game); new_game.pressed.connect(_new_game)
	continue_button=button("CONTINUAR",Vector2(38,398),Vector2(374,52),18); card.add_child(continue_button); continue_button.disabled=not SaveManager.has_save(); continue_button.pressed.connect(_continue_game)
	var info:=Label.new(); info.text="Cada raza tiene técnicas exclusivas y una evolución propia.\nPC: A/D • ESPACIO • J • 1-6 • F\nMóvil: joystick + botones táctiles"; info.position=Vector2(38,462); info.size=Vector2(374,58); info.add_theme_font_size_override("font_size",13); info.add_theme_color_override("font_color",Color(0.62,0.74,0.88)); card.add_child(info)
	var server:=button("SERVIDOR DE PRUEBA",Vector2(38,532),Vector2(374,38),12); card.add_child(server); server.pressed.connect(func(): OS.shell_open("server/README.md") if false else null)

func _new_game() -> void:
	GameState.reset_new_game()
	GameState.player_name=name_edit.text.strip_edges() if name_edit.text.strip_edges()!="" else "Goku"
	GameState.race=race_option.get_item_text(race_option.selected)
	RaceManager.set_race_defaults(GameState.race, false)
	GameState.hp=GameState.max_hp(); GameState.ki=GameState.max_ki()
	SaveManager.save_game()
	_enter_world()

func _continue_game() -> void:
	SaveManager.load_game(); _enter_world()

func _enter_world() -> void:
	if overlay: overlay.queue_free()
	world=WORLD_SCENE.instantiate(); add_child(world)

func style(bg:Color,border:Color,r:int)->StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border; s.set_border_width_all(2); s.set_corner_radius_all(r); s.content_margin_left=10; s.content_margin_right=10; return s
func button(text_value:String,pos:Vector2,box:Vector2,font_size:int)->Button:
	var b:=Button.new(); b.text=text_value; b.position=pos; b.size=box; b.add_theme_font_size_override("font_size",font_size); b.add_theme_stylebox_override("normal",style(Color(0.08,0.23,0.40,0.98),Color(0.34,0.70,0.96),10)); b.add_theme_stylebox_override("hover",style(Color(0.14,0.34,0.54,1),Color(0.60,0.88,1),10)); return b

func _run_race_test() -> void:
	var failures: Array[String] = []
	var expected := {
		"Saiyan": ["saiyan_ki_burst","galick_gun","kaioken","super_saiyan"],
		"Humano": ["human_ki_burst","kamehameha","solar_flare","potential_unleashed"],
		"Namekiano": ["namek_ki_burst","masenko","demon_hand","giant_namek"],
		"Majin": ["majin_ki_burst","majin_beam","candy_beam","pure_majin"],
		"Raza Helada": ["frost_ki_burst","death_beam","telekinesis","golden_frost"]
	}
	for race in RaceManager.names():
		GameState.reset_new_game()
		RaceManager.set_race_defaults(race, false)
		RaceManager.validate_loadout()
		if GameState.power != 10: failures.append("start_power_%s" % race)
		if GameState.learned_skills != ["basic_punch"]: failures.append("starter_is_punch_only_%s" % race)
		for id in expected[race]:
			if not RaceManager.is_allowed(race,id): failures.append("allowed_%s_%s" % [race,id])
		for id in SkillManager.SKILLS.keys():
			if str(SkillManager.data(str(id)).get("race","")) not in [race, "Universal"] and SkillManager.can_learn(str(id)):
				failures.append("illegal_%s_%s" % [race,id])
	# KI must remain locked until five unique missions are complete.
	GameState.reset_new_game()
	RaceManager.set_race_defaults("Saiyan", false)
	QuestManager.reset()
	if SkillManager.can_learn("saiyan_ki_burst"): failures.append("ki_early_unlock")
	for id in ["valley_hunt","forest_hunt","desert_patrol","kame_raiders"]:
		QuestManager.quests[id].completed = true
	if SkillManager.can_learn("saiyan_ki_burst"): failures.append("ki_before_mission_5")
	QuestManager.quests["master_training"].completed = true
	if not SkillManager.can_learn("saiyan_ki_burst"): failures.append("ki_mission_5_unlock")
	if not SkillManager.learn("saiyan_ki_burst"): failures.append("ki_learn")
	if GameState.potential_points != 0: failures.append("free_ki_cost")
	GameState.potential_points = 100
	if not SkillManager.learn("galick_gun"): failures.append("potential_skill_learn")
	var before_pot := GameState.potential_points
	if not SkillManager.upgrade("galick_gun"): failures.append("skill_upgrade")
	if GameState.potential_points >= before_pot or SkillManager.rank("galick_gun") != 2: failures.append("skill_upgrade_result")	
	# Power and potential are independent of level.
	var old_power := GameState.power
	var gain := GameState.calculate_hit_gain(18, 100, 500)
	GameState.gain_power(gain, gain)
	if gain <= 0 or GameState.power <= old_power: failures.append("power_gain")
	print("[RACE_TEST] %s" % ("PASS" if failures.is_empty() else "FAIL "+str(failures)))
	get_tree().quit(0 if failures.is_empty() else 1)
