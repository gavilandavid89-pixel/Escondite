extends CanvasLayer

const JOYSTICK_SCRIPT = preload("res://scripts/virtual_joystick.gd")
const DIALOGUE_SCRIPT = preload("res://scripts/dialogue.gd")
const MINIMAP_SCRIPT = preload("res://scripts/minimap.gd")

var world: GameWorld
var player: DBPlayer
var joystick: DBVirtualJoystick
var hp_bar: ProgressBar
var ki_bar: ProgressBar
var potential_bar: ProgressBar
var info_label: Label
var power_label: Label
var points_label: Label
var quest_label: Label
var zone_label: Label
var combat_label: Label
var selected_skill_label: Label
var toast_label: Label
var interact_button: Button
var menu_button: Button
var flight_button: Button
var skill_buttons: Dictionary = {}
var skill_last_tap_ms: Dictionary = {}
const DOUBLE_TAP_MS := 320
var menu_panel: Panel
var menu_content: VBoxContainer
var menu_title: Label
var open_panel_name := ""
var dialogue: Control

func setup(w: GameWorld, p: DBPlayer) -> void:
	world=w; player=p
	_build()
	QuestManager.quest_updated.connect(refresh)
	InventoryManager.changed.connect(refresh)
	SkillManager.changed.connect(refresh)
	NetworkClient.status_changed.connect(_on_network_status)
	refresh()

func _build() -> void:
	var root:=Control.new(); root.name="Root"; root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(root)
	# top stats
	var top:=Panel.new(); top.position=Vector2(18,14); top.size=Vector2(510,128); top.mouse_filter=Control.MOUSE_FILTER_IGNORE; top.add_theme_stylebox_override("panel",style(Color(0.025,0.035,0.06,0.92),Color(0.16,0.42,0.72,0.85),12)); root.add_child(top)
	info_label=label("GUERRERO • PODER 10",Vector2(16,9),Vector2(320,30),19,Color(0.92,0.95,1)); top.add_child(info_label)
	var zeni:=label("◈ 80 ZENI",Vector2(330,9),Vector2(160,30),16,Color(1,0.84,0.36)); zeni.name="Zeni"; top.add_child(zeni)
	hp_bar=bar(Vector2(16,45),Vector2(330,20),Color("#ef3e4b")); top.add_child(hp_bar)
	ki_bar=bar(Vector2(16,71),Vector2(330,17),Color("#4198ee")); top.add_child(ki_bar)
	potential_bar=bar(Vector2(16,94),Vector2(330,12),Color("#f2b83a")); top.add_child(potential_bar)
	top.add_child(label("HP",Vector2(22,45),Vector2(30,18),10,Color.WHITE)); top.add_child(label("KI",Vector2(22,70),Vector2(30,18),10,Color.WHITE)); top.add_child(label("POT",Vector2(22,93),Vector2(38,18),9,Color.WHITE))
	power_label=label("PODER 0",Vector2(365,46),Vector2(125,23),13,Color(0.62,0.82,1)); top.add_child(power_label)
	points_label=label("PTS 0 / 0",Vector2(365,72),Vector2(125,23),13,Color(0.95,0.82,0.42)); top.add_child(points_label)
	zone_label=label("VALLE AZUL",Vector2(365,98),Vector2(125,20),11,Color(0.50,0.95,0.65)); zone_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; top.add_child(zone_label)

	# quest panel
	var qp:=Panel.new(); qp.position=Vector2(548,14); qp.size=Vector2(450,112); qp.mouse_filter=Control.MOUSE_FILTER_IGNORE; qp.add_theme_stylebox_override("panel",style(Color(0.05,0.035,0.075,0.91),Color(0.55,0.37,0.82,0.8),12)); root.add_child(qp)
	quest_label=label("MISIÓN",Vector2(15,12),Vector2(420,90),14,Color(0.93,0.90,1)); qp.add_child(quest_label)

	# minimap
	var map:=Panel.new(); map.position=Vector2(1040,16); map.size=Vector2(220,160); map.add_theme_stylebox_override("panel",style(Color(0.02,0.03,0.05,0.85),Color(0.23,0.48,0.68,0.75),10)); root.add_child(map)
	map.add_child(label("MINIMAPA",Vector2(10,7),Vector2(200,22),11,Color(0.55,0.80,1)))
	var mini:=MINIMAP_SCRIPT.new(); mini.name="Mini"; mini.position=Vector2(10,34); mini.size=Vector2(200,112); map.add_child(mini); mini.setup(world)

	# top menu button
	menu_button=button("☰",Vector2(1176,170),Vector2(70,52),24); root.add_child(menu_button); menu_button.pressed.connect(toggle_menu)

	# joystick
	joystick=JOYSTICK_SCRIPT.new(); joystick.position=Vector2(28,520); joystick.size=Vector2(190,190); root.add_child(joystick)

	# action buttons bottom right
	var jump:=button("SALTAR",Vector2(1060,500),Vector2(120,54),15); root.add_child(jump); jump.pressed.connect(func(): Input.action_press("jump"); await get_tree().create_timer(0.05).timeout; Input.action_release("jump"))
	var attack:=button("EJECUTAR",Vector2(1060,560),Vector2(120,54),14); root.add_child(attack); attack.pressed.connect(func(): player.try_attack())
	flight_button=button("VUELO",Vector2(1060,440),Vector2(120,48),13); flight_button.visible=GameState.flight_unlocked; root.add_child(flight_button); flight_button.pressed.connect(func(): player.toggle_flight(); refresh())

	# Quick bar: basic + race skills + universal Barrier. Any button selects the skill; double-tap executes it.
	var ids: Array=RaceManager.allowed_skills(GameState.race)
	if ids.size() > 8: ids=ids.slice(0,8)
	var visible_index := 0
	for raw_id in ids:
		var id: String = str(raw_id)
		var col := visible_index % 4
		var row := visible_index / 4
		var b:=button("SKILL",Vector2(520 + col*88,500 + row*60),Vector2(80,52),8)
		b.tooltip_text=SkillManager.data(id).get("description","")
		root.add_child(b); b.pressed.connect(func(sid=id): _on_skill_button(sid)); skill_buttons[id]=b
		visible_index += 1
	interact_button=button("HABLAR",Vector2(875,445),Vector2(122,44),14); interact_button.visible=false; root.add_child(interact_button); interact_button.pressed.connect(world.interact)

	combat_label=label("",Vector2(420,145),Vector2(400,32),17,Color(0.82,0.92,1)); combat_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; root.add_child(combat_label)
	selected_skill_label=label("SELECCIONADA: PUÑO BÁSICO • EJECUTAR",Vector2(520,468),Vector2(440,25),11,Color(0.64,0.82,0.96)); selected_skill_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; root.add_child(selected_skill_label)
	toast_label=label("",Vector2(380,670),Vector2(520,34),16,Color(1,0.88,0.48)); toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; root.add_child(toast_label)

func get_joystick()->DBVirtualJoystick:
	return joystick

func refresh()->void:
	if not is_instance_valid(player): return
	if flight_button: flight_button.visible=GameState.flight_unlocked; flight_button.text="ATERRIZAR" if player.flight_enabled else "VUELO"
	var zeni_label=get_node_or_null("Root/Panel/Zeni")
	if zeni_label: zeni_label.text="◈ %d ZENI" % GameState.zeni
	if power_label: power_label.text="PODER %d" % GameState.combat_power()
	if points_label: points_label.text="POT %d" % GameState.potential_points
	info_label.text="%s • %s • PODER %d" % [GameState.player_name,GameState.race,GameState.power]
	hp_bar.max_value=GameState.max_hp(); hp_bar.value=player.hp
	ki_bar.max_value=GameState.max_ki(); ki_bar.value=player.ki
	potential_bar.max_value=maxi(25, GameState.potential_points + 25); potential_bar.value=GameState.potential_points
	if selected_skill_label:
		var selected_name := str(SkillManager.data(player.selected_skill_id).get("name", "Puño Básico"))
		selected_skill_label.text="SELECCIONADA: %s • EJECUTAR" % selected_name
	var q:Dictionary=QuestManager.get_primary_for_zone(world.current_zone, GameState.power)
	if q.is_empty(): quest_label.text="MISIÓN\nTodas las misiones actuales están completas."
	else:
		quest_label.text="%s\n%s\nProgreso: %d / %d" % [q.name,q.description,q.progress,q.required]
	_update_skill_buttons()

func _on_skill_button(id: String) -> void:
	if not SkillManager.is_learned(id):
		return
	var now := Time.get_ticks_msec()
	var last := int(skill_last_tap_ms.get(id, -999999))
	if player.selected_skill_id == id and now - last <= DOUBLE_TAP_MS:
		skill_last_tap_ms[id] = -999999
		if player.execute_selected_or_basic():
			show_message("Ejecutada: %s" % str(SkillManager.data(id).get("name", id)))
		refresh()
		return
	player.select_skill(id)
	skill_last_tap_ms[id] = now
	show_message("Seleccionada: %s • EJECUTAR para usarla" % str(SkillManager.data(id).get("name", id)))
	_update_skill_buttons()

func _execute_selected() -> void:
	var id := player.selected_skill_id
	var ok := player.execute_selected_or_basic()
	if ok:
		show_message("Ejecutado: %s" % str(SkillManager.data(player.selected_skill_id).get("name", "Puño Básico")))
	else:
		show_message("No puedes usar esa técnica todavía.")
	refresh()

func _update_skill_buttons()->void:
	for id in skill_buttons.keys():
		var b:Button=skill_buttons[id]
		var data:Dictionary=SkillManager.data(id)
		var learned:=SkillManager.is_learned(id)
		var cd:=player.get_skill_cooldown(id)
		var cost:=SkillManager.ki_cost(id)
		var rank:=SkillManager.rank(id)
		var marker := "▶ " if player.selected_skill_id == id else ""
		b.text="%s%s R%d\n%s" % [marker,str(data.name).to_upper(),rank,("%.1fs" % cd if cd>0.05 else "%d KI" % cost)]
		b.disabled=not learned or cd>0.05 or player.ki<cost
		b.modulate = Color(1.0,0.86,0.44,1.0) if player.selected_skill_id == id else Color.WHITE

func set_interact_visible(v:bool)->void:
	if interact_button: interact_button.visible=v and open_panel_name==""

func show_message(text:String)->void:
	if toast_label == null: return
	toast_label.text=text; toast_label.modulate.a=1
	var tw:=create_tween(); tw.tween_interval(1.8); tw.tween_property(toast_label,"modulate:a",0.0,0.5)

func show_chat(text:String)->void:
	show_message(text)

func set_combat_message(text:String)->void:
	if combat_label == null: return
	combat_label.text=text
	var tw:=create_tween(); tw.tween_interval(0.7); tw.tween_property(combat_label,"modulate:a",0.0,0.4); tw.finished.connect(func(): combat_label.modulate.a=1)

func on_zone_changed(_id:String,title:String)->void:
	zone_label.text=title.to_upper(); show_message("Zona: %s" % title); refresh()

func open_named_menu(tab:String)->void:
	if menu_panel == null:
		_create_menu()
	menu_panel.visible = true
	_show_tab(tab)

func toggle_menu()->void:
	if menu_panel and menu_panel.visible:
		menu_panel.visible=false; open_panel_name=""; return
	if menu_panel==null:
		_create_menu()
	menu_panel.visible=true; _show_tab("perfil")

func _create_menu()->void:
	menu_panel=Panel.new(); menu_panel.position=Vector2(250,150); menu_panel.size=Vector2(780,500); menu_panel.add_theme_stylebox_override("panel",style(Color(0.025,0.035,0.06,0.98),Color(0.30,0.62,0.92),14)); add_child(menu_panel)
	menu_title=label("MENÚ DEL GUERRERO",Vector2(24,18),Vector2(500,36),24,Color(0.95,0.96,1)); menu_panel.add_child(menu_title)
	var close:=button("X",Vector2(700,16),Vector2(56,44),20); menu_panel.add_child(close); close.pressed.connect(func(): menu_panel.visible=false; open_panel_name="")
	var tabs:=GridContainer.new(); tabs.columns=7; tabs.position=Vector2(22,66); tabs.size=Vector2(736,82); tabs.add_theme_constant_override("h_separation",5); tabs.add_theme_constant_override("v_separation",6); menu_panel.add_child(tabs)
	for pair in [["perfil","PERFIL"],["estadisticas","ESTADÍSTICAS"],["historia","HISTORIA"],["inventario","ITEMS"],["habilidades","TECNICAS"],["misiones","MISIONES"],["bestiario","BESTIARIO"],["mundo","MUNDO"],["tienda","TIENDA"],["forja","FORJA"],["social","SOCIAL"],["conexion","ONLINE"],["ajustes","AJUSTES"]]:
		var b:=button(pair[1],Vector2.ZERO,Vector2(100,36),8); b.custom_minimum_size=Vector2(100,36); tabs.add_child(b); b.pressed.connect(func(id=pair[0]): _show_tab(id))
	var scroll:=ScrollContainer.new(); scroll.position=Vector2(26,156); scroll.size=Vector2(728,320); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; menu_panel.add_child(scroll)
	menu_content=VBoxContainer.new(); menu_content.custom_minimum_size=Vector2(700,0); menu_content.add_theme_constant_override("separation",8); scroll.add_child(menu_content)

func _clear_content()->void:
	for child in menu_content.get_children(): child.queue_free()

func _show_tab(id:String)->void:
	open_panel_name=id; _clear_content()
	match id:
		"perfil": _build_profile()
		"estadisticas": _build_stats()
		"inventario": _build_inventory()
		"habilidades": _build_skills()
		"misiones": _build_quests()
		"bestiario": _build_bestiary()
		"mundo": _build_world_map()
		"tienda": _build_shop()
		"forja": _build_forge()
		"social": _build_social()
		"conexion": _build_online()
		"ajustes": _build_settings()

func _build_profile()->void:
	var race_data:=RaceManager.get_data(GameState.race)
	menu_content.add_child(label("%s\nRaza: %s\n%s\n\nPODER: %d\nPOTENCIAL: %d\n\nVida %d   Ataque %d   KI %d   Armadura %d\nCrítico %.1f%%   Daño crítico %.0f%%   Velocidad %d" % [GameState.player_name,GameState.race,race_data.description,GameState.power,GameState.potential_points,GameState.vitality,GameState.attack_stat,GameState.ki_power,GameState.armor,GameState.crit_chance,GameState.crit_damage,GameState.speed_stat],Vector2.ZERO,Vector2(700,245),16,Color(0.88,0.92,1)))
	var b:=button("ABRIR ESTADÍSTICAS",Vector2.ZERO,Vector2(230,44),12); menu_content.add_child(b); b.pressed.connect(func(): _show_tab("estadisticas"))
	menu_content.add_child(label("Transformación actual: %s\nEquipo: %s / %s" % [GameState.transformation,InventoryManager.get_item_name(str(GameState.equipment.get("armor","novice_gi"))),InventoryManager.get_item_name(str(GameState.equipment.get("accessory","training_band")))],Vector2.ZERO,Vector2(700,72),14,Color(0.65,0.80,0.95)))

func _build_stats()->void:
	menu_content.add_child(label("ESTADÍSTICAS DEL GUERRERO",Vector2.ZERO,Vector2(700,40),21,Color(0.95,0.97,1)))
	menu_content.add_child(label("La primera mejora cuesta 1 Potencial, la segunda 2, la tercera 3... de forma independiente para cada atributo.",Vector2.ZERO,Vector2(690,42),13,Color(1.0,0.82,0.44)))
	var grid:=GridContainer.new(); grid.columns=2; grid.custom_minimum_size=Vector2(690,235); grid.add_theme_constant_override("h_separation",8); grid.add_theme_constant_override("v_separation",6); menu_content.add_child(grid)
	var stat_ids:= ["vitality","attack_stat","ki_power","armor","crit_chance","crit_damage","speed_stat","ki_regen","dodge_chance"]
	for stat in stat_ids:
		var card:=PanelContainer.new(); card.custom_minimum_size=Vector2(341,44); card.add_theme_stylebox_override("panel",style(Color(0.045,0.07,0.11,0.96),Color(0.18,0.40,0.62,0.85),8)); grid.add_child(card)
		var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",4); card.add_child(row)
		var name:=Label.new(); name.text=GameState.stat_display_name(stat); name.custom_minimum_size=Vector2(88,34); name.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; name.add_theme_font_size_override("font_size",12); row.add_child(name)
		var value:=Label.new(); value.text=GameState.stat_value_text(stat); value.custom_minimum_size=Vector2(42,34); value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; value.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; value.add_theme_font_size_override("font_size",14); value.add_theme_color_override("font_color",Color(0.55,0.88,1)); row.add_child(value)
		var effect:=Label.new(); effect.text=GameState.stat_effect_text(stat); effect.custom_minimum_size=Vector2(126,34); effect.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; effect.add_theme_font_size_override("font_size",9); effect.add_theme_color_override("font_color",Color(0.65,0.73,0.84)); row.add_child(effect)
		var cost:=GameState.stat_upgrade_cost(stat)
		var b:=button("+1 • %d POT" % cost,Vector2.ZERO,Vector2(70,34),8); b.disabled=GameState.potential_points < cost; row.add_child(b)
		b.pressed.connect(func(s=stat):
			if player.spend_stat(s):
				SaveManager.save_game()
				refresh()
				_show_tab("estadisticas")
		)

func _build_story()->void:
	var ch:=ChapterManager.current()
	menu_content.add_child(label("HISTORIA — %s" % ch.title,Vector2.ZERO,Vector2(700,44),20,Color(0.92,0.95,1)))
	menu_content.add_child(label(ch.description,Vector2.ZERO,Vector2(690,60),15,Color(0.72,0.84,0.95)))
	menu_content.add_child(label("Capítulo actual: %d / %d" % [GameState.chapter,ChapterManager.CHAPTERS.size()],Vector2.ZERO,Vector2(690,32),14,Color(1.0,0.84,0.42)))
	var sep:=HSeparator.new(); sep.custom_minimum_size=Vector2(690,8); menu_content.add_child(sep)
	for i in range(1,ChapterManager.CHAPTERS.size()+1):
		var c:Dictionary=ChapterManager.CHAPTERS[i]
		var state:="ACTUAL" if i==GameState.chapter else ("COMPLETADO" if i<GameState.chapter else "BLOQUEADO")
		menu_content.add_child(label("%d. %s  • %s\n%s" % [i,c.title,state,c.description],Vector2.ZERO,Vector2(690,52),13,Color(0.82,0.91,1.0) if i<=GameState.chapter else Color(0.48,0.55,0.64)))

func _build_inventory()->void:
	for id in GameState.inventory.keys():
		var count:=int(GameState.inventory[id]); if count<=0: continue
		var data:=InventoryManager.get_item_data(str(id))
		var row:=HBoxContainer.new(); row.custom_minimum_size=Vector2(680,44); menu_content.add_child(row)
		var name:=Label.new(); name.text="%s x%d" % [InventoryManager.get_item_name(str(id)),count]; name.custom_minimum_size=Vector2(300,40); name.add_theme_font_size_override("font_size",15); row.add_child(name)
		var desc:=Label.new(); desc.text=str(data.get("description","")); desc.custom_minimum_size=Vector2(250,40); row.add_child(desc)
		if data.get("type","") in ["consumable"]:
			var use:=button("USAR",Vector2.ZERO,Vector2(90,38),12); row.add_child(use); use.pressed.connect(func(item_id=id): show_message(InventoryManager.use_item(str(item_id))); refresh(); _show_tab("inventario"))
		elif data.get("type","") in ["armor","accessory"]:
			var eq:=button("EQUIPAR",Vector2.ZERO,Vector2(90,38),11); row.add_child(eq); eq.pressed.connect(func(item_id=id): InventoryManager.equip(str(item_id)); refresh(); _show_tab("inventario"))

func _build_skills()->void:
	var race_skills:=RaceManager.allowed_skills(GameState.race)
	menu_content.add_child(label("TÉCNICAS DE %s" % GameState.race.to_upper(),Vector2.ZERO,Vector2(700,42),21,Color(0.95,0.97,1)))
	menu_content.add_child(label("Potencial disponible: %s  •  Todas las técnicas llegan hasta RANGO 10" % _format_potential(GameState.potential_points),Vector2.ZERO,Vector2(690,34),13,Color(1.0,0.84,0.42)))
	menu_content.add_child(label("La técnica KI racial se obtiene gratis en la misión 5. El resto parte en 5.000 POT de coste base; el daño, control, curación y transformaciones elevan su multiplicador de precio.",Vector2.ZERO,Vector2(690,50),13,Color(0.68,0.80,0.92)))
	var base:=PanelContainer.new(); base.custom_minimum_size=Vector2(690,54); base.add_theme_stylebox_override("panel",style(Color(0.035,0.055,0.085,0.96),Color(0.28,0.55,0.78,0.8),9)); menu_content.add_child(base)
	var base_row:=HBoxContainer.new(); base_row.add_theme_constant_override("separation",8); base.add_child(base_row)
	var fist_icon:=Label.new(); fist_icon.text="✦"; fist_icon.custom_minimum_size=Vector2(42,42); fist_icon.add_theme_font_size_override("font_size",25); fist_icon.add_theme_color_override("font_color",Color(0.72,0.92,1)); fist_icon.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; fist_icon.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; base_row.add_child(fist_icon)
	var fist_text:=label("PUÑO BÁSICO\nSiempre disponible • no consume KI • mejora con Ataque",Vector2.ZERO,Vector2(520,45),12,Color(0.82,0.91,0.98)); base_row.add_child(fist_text)
	var grid:=GridContainer.new(); grid.columns=2; grid.custom_minimum_size=Vector2(690,280); grid.add_theme_constant_override("h_separation",8); grid.add_theme_constant_override("v_separation",8); menu_content.add_child(grid)
	for raw_id in race_skills:
		var id: String = str(raw_id)
		var data:Dictionary=SkillManager.data(id)
		var learned:=SkillManager.is_learned(id)
		var learned_rank:=SkillManager.rank(id)
		var cost_mult:=SkillManager.cost_multiplier(id)
		var card:=PanelContainer.new(); card.custom_minimum_size=Vector2(341,116); card.add_theme_stylebox_override("panel",style(Color(0.035,0.055,0.09,0.98),_skill_color(id),10)); grid.add_child(card)
		var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",8); card.add_child(row)
		var icon:=TextureRect.new(); icon.custom_minimum_size=Vector2(54,54); icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.texture=load(SkillManager.icon_path(id)) as Texture2D; row.add_child(icon)
		var mid:=VBoxContainer.new(); mid.custom_minimum_size=Vector2(184,100); row.add_child(mid)
		var title:=Label.new(); title.text=str(data.get("name",id)); title.add_theme_font_size_override("font_size",14); title.add_theme_color_override("font_color",_skill_color(id).lightened(0.25)); mid.add_child(title)
		var rank_text: String = "RANGO %d/%d" % [learned_rank,SkillManager.max_rank(id)] if learned else "BLOQUEADA"
		var rank_label:=Label.new(); rank_label.text=rank_text; rank_label.add_theme_font_size_override("font_size",10); rank_label.add_theme_color_override("font_color",Color(0.78,0.86,0.95)); mid.add_child(rank_label)
		var pips := ""
		for pip_i in range(SkillManager.max_rank(id)):
			pips += "●" if learned_rank >= pip_i + 1 else "○"
		var pip_label:=Label.new(); pip_label.text=pips; pip_label.add_theme_font_size_override("font_size",8); pip_label.add_theme_color_override("font_color",_skill_color(id)); mid.add_child(pip_label)
		var tags:=Label.new(); tags.text=SkillManager.tags(id); tags.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; tags.custom_minimum_size=Vector2(180,22); tags.add_theme_font_size_override("font_size",9); tags.add_theme_color_override("font_color",Color(0.60,0.72,0.84)); mid.add_child(tags)
		var effect_text := "DAÑO %d → %d" % [int(data.get("damage",0)), SkillManager.damage_at_rank(id, SkillManager.max_rank(id))] if int(data.get("damage",0)) > 0 else "EFECTO ESPECIAL • POTENCIADO POR RANGO"
		var effect_label:=Label.new(); effect_label.text=effect_text; effect_label.add_theme_font_size_override("font_size",8); effect_label.add_theme_color_override("font_color",Color(0.70,0.80,0.90)); mid.add_child(effect_label)
		var scale_label:=Label.new(); scale_label.text="PRECIO ×%.2f" % cost_mult; scale_label.add_theme_font_size_override("font_size",9); scale_label.add_theme_color_override("font_color",Color(1.0,0.76,0.38)); mid.add_child(scale_label)
		var action_col:=VBoxContainer.new(); action_col.custom_minimum_size=Vector2(86,100); row.add_child(action_col)
		var cost_label:=Label.new();
		if not learned:
			cost_label.text="MISIÓN 5" if id == RaceManager.starter_ki_skill(GameState.race) else _format_potential(SkillManager.unlock_cost(id))+" POT"
		else:
			cost_label.text="MÁXIMO" if learned_rank >= SkillManager.max_rank(id) else "+1  "+_format_potential(SkillManager.upgrade_cost(id))+" POT"
		cost_label.custom_minimum_size=Vector2(82,34); cost_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; cost_label.add_theme_font_size_override("font_size",9); cost_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; cost_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; cost_label.add_theme_color_override("font_color",Color(0.94,0.84,0.52)); action_col.add_child(cost_label)
		var b:=button("MEJORAR" if learned else "DESBLOQUEAR",Vector2.ZERO,Vector2(86,42),9); action_col.add_child(b)
		if learned:
			b.disabled=learned_rank>=SkillManager.max_rank(id) or not SkillManager.can_upgrade(id)
			b.pressed.connect(func(skill_id=id): SkillManager.upgrade(skill_id); refresh(); _show_tab("habilidades"))
		else:
			b.disabled=not SkillManager.can_learn(id)
			b.pressed.connect(func(skill_id=id): SkillManager.learn(skill_id); refresh(); _show_tab("habilidades"))
	menu_content.add_child(label("Rangos altos no solo aumentan daño: también pueden reducir KI/cooldown o aumentar la fuerza de curación, control, defensa y transformación según la identidad de cada técnica.",Vector2.ZERO,Vector2(690,55),12,Color(0.58,0.70,0.82)))

func _skill_color(id:String)->Color:
	var t:=str(SkillManager.data(id).get("type","projectile"))
	match t:
		"beam": return Color("#6dc8ff")
		"transform": return Color("#ffc95d")
		"heal": return Color("#6fe39a")
		"defense": return Color("#9ba8ff")
		"control": return Color("#db83ff")
		"melee","ranged_melee": return Color("#ff8b65")
		"buff": return Color("#ff6f7f")
		_: return Color("#5eb7ef")

func _format_potential(value:int)->String:
	if value >= 1000000: return "%.2fM" % (float(value)/1000000.0)
	if value >= 1000: return "%.1fk" % (float(value)/1000.0)
	return str(value)

func _build_quests()->void:
	for q in QuestManager.quests.values():
		var row:=VBoxContainer.new(); row.custom_minimum_size=Vector2(690,78); menu_content.add_child(row)
		var a:=label("%s  %s" % ["✓" if q.completed else "○",q.name],Vector2.ZERO,Vector2(690,28),16,Color(1,0.84,0.4) if not q.completed else Color(0.55,1,0.7)); row.add_child(a)
		var b:=label("%s\n%d/%d  • Recompensa %d PODER + %d POT + %d ZENI" % [q.description,q.progress,q.required,q.reward_power,q.reward_potential,q.reward_zeni],Vector2.ZERO,Vector2(690,50),12,Color(0.78,0.84,0.93)); row.add_child(b)



func _build_bestiary()->void:
	var title:=label("BESTIARIO",Vector2.ZERO,Vector2(700,42),20,Color(0.92,0.95,1)); menu_content.add_child(title)
	var info:=label("Los enemigos están distribuidos por zonas con distintos niveles de poder y recompensas.\nDerrota enemigos para registrar sus estadísticas.",Vector2.ZERO,Vector2(700,70),14,Color(0.68,0.80,0.92)); menu_content.add_child(info)
	var rows:=VBoxContainer.new(); rows.custom_minimum_size=Vector2(690,230); menu_content.add_child(rows)
	for id in ["wolf_raider","boar_brute","saibaman","desert_bandit","dino_scavenger","dino_matriarch","pirate_raider","rr_scout","rr_heavy","rr_commander","ice_wolf","frost_soldier","ice_commander","namek_raider","namek_guardian","saibaman_elite","galactic_raider","temple_guardian"]:
		var known:=int(GameState.kill_counts.get(id,0))>0
		var name:=MobCatalog.name(id)
		var row:=Label.new(); row.custom_minimum_size=Vector2(680,28); row.add_theme_font_size_override("font_size",13)
		row.text=("✓ " if known else "? ")+name+"  • derrotados: "+str(GameState.kill_counts.get(id,0))
		row.add_theme_color_override("font_color",Color(0.82,0.91,1.0) if known else Color(0.44,0.52,0.60))
		rows.add_child(row)

func _build_world_map()->void:
	var title:=label("MAPA DEL MUNDO",Vector2.ZERO,Vector2(700,42),20,Color(0.92,0.95,1)); menu_content.add_child(title)
	var entries:= [
		["valley","Valle Azul","PWR 10"],["city","Ciudad Capsule","Zona segura"],["forest","Bosque Oscuro","PWR 25"],
		["desert","Desierto Carmesí","PWR 40"],["kame","Costa Kame","PWR 55"],["ice","Montañas del Norte","PWR 75"],
		["namek","Pantanos de Namek","PWR 105"],["red_ribbon","Base Ejército Red","PWR 65"],["temple","Templo del KI","PWR 165"],["karin","Torre Sagrada","PWR 165"]
	]
	for e in entries:
		var line:=label(("✓ " if GameState.discovered_zones.has(e[0]) else "• ")+e[1]+"  —  "+e[2],Vector2.ZERO,Vector2(680,28),14,Color(0.78,0.88,1.0)); menu_content.add_child(line)
	menu_content.add_child(label("Viaja usando los portales físicos de cada zona. Los mapas se desbloquean al visitarlos.",Vector2.ZERO,Vector2(680,60),13,Color(0.62,0.72,0.84)))

func _build_shop()->void:
	var title:=label("TIENDA DEL VALLE\nTus Zeni: %d" % GameState.zeni,Vector2.ZERO,Vector2(700,55),18,Color(0.92,0.95,1)); menu_content.add_child(title)
	for id in ["senzu","water","iron","heavy_gi"]:
		var data:=InventoryManager.get_item_data(id); var row:=HBoxContainer.new(); row.custom_minimum_size=Vector2(680,48); menu_content.add_child(row)
		var a:=label("%s • %d Zeni" % [InventoryManager.get_item_name(id),int(data.get("value",0))],Vector2.ZERO,Vector2(500,42),14,Color(0.82,0.88,0.96)); row.add_child(a)
		var b:=button("COMPRAR",Vector2.ZERO,Vector2(110,40),11)
		row.add_child(b)
		b.pressed.connect(func(item_id=id):
			if InventoryManager.buy(str(item_id)):
				show_message("Comprado: %s" % InventoryManager.get_item_name(str(item_id)))
			else:
				show_message("No tienes suficiente Zeni.")
			refresh()
			_show_tab("tienda")
		)

func _build_forge()->void:
	var title:=label("FORJA Y CRAFTING",Vector2.ZERO,Vector2(700,42),20,Color(0.92,0.95,1)); menu_content.add_child(title)
	var desc:=label("Cápsula KI • 2 hierro + 1 agua\nRestaura 60 KI al usarla.",Vector2.ZERO,Vector2(650,72),15,Color(0.75,0.84,0.94)); menu_content.add_child(desc)
	var b:=button("FABRICAR CÁPSULA",Vector2.ZERO,Vector2(220,44),12); menu_content.add_child(b); b.pressed.connect(func():
		if InventoryManager.craft_ki_capsule():
			show_message("Fabricaste una Cápsula KI.")
		else:
			show_message("Necesitas 2 hierro y 1 agua.")
		refresh()
		_show_tab("forja")
	)
	var r:=button("FABRICAR RACIÓN SENZU",Vector2.ZERO,Vector2(250,44),12); menu_content.add_child(r); r.pressed.connect(func():
		if InventoryManager.craft_ration():
			show_message("Fabricaste una Semilla Senzu.")
		else:
			show_message("Necesitas 2 carne y 1 agua.")
		refresh()
		_show_tab("forja")
	)

func _build_social()->void:
	var title:=label("SOCIAL Y CLAN",Vector2.ZERO,Vector2(700,48),20,Color(0.92,0.95,1)); menu_content.add_child(title)
	var clan:=label("Clan: %s  • Nivel %d" % [GameState.clan_name,GameState.clan_level],Vector2.ZERO,Vector2(700,42),16,Color(1,0.84,0.42)); menu_content.add_child(clan)
	var row:=HBoxContainer.new(); menu_content.add_child(row)
	var clan_btn:=button("CREAR CLAN • 100 ZENI",Vector2.ZERO,Vector2(210,42),11); row.add_child(clan_btn); clan_btn.disabled=GameState.clan_name!="Sin clan"; clan_btn.pressed.connect(func():
		if GameState.zeni >= 100:
			GameState.zeni -= 100
			GameState.clan_name = "Guerreros del Ki"
			GameState.clan_level = 1
			GameState.changed.emit()
			SaveManager.save_game()
			_show_tab("social")
	)
	var sep:=HSeparator.new(); sep.custom_minimum_size=Vector2(680,8); menu_content.add_child(sep)
	var fl:=label("AMIGOS",Vector2.ZERO,Vector2(700,30),17,Color(0.75,0.88,1)); menu_content.add_child(fl)
	if GameState.friends.is_empty():
		menu_content.add_child(label("Todavía no tienes amigos guardados en este dispositivo.",Vector2.ZERO,Vector2(680,34),13,Color(0.65,0.74,0.84)))
	else:
		for f in GameState.friends:
			menu_content.add_child(label("• "+str(f),Vector2.ZERO,Vector2(680,28),14,Color(0.82,0.90,0.98)))
	var input:=LineEdit.new(); input.placeholder_text="Nombre del amigo (local)"; input.custom_minimum_size=Vector2(400,40); menu_content.add_child(input)
	var add:=button("AGREGAR",Vector2.ZERO,Vector2(140,40),11); menu_content.add_child(add); add.pressed.connect(func():
		if input.text.strip_edges() != "":
			GameState.friends.append(input.text.strip_edges())
			SaveManager.save_game()
			_show_tab("social")
	)

func _build_online()->void:
	var title:=label("SERVIDORES Y CHAT",Vector2.ZERO,Vector2(700,40),20,Color(0.9,0.94,1)); menu_content.add_child(title)
	var status:=label("Estado: %s\nTCP JSON • Canal TIERRA-01 • 127.0.0.1:4010" % ("CONECTADO" if NetworkClient.connected else "MODO LOCAL"),Vector2.ZERO,Vector2(700,70),16,Color(0.70,0.87,1)); menu_content.add_child(status)
	var row:=HBoxContainer.new(); menu_content.add_child(row)
	var conn:=button("CONECTAR",Vector2.ZERO,Vector2(150,44),13); row.add_child(conn); conn.pressed.connect(func(): NetworkClient.connect_to_server(); show_message("Intentando conectar al servidor..."))
	var dis:=button("DESCONECTAR",Vector2.ZERO,Vector2(150,44),13); row.add_child(dis); dis.pressed.connect(NetworkClient.disconnect_from_server)
	var chat_row:=HBoxContainer.new(); menu_content.add_child(chat_row)
	var chat:=LineEdit.new(); chat.placeholder_text="Escribe un mensaje global..."; chat.custom_minimum_size=Vector2(510,42); chat_row.add_child(chat)
	var send:=button("ENVIAR",Vector2.ZERO,Vector2(130,42),12); chat_row.add_child(send)
	var send_chat:=func():
		var t:=chat.text.strip_edges()
		if t!="" and NetworkClient.connected:
			NetworkClient.send_packet({"type":"CHAT","text":t})
			chat.clear()
		elif t!="":
			show_message("Conecta al servidor para usar el chat online.")
	send.pressed.connect(send_chat)
	chat.text_submitted.connect(func(_t): send_chat.call())
	var note:=label("Multijugador experimental: posición, presencia y chat ya atraviesan el servidor. El combate competitivo y la autoridad antitrampas quedan para la capa de producción.",Vector2.ZERO,Vector2(700,105),14,Color(0.64,0.74,0.86)); menu_content.add_child(note)

func _build_settings()->void:
	var title:=label("AJUSTES",Vector2.ZERO,Vector2(700,40),20,Color(0.9,0.94,1)); menu_content.add_child(title)
	var music:=button("MÚSICA: %s" % ("OFF" if AudioManager.bus_muted else "ON"),Vector2.ZERO,Vector2(220,46),13); menu_content.add_child(music)
	music.pressed.connect(func(): AudioManager.toggle_mute(); _show_tab("ajustes"))
	var explain:=label("Controles de PC: A/D o flechas, ESPACIO, J, teclas 1-6.\nMóvil: joystick, salto, golpe y barra de técnicas.\nLa escala del HUD está pensada para 16:9 y se adapta al viewport.",Vector2.ZERO,Vector2(700,120),14,Color(0.68,0.78,0.9)); menu_content.add_child(explain)

func open_dialogue(speaker:String, lines:Array[String])->void:
	if dialogue and is_instance_valid(dialogue): dialogue.queue_free()
	dialogue=DIALOGUE_SCRIPT.new(); add_child(dialogue); dialogue.open_dialogue(speaker,lines); dialogue.closed.connect(func(): dialogue.queue_free())

func _on_network_status(text:String)->void:
	show_message(text)

func label(text_value:String,pos:Vector2,box:Vector2,font_size:int,color:Color)->Label:
	var l:=Label.new(); l.text=text_value; l.position=pos; l.size=box; l.add_theme_font_size_override("font_size",font_size); l.add_theme_color_override("font_color",color); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; return l

func button(text_value:String,pos:Vector2,box:Vector2,font_size:int)->Button:
	var b:=Button.new(); b.text=text_value; b.position=pos; b.size=box; b.add_theme_font_size_override("font_size",font_size); b.add_theme_stylebox_override("normal",style(Color(0.08,0.22,0.38,0.97),Color(0.30,0.68,0.95,0.9),10)); b.add_theme_stylebox_override("hover",style(Color(0.14,0.34,0.54,0.98),Color(0.55,0.86,1,1),10)); b.add_theme_stylebox_override("pressed",style(Color(0.05,0.14,0.24,1),Color(0.34,0.72,1,0.9),10)); b.add_theme_stylebox_override("disabled",style(Color(0.06,0.08,0.12,0.65),Color(0.18,0.22,0.28,0.7),10)); return b

func bar(pos:Vector2,box:Vector2,fill:Color)->ProgressBar:
	var b:=ProgressBar.new(); b.position=pos; b.size=box; b.show_percentage=false; b.add_theme_stylebox_override("background",style(Color(0.02,0.03,0.05,0.9),Color(0.12,0.15,0.2),6)); b.add_theme_stylebox_override("fill",style(fill,Color(0,0,0,0),6)); return b

func style(bg:Color,border:Color,r:int)->StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border; s.set_border_width_all(1); s.set_corner_radius_all(r); s.content_margin_left=10; s.content_margin_right=10; return s
