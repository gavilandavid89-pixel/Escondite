extends Node2D
class_name GameWorld

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")
const ENEMY_SCENE = preload("res://scenes/enemies/enemy.tscn")
const BOSS_SCENE = preload("res://scenes/enemies/temple_guardian.tscn")
const MASTER_SCENE = preload("res://scenes/npcs/master.tscn")
const MERCHANT_SCENE = preload("res://scenes/npcs/merchant.tscn")
const PROJECTILE_SCENE = preload("res://scenes/enemies/projectile.tscn")
const SKILL_PRESENTATION_SCENE = preload("res://scenes/skills/skill_presentation.tscn")
const HUD_SCENE = preload("res://scenes/ui/hud.tscn")
const REMOTE_SCENE = preload("res://scenes/player/remote_player.tscn")
const ORB_SCENE = preload("res://scenes/world/dragon_orb.tscn")
const SHENRON_SCENE = preload("res://scenes/npcs/shenron.tscn")
const DROP_SCENE = preload("res://scenes/world/drop_pickup.tscn")
const CITY_NPC_SCENE = preload("res://scenes/npcs/city_npc.tscn")

var player: DBPlayer
var current_map: MapBase
var current_zone := ""
var enemies: Array[DBEnemy] = []
var drops: Array[Dictionary] = []
var hud
var autosave_timer := 0.0
var respawn_timer := 0.0
var network_timer := 0.0
var remote_players: Dictionary = {}
var mob_visuals: Array[Dictionary] = []

signal zone_changed(zone_id: String, title: String)

func _ready() -> void:
	if _has_arg("--self-test"):
		_start_world_for_test()
	else:
		var preview_zone := ""
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--preview="):
				preview_zone = arg.trim_prefix("--preview=")
		if preview_zone != "":
			start_world(preview_zone, Vector2(420,560))
		else:
			start_world(GameState.current_zone, Vector2(GameState.position_x, GameState.position_y))

func start_world(zone: String = "valley", spawn := Vector2(-1,-1)) -> void:
	_create_player()
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.setup(self, player)
	player.setup_mobile_input(hud.get_joystick())
	player.attack_fired.connect(_on_player_attack)
	player.skill_fired.connect(_on_player_skill)
	player.died.connect(_on_player_died)
	QuestManager.quest_completed.connect(_on_quest_completed)
	NetworkClient.packet_received.connect(_on_network_packet)
	NetworkClient.configure_identity(GameState.player_name,GameState.power,GameState.current_zone)
	change_zone(zone, spawn if spawn.x >= 0 else Vector2(260,610))
	call_deferred("_run_visual_preview")

func _run_visual_preview() -> void:
	var args := OS.get_cmdline_user_args()
	var skill_preview := ""
	var boss_zone := ""
	for arg in args:
		var value := str(arg)
		if value.begins_with("--skill-preview="):
			skill_preview = value.trim_prefix("--skill-preview=")
		elif value.begins_with("--boss-preview="):
			boss_zone = value.trim_prefix("--boss-preview=")
	if boss_zone != "":
		await get_tree().create_timer(0.15).timeout
		change_zone(boss_zone, Vector2(3100,560))
	if "--flight-preview" in args:
		await get_tree().create_timer(0.6).timeout
		player.toggle_flight()
		player.velocity = Vector2(150, -70)
	if "--transform-preview" in args:
		var race_data: Dictionary = RaceManager.get_data(GameState.race)
		var transform_id := str(race_data.get("transformation", ""))
		if transform_id != "":
			await get_tree().create_timer(0.8).timeout
			player.use_skill(transform_id)
	if skill_preview != "":
		await get_tree().create_timer(0.8).timeout
		player.use_skill(skill_preview)
	if "--skills-menu-preview" in args:
		await get_tree().create_timer(0.5).timeout
		hud.open_named_menu("habilidades")
	if "--profile-preview" in args:
		await get_tree().create_timer(0.5).timeout
		hud.open_named_menu("perfil")
	var capture_path := ""
	for arg in args:
		var av := str(arg)
		if av.begins_with("--capture="):
			capture_path = av.trim_prefix("--capture=")
	if capture_path != "":
		await get_tree().create_timer(1.2).timeout
		get_viewport().get_texture().get_image().save_png(capture_path)

func _create_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.name = "Player"
	player.position = Vector2(260,610)
	add_child(player)
	player.hp_changed.connect(_on_player_stat_changed)
	player.ki_changed.connect(_on_player_stat_changed)
	player.power_changed.connect(_on_player_stat_changed)
	player.coins_changed.connect(_on_player_stat_changed)
	var camera := Camera2D.new()
	camera.name = "Camera"
	camera.position = Vector2(0,-140)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 9.0
	player.add_child(camera)

func change_zone(zone: String, spawn: Vector2) -> void:
	_clear_zone()
	current_zone = zone
	var scene: PackedScene
	match zone:
		"forest": scene = load("res://scenes/world/forest.tscn")
		"temple": scene = load("res://scenes/world/temple.tscn")
		"city": scene = load("res://scenes/world/city.tscn")
		"desert": scene = load("res://scenes/world/desert.tscn")
		"kame": scene = load("res://scenes/world/kame.tscn")
		"ice": scene = load("res://scenes/world/ice.tscn")
		"namek": scene = load("res://scenes/world/namek.tscn")
		"red_ribbon": scene = load("res://scenes/world/red_ribbon.tscn")
		"karin": scene = load("res://scenes/world/karin.tscn")
		"plains": scene = load("res://scenes/world/map_plains.tscn")
		"arena": scene = load("res://scenes/world/map_arena.tscn")
		"wasteland": scene = load("res://scenes/world/map_wasteland.tscn")
		"otherworld": scene = load("res://scenes/world/map_otherworld.tscn")
		_: scene = load("res://scenes/world/valley.tscn")
	current_map = scene.instantiate() as MapBase
	add_child(current_map)
	move_child(current_map, 0)
	current_map.travel_requested.connect(change_zone)
	current_zone = current_map.zone_id
	player.position = spawn
	GameState.current_zone = current_zone
	GameState.position_x = player.position.x
	GameState.position_y = player.position.y
	_spawn_zone_contents()
	_update_camera_limits()
	zone_changed.emit(current_zone, current_map.zone_title)
	if hud:
		hud.on_zone_changed(current_zone, current_map.zone_title)
		if current_zone == "temple":
			hud.show_message("Templo del KI • zona avanzada • derrota al Guardián para completar la prueba.")
		elif current_zone == "forest":
			hud.show_message("Bosque Oscuro • PODER 25+ • Saibaman y lobos.")
		elif current_zone == "city":
			hud.show_message("Ciudad Capsule • zona segura • compra, fabrica y prepara tu viaje.")
		elif current_zone == "desert":
			hud.show_message("Desierto Carmesí • PODER 40+ • bandidos y dinos.")
		elif current_zone == "kame":
			hud.show_message("Costa Kame • PODER 55+ • piratas y zonas de entrenamiento.")
		elif current_zone == "ice":
			hud.show_message("Montañas del Norte • PODER 75+ • hielo y patrullas.")
		elif current_zone == "namek":
			hud.show_message("Pantanos de Namek • PODER 100+ • cristales y asaltantes.")
		elif current_zone == "red_ribbon":
			hud.show_message("Base del Ejército Red • PODER 65+ • patrullas y comandante.")
		elif current_zone == "karin":
			hud.show_message("Torre Sagrada • PODER 175+ • entrenamiento y desafío final.")
		elif current_zone == "plains":
			hud.show_message("Llanuras del Torneo • PODER 80+ • combate, plataformas y vuelo.")
		elif current_zone == "arena":
			hud.show_message("Arena Celestial • PODER 100+ • Campeón con segunda fase.")
		elif current_zone == "wasteland":
			hud.show_message("Tierra Devastada • PODER 240+ • zona de élite.")
		elif current_zone == "otherworld":
			hud.show_message("Camino del Otro Mundo • PODER 360+ • contenido de endgame.")
		else:
			hud.show_message("Valle Azul • PODER 10 • inicia tu entrenamiento.")
	SaveManager.save_game()

func _clear_zone() -> void:
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	for entry in mob_visuals:
		var visual = entry.get("node")
		if is_instance_valid(visual):
			visual.queue_free()
	mob_visuals.clear()
	for n in get_tree().get_nodes_in_group("zone_npcs"):
		if is_instance_valid(n):
			n.queue_free()
	if current_map and is_instance_valid(current_map):
		current_map.queue_free()
	current_map = null
	for drop in drops:
		var node = drop.get("node")
		if is_instance_valid(node): node.queue_free()
	drops.clear()

func _spawn_zone_contents() -> void:
	if current_map == null:
		return
	var npc_positions := current_map.get_npc_spawns()
	for index in range(npc_positions.size()):
		var pos: Vector2 = npc_positions[index]
		if current_zone == "city" and index >= 2:
			var citizen = CITY_NPC_SCENE.instantiate()
			var city_people := [
				["Mika Capsule", "citizen", "Las cápsulas pueden almacenar una ciudad entera si sabes usarlas.", Color("#5c84b7"), Color("#e8e0d0")],
				["Rudo Entrenador", "trainer", "El cielo es la próxima frontera. Aprende a volar antes de entrar al torneo.", Color("#8f6a4a"), Color("#4e77ae")],
				["Taya Mensajera", "citizen", "He visto guerreros salir disparados hacia la Base Red.", Color("#d18a6c"), Color("#566d8c")],
				["Jiro Mecánico", "citizen", "Puedo mejorar tus cápsulas y reparar equipo cuando tengamos el sistema completo.", Color("#9aa1ad"), Color("#3d4b60")]
			]
			var people_index := (index - 2) % city_people.size()
			citizen.setup(city_people[people_index][0], city_people[people_index][1], city_people[people_index][2], city_people[people_index][3], city_people[people_index][4])
			add_child(citizen); citizen.position=pos; citizen.add_to_group("zone_npcs")
			continue
		var npc = MERCHANT_SCENE.instantiate() if (current_zone == "city" and index == 0) else MASTER_SCENE.instantiate()
		add_child(npc); npc.position = pos; npc.add_to_group("zone_npcs")
		if current_zone == "city" and index == 1: npc.display_name = "Maestro Renso"
		elif current_zone == "namek": npc.display_name = "Anciano Namek"
		elif current_zone == "ice": npc.display_name = "Maestro del Norte"
		elif current_zone == "desert": npc.display_name = "Guía del Desierto"
		elif current_zone == "kame": npc.display_name = "Maestro de la Costa"
		elif current_zone == "red_ribbon": npc.display_name = "Prisionero del Ejército Red"
		elif current_zone == "karin": npc.display_name = "Maestro de la Torre"
	var spawn_defs := current_map.get_mob_spawns()
	for entry in spawn_defs:
		var kind := str(entry.get("kind","wolf_raider"))
		var data: Dictionary = MobCatalog.lookup(kind)
		var is_boss_spawn := bool(data.get("boss", false)) or str(data.get("type","")) == "boss"
		if is_boss_spawn and GameState.boss_flags.get(kind, false):
			continue
		var e: DBEnemy = ENEMY_SCENE.instantiate()
		add_child(e)
		var difficulty := 1
		e.setup(player, kind, difficulty)
		e.position = entry.get("position", Vector2(200,590))
		e.floor_y = e.position.y + 40.0
		e.spawn_position = e.position
		e.defeated.connect(_on_enemy_defeated)
		e.player_hit.connect(_on_enemy_hit_player)
		enemies.append(e)
		_attach_mob_visual(e)
	for orb_index in range(current_map.get_orb_spawns().size()):
		var orb_id := "%s_%d" % [current_zone, orb_index + 1]
		if GameState.collected_orbs.has(orb_id):
			continue
		var orb: DragonOrbPickup = ORB_SCENE.instantiate()
		add_child(orb)
		orb.position = current_map.get_orb_spawns()[orb_index]
		orb.setup(orb_index + 1, orb_id)
		orb.collected.connect(_on_dragon_orb_collected.bind(orb_id))
	if current_zone == "valley" and QuestManager.quests["dragon_orbs"].completed:
		var shenron: ShenronNPC = SHENRON_SCENE.instantiate()
		shenron.position = Vector2(3600, 555)
		shenron.add_to_group("zone_npcs")
		add_child(shenron)
	if current_zone == "temple" and not GameState.boss_flags.get("temple_guardian", false):
		var boss: DBEnemy = BOSS_SCENE.instantiate()
		add_child(boss)
		boss.position = Vector2(2800,610)
		boss.floor_y = boss.position.y + 40.0
		boss.spawn_position = boss.position
		boss.setup(player, "temple_guardian", 2)
		boss.defeated.connect(_on_enemy_defeated)
		boss.player_hit.connect(_on_enemy_hit_player)
		enemies.append(boss)
		_attach_mob_visual(boss)

func _update_camera_limits() -> void:
	var camera := player.get_node_or_null("Camera") as Camera2D
	if camera == null or current_map == null:
		return
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(current_map.world_size.x)
	camera.limit_bottom = int(current_map.world_size.y)

func _physics_process(_delta: float) -> void:
	_update_mob_visuals()
	if player == null or current_map == null:
		return
	GameState.position_x = player.position.x
	GameState.position_y = player.position.y
	GameState.current_zone = current_zone
	for npc in get_tree().get_nodes_in_group("zone_npcs"):
		if player.position.distance_to(npc.position) < 95.0 and hud:
			hud.set_interact_visible(true)
			break
		elif hud:
			hud.set_interact_visible(false)

func _process(delta: float) -> void:
	autosave_timer += delta
	network_timer += delta
	respawn_timer = maxf(0.0, respawn_timer - delta)
	if autosave_timer >= 8.0:
		autosave_timer = 0.0
		SaveManager.save_game()
	_update_drops(delta)
	if network_timer >= 0.10:
		network_timer = 0.0
		NetworkClient.configure_identity(GameState.player_name,GameState.power,current_zone)
		NetworkClient.send_packet({"type":"MOVE","x":player.position.x,"y":player.position.y,"zone":current_zone})
	if enemies.size() < 5 and respawn_timer <= 0.0 and current_zone not in ["temple", "city"]:
		_spawn_one_enemy()
		respawn_timer = 4.0

func _spawn_one_enemy() -> void:
	if current_map == null:
		return
	var defs := current_map.get_mob_spawns()
	if defs.is_empty():
		return
	var candidates: Array[Dictionary] = []
	for candidate in defs:
		var cid := str(candidate.get("kind","wolf_raider"))
		var cdata: Dictionary = MobCatalog.lookup(cid)
		if not bool(cdata.get("boss", false)) and str(cdata.get("type","")) != "boss":
			candidates.append(candidate)
	if candidates.is_empty():
		return
	var entry: Dictionary = candidates[randi() % candidates.size()]
	var e: DBEnemy = ENEMY_SCENE.instantiate()
	add_child(e)
	var kind := str(entry.get("kind","wolf_raider"))
	e.setup(player, kind, maxi(1, 1 + int(GameState.power / 250)))
	e.position = entry.get("position", Vector2(200,590))
	e.floor_y = e.position.y + 40.0
	e.spawn_position = e.position
	e.defeated.connect(_on_enemy_defeated)
	e.player_hit.connect(_on_enemy_hit_player)
	enemies.append(e)
	_attach_mob_visual(e)

func _attach_mob_visual(enemy: DBEnemy) -> void:
	var visual := AnimatedSprite2D.new()
	visual.z_index = 80
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()
	frames.add_animation("idle"); frames.set_animation_speed("idle",4.0); frames.set_animation_loop("idle",true)
	var base := "res://assets/pixel/mobs/%s_" % enemy.enemy_id
	for i in range(2):
		var frame_path := base + str(i) + ".png"
		if FileAccess.file_exists(frame_path):
			var tex := load(frame_path) as Texture2D
			if tex: frames.add_frame("idle",tex)
	if frames.get_frame_count("idle") == 0:
		var path := "res://assets/sprites/mobs/%s.svg" % enemy.enemy_id
		var tex: Texture2D = load(path) as Texture2D if FileAccess.file_exists(path) else load("res://assets/sprites/mobs/rr_scout.svg") as Texture2D
		frames.add_frame("idle",tex)
	visual.sprite_frames=frames
	visual.animation="idle"
	visual.centered=true
	visual.scale=Vector2(1.55,1.55) if enemy.is_boss else Vector2(1.22,1.22)
	visual.position=enemy.position
	add_child(visual)
	mob_visuals.append({"enemy":enemy,"node":visual,"id":enemy.enemy_id})

func _update_mob_visuals() -> void:
	for i in range(mob_visuals.size() - 1, -1, -1):
		var entry: Dictionary = mob_visuals[i]
		var enemy = entry.get("enemy")
		var visual = entry.get("node")
		if not is_instance_valid(enemy) or not is_instance_valid(visual):
			if is_instance_valid(visual): visual.queue_free()
			mob_visuals.remove_at(i)
			continue
		visual.position = enemy.position + Vector2(0.0, sin(Time.get_ticks_msec() * 0.006 + float(i) * 1.7) * 1.5)
		if absf(enemy.velocity.x) > 3.0:
			visual.flip_h = enemy.velocity.x < 0.0
		visual.modulate = Color(1.35,0.55,0.55,1.0) if enemy.hurt_timer > 0.0 else (Color(1.0,0.92,0.52,1.0) if enemy.is_blinded() else Color.WHITE)
		var base_scale := 1.48 if enemy.is_boss else 1.08
		var attack_scale := 1.0 + (0.10 if enemy.attack_timer > 0.0 else 0.0)
		visual.scale = Vector2(base_scale * attack_scale, base_scale / attack_scale)

func _remove_mob_visual(enemy: DBEnemy) -> void:
	for i in range(mob_visuals.size() - 1, -1, -1):
		var entry: Dictionary = mob_visuals[i]
		if entry.get("enemy") == enemy:
			var visual = entry.get("node")
			if is_instance_valid(visual): visual.queue_free()
			mob_visuals.remove_at(i)

func _on_player_attack(origin: Vector2, direction: Vector2) -> void:
	var transformed_raw := int(round(float(GameState.attack_power() + InventoryManager.equipment_bonus("strength") * 2) * SkillManager.transformation_damage_multiplier(GameState.transformation)))
	var damage := GameState.critical_damage(transformed_raw)
	if not player.is_on_floor() or player.flight_enabled:
		damage = int(damage * 1.10)
	var did_hit := false
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			enemies.erase(enemy)
			continue
		var off: Vector2 = enemy.global_position - origin
		var forward := maxf(0.0, direction.normalized().dot(off.normalized())) if off.length() > 0.01 else 1.0
		var range := 112.0 if (not player.is_on_floor() or player.flight_enabled) else 96.0
		if off.length() <= range and forward > 0.18:
			var actual: int = enemy.take_damage(damage, Vector2.ZERO, 0.0)
			_reward_power_hit(enemy, actual)
			player.apply_active_transform_hit(actual)
			did_hit = true
			_spawn_hit_text(enemy.position, ("CRIT! %d" % damage) if GameState.last_damage_was_critical else str(damage))
	if did_hit:
		AudioManager.play("punch", -6.0)
		if hud: hud.show_message(("¡COMBO AÉREO! " if not player.is_on_floor() else "¡COMBO! ") + str(damage) + " daño")

func _on_player_skill(id: String, origin: Vector2, direction: Vector2) -> void:
	var data: Dictionary = SkillManager.data(id)
	var damage: int
	if id == "basic_punch":
		damage = maxi(1, int(round(float(GameState.attack_power()) * SkillManager.rank_strength(id) * SkillManager.transformation_damage_multiplier(GameState.transformation))))
	else:
		var raw_damage := SkillManager.damage(id) + GameState.ki_damage() - 10
		damage = int(round(float(maxi(1, raw_damage)) * SkillManager.transformation_damage_multiplier(GameState.transformation)))
	var race_tint := Color(str(RaceManager.get_data(GameState.race).get("color", "#5cc8ff")))
	match str(data.get("type", "projectile")):
		"basic_melee":
			var range := 96.0 if player.is_on_floor() and not player.flight_enabled else 112.0
			# El golpe se resuelve después del inicio de la animación, no al pulsar.
			get_tree().create_timer(0.18).timeout.connect(func():
				var did_hit := false
				for enemy in enemies.duplicate():
					if not is_instance_valid(enemy):
						continue
					var off: Vector2 = enemy.global_position - origin
					var forward := maxf(0.0, direction.normalized().dot(off.normalized())) if off.length() > 0.01 else 1.0
					if off.length() <= range and forward > 0.18:
						var crit_damage_value := GameState.critical_damage(damage)
						var actual: int = enemy.take_damage(crit_damage_value, Vector2.ZERO, 0.0)
						_reward_power_hit(enemy, actual)
						player.apply_active_transform_hit(actual)
						_spawn_hit_text(enemy.position, ("CRIT! %d" % crit_damage_value) if GameState.last_damage_was_critical else str(crit_damage_value))
						did_hit = true
				if did_hit:
					AudioManager.play("punch", -6.0)
					if hud: hud.show_message("PUÑO BÁSICO • %d daño" % damage)
			)
		"projectile":
			var p: KIProjectile = PROJECTILE_SCENE.instantiate()
			add_child(p)
			p.setup(origin, direction, damage, player, race_tint, id, SkillManager.rank(id))
			p.enemy_hit.connect(_on_player_projectile_hit)
			match GameState.race:
				"Saiyan": p.speed = 720.0
				"Humano": p.speed = 790.0
				"Namekiano": p.speed = 620.0; p.life = 1.6
				"Majin": p.speed = 540.0; p.life = 1.6
				"Raza Helada": p.speed = 840.0
		"beam":
			_spawn_skill_beam(id, origin, direction, damage)
		"single_control":
			var flash_range := SkillManager.effect_range(id)
			var target_enemy := _find_single_skill_target(origin, direction, flash_range)
			if target_enemy != null:
				var target_ref := target_enemy
				_spawn_flash(target_ref.global_position, 78.0 + 3.0 * float(SkillManager.rank(id) - 1), damage, true)
				# El destello se ve primero; el impacto llega después de su animación.
				get_tree().create_timer(0.52).timeout.connect(func():
					if not is_instance_valid(target_ref):
						return
					var crit_damage_value := GameState.critical_damage(damage)
					var actual: int = target_ref.take_damage(crit_damage_value, Vector2.ZERO, 0.0)
					_reward_power_hit(target_ref, actual)
					player.apply_active_transform_hit(actual)
				)
			else:
				if hud: hud.show_message("Taiyōken • ningún objetivo en alcance")
		"area":
			_spawn_skill_area(id, origin, damage)
		"melee", "ranged_melee":
			_spawn_dragon_fist(origin, direction, damage)
			var melee_type := str(data.get("type"))
			get_tree().create_timer(0.28).timeout.connect(func():
				var hit_radius := 135.0 + (35.0 if melee_type == "ranged_melee" else 0.0)
				for enemy in enemies.duplicate():
					if is_instance_valid(enemy) and enemy.global_position.distance_to(origin) <= hit_radius:
						var crit_damage_value := GameState.critical_damage(damage)
						var actual: int = enemy.take_damage(crit_damage_value, Vector2.ZERO, 0.0)
						_reward_power_hit(enemy, actual)
						player.apply_active_transform_hit(actual)
			)
		"heal":
			var heal_strength := SkillManager.effect_strength(id)
			var heal := int(round((55.0 + sqrt(float(GameState.power)) * 2.0 + GameState.ki_power) * heal_strength))
			if GameState.race == "Namekiano":
				heal = int(round(float(heal) * 1.35))
			elif GameState.race == "Humano":
				heal = int(round(float(heal) * 0.80))
			elif GameState.race == "Majin":
				heal = int(round(float(heal) * 1.20))
			player.hp = mini(GameState.max_hp(), player.hp + heal)
			GameState.hp = player.hp
			player.hp_changed.emit(player.hp, GameState.max_hp())
			if GameState.race == "Humano":
				player.ki = mini(GameState.max_ki(), player.ki + int(round(25.0 * heal_strength)))
				GameState.ki = player.ki
				player.ki_changed.emit(player.ki, GameState.max_ki())
			if hud: hud.show_message("%s • +%d HP" % [data.get("name", "Recuperación"), heal])
		"control":
			# Legacy compatibility: offensive skills no longer apply movement control.
			for enemy in enemies.duplicate():
				if is_instance_valid(enemy):
					var off: Vector2 = enemy.global_position - origin
					if off.length() < 430.0 and direction.normalized().dot(off.normalized()) > 0.3:
						var crit_damage_value := GameState.critical_damage(damage)
						var actual: int = enemy.take_damage(crit_damage_value, Vector2.ZERO, 0.0)
						_reward_power_hit(enemy, actual)
						player.apply_active_transform_hit(actual)
		"defense":
			var defense_time := 7.0 + 0.45 * float(SkillManager.rank(id) - 1)
			player._defense_timer = defense_time
			if hud: hud.show_message("Barrera Helada • %.1fs de defensa" % defense_time)
		"barrier":
			var barrier_time := player.barrier_time_left()
			if hud: hud.show_message("Barrera • %.1fs • daño recibido = 1" % barrier_time)
		"buff":
			if hud: hud.show_message("%s activado" % data.get("name", id))
		"transform":
			if hud: hud.show_message("¡%s! • Rango %d" % [data.get("name", id), SkillManager.rank(id)])

	if data.get("transform", "") != "":
		GameState.transformation = str(data.get("transform"))
	GameState.changed.emit()

func _on_player_projectile_hit(enemy: Node, actual_damage: int) -> void:
	if enemy is DBEnemy:
		_reward_power_hit(enemy as DBEnemy, actual_damage)
		player.apply_active_transform_hit(actual_damage)

func _reward_power_hit(enemy: DBEnemy, actual_damage: int) -> void:
	if enemy == null or actual_damage <= 0:
		return
	var gain := GameState.calculate_hit_gain(enemy.mob_power, actual_damage, enemy.max_hp)
	if gain > 0:
		GameState.gain_power(gain, gain)
		_spawn_hit_text(enemy.position + Vector2(0,-52), "+%d PWR" % gain, Color("#65e6ff"))

func _find_single_skill_target(origin: Vector2, direction: Vector2, max_range: float) -> DBEnemy:
	var best: DBEnemy = null
	var best_distance := max_range + 1.0
	var forward := direction.normalized()
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.hp <= 0:
			continue
		var offset: Vector2 = enemy.global_position - origin
		var distance := offset.length()
		if distance > max_range or distance <= 0.01:
			continue
		if forward.dot(offset.normalized()) < 0.35:
			continue
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best

func _spawn_skill_beam(id: String, origin: Vector2, direction: Vector2, damage: int) -> void:
	var fx: SkillPresentation = SKILL_PRESENTATION_SCENE.instantiate()
	add_child(fx)
	fx.position = origin
	_setup_skill_fx(fx, id, SkillManager.rank(id), direction, "beam")
	fx.impact_ready.connect(func():
		var did_hit := false
		var length := 420.0 + 28.0 * float(SkillManager.rank(id))
		var width_angle := 0.24 + 0.008 * float(SkillManager.rank(id))
		for enemy in enemies.duplicate():
			if not is_instance_valid(enemy):
				continue
			var off: Vector2 = enemy.global_position - origin
			if off.length() <= length and off.length() > 0.01 and absf(direction.normalized().angle_to(off.normalized())) < width_angle:
				var crit_damage_value := GameState.critical_damage(damage)
				var actual: int = enemy.take_damage(crit_damage_value, Vector2.ZERO, 0.0)
				_reward_power_hit(enemy, actual)
				player.apply_active_transform_hit(actual)
				_spawn_hit_text(enemy.position, ("CRIT! %d" % crit_damage_value) if GameState.last_damage_was_critical else str(crit_damage_value), Color("#9de8ff"))
				did_hit = true
		if did_hit and hud:
			hud.show_message("%s • impacto" % SkillManager.data(id).get("name", id))
	)

func _setup_skill_fx(fx: SkillPresentation, id: String, skill_rank: int, direction: Vector2, mode: String) -> void:
	fx.setup_effect(id, skill_rank, direction, mode, Color.WHITE)

func _spawn_skill_area(id: String, origin: Vector2, damage: int) -> void:
	var fx: SkillPresentation = SKILL_PRESENTATION_SCENE.instantiate()
	add_child(fx)
	fx.position = origin
	_setup_skill_fx(fx, id, SkillManager.rank(id), Vector2.RIGHT, "area")
	fx.impact_ready.connect(func():
		var rank_value := SkillManager.rank(id)
		var radius := 185.0 + 7.2 * float(maxi(0, rank_value - 1))
		for enemy in enemies.duplicate():
			if is_instance_valid(enemy) and enemy.global_position.distance_to(origin) <= radius:
				var crit_damage_value := GameState.critical_damage(damage)
				var actual: int = enemy.take_damage(crit_damage_value, Vector2.ZERO, 0.0)
				_reward_power_hit(enemy, actual)
				player.apply_active_transform_hit(actual)
	)

func _spawn_dragon_fist(origin: Vector2, direction: Vector2, damage: int = 190) -> void:
	var fx := Node2D.new()
	fx.position = origin + direction * 35.0
	fx.z_index = 25
	fx.set_script(load("res://scripts/flash_effect.gd"))
	fx.setup(105.0, 0.35)
	add_child(fx)
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy) and enemy.global_position.distance_to(origin) <= 115.0 and signf(enemy.global_position.x-origin.x) == signf(direction.x):
			var dragon_damage := GameState.critical_damage(maxi(1, damage + GameState.attack_stat * 2))
			var actual: int = enemy.take_damage(dragon_damage, Vector2.ZERO, 0.0)
			_reward_power_hit(enemy, actual)
			player.apply_active_transform_hit(actual)
			_spawn_hit_text(enemy.position, "DRAGON FIST", Color("#ffcf5c"))

func _spawn_flash(origin: Vector2, radius: float, damage: int = 28, apply_blind := false) -> void:
	var fx := Node2D.new()
	fx.position = origin
	fx.z_index = 25
	fx.set_script(load("res://scripts/flash_effect.gd"))
	fx.setup(radius, 0.55)
	add_child(fx)
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy) and enemy.global_position.distance_to(origin) <= radius:
			var flash_damage := GameState.critical_damage(maxi(1, damage + GameState.ki_power))
			var actual: int = enemy.take_damage(flash_damage, Vector2.ZERO, 0.0)
			_reward_power_hit(enemy, actual)
			player.apply_active_transform_hit(actual)
			if apply_blind and SkillManager.enemy_effect("solar_flare") == "blind" and enemy.has_method("apply_blind"):
				enemy.apply_blind(SkillManager.blind_duration("solar_flare"))
				_spawn_hit_text(enemy.position, "CIEGO", Color("#ffe883"))

func _on_quest_completed(q: Dictionary) -> void:
	if player == null:
		return
	player.gain_power(int(q.reward_power), int(q.reward_potential))
	player.add_zeni(int(q.reward_zeni))
	InventoryManager.add_item(str(q.reward_item), 1)
	if hud:
		hud.show_message("Misión completada: %s" % str(q.name))
	SaveManager.save_game()

func _on_dragon_orb_collected(orb_id: String) -> void:
	if GameState.collected_orbs.has(orb_id):
		return
	GameState.collected_orbs.append(orb_id)
	InventoryManager.add_item("dragon_orb", 1)
	QuestManager.on_item_collected("dragon_orb", 1)
	if hud:
		hud.show_message("¡Encontraste un Orbe del Dragón! %d/7" % QuestManager.quests["dragon_orbs"].progress)
	SaveManager.save_game()

func _on_enemy_defeated(enemy: DBEnemy) -> void:
	_remove_mob_visual(enemy)
	var reward: Dictionary = enemy.get_reward()
	# Defeating the opponent grants a small finishing bonus on top of the power earned per hit.
	var finish_gain := maxi(1, int(round(float(reward.power) * 0.03)))
	player.gain_power(finish_gain, finish_gain)
	player.add_zeni(int(reward.zeni))
	GameState.record_kill(str(reward.id))
	QuestManager.on_enemy_defeated(str(reward.id))
	_spawn_hit_text(enemy.position + Vector2(0,-30), "+%d PODER  +%d ZENI" % [finish_gain,reward.zeni], Color("#ffd66b"))
	var loot_list: Array = reward.get("loot", [])
	if not loot_list.is_empty() and randf() < 0.62:
		var item_id := str(loot_list[randi() % loot_list.size()])
		var amount := 1 if item_id != "zenicoin" else randi_range(1,3)
		var drop = DROP_SCENE.instantiate()
		add_child(drop)
		drop.position = enemy.position
		drop.setup(item_id, amount)
		drops.append({"pos":drop.position,"item":item_id,"amount":amount,"life":25.0,"node":drop})
	var mob_data: Dictionary = MobCatalog.lookup(str(reward.id))
	if str(reward.id) == "temple_guardian" or bool(mob_data.get("boss", false)):
		GameState.boss_flags[str(reward.id)] = true
		var achievement_id := "boss_" + str(reward.id)
		if not GameState.achievements.has(achievement_id):
			GameState.achievements.append(achievement_id)
		if hud:
			hud.show_message("¡%s derrotado! El área ha quedado despejada." % str(reward.name))
	SaveManager.save_game()

func _on_enemy_hit_player(amount: int) -> void:
	if player.hp <= 0:
		return
	player.take_damage(amount)
	if hud:
		hud.set_combat_message("-%d HP" % amount)

func _update_drops(delta: float) -> void:
	for i in range(drops.size()-1,-1,-1):
		var d: Dictionary = drops[i]
		d.life = float(d.life)-delta
		if d.life <= 0:
			drops.remove_at(i); continue
		var node = d.get("node")
		if is_instance_valid(node):
			d.pos = node.position
		if player.position.distance_to(d.pos) < 54:
			InventoryManager.add_item(str(d.item),int(d.amount))
			hud.show_message("Recogiste %s x%d" % [InventoryManager.get_item_name(str(d.item)),int(d.amount)])
			if is_instance_valid(node): node.queue_free()
			drops.remove_at(i)

func interact() -> void:
	var nearest: Node = null
	var best := 120.0
	for npc in get_tree().get_nodes_in_group("zone_npcs"):
		var d := player.position.distance_to(npc.position)
		if d < best:
			nearest = npc; best = d
	if nearest and hud:
		var result: Dictionary = nearest.interact()
		hud.open_dialogue(str(result.speaker), [str(result.text), "Recuerda: el dominio del KI empieza con entrenamiento constante.", "Cuando estés preparado, visita el bosque y busca la entrada al templo."])
		if str(result.get("action", "")) == "shop":
			hud.open_named_menu("tienda")
		elif str(result.get("action", "")) == "wish":
			if not GameState.achievements.has("dragon_wish"):
				GameState.achievements.append("dragon_wish")
				player.gain_power(60,60)
				player.add_zeni(1000)
				player.hp = GameState.max_hp(); player.ki = GameState.max_ki()
				GameState.hp = player.hp; GameState.ki = player.ki
				hud.show_message("¡Shenron concedió tu deseo! +60 PODER +60 POTENCIAL +1000 ZENI")
				SaveManager.save_game()

func _on_player_died() -> void:
	if hud: hud.show_message("Has sido derrotado. Regresarás al Valle Azul.")
	await get_tree().create_timer(1.2).timeout
	GameState.hp = GameState.max_hp()
	GameState.ki = GameState.max_ki()
	GameState.zeni = maxi(0, GameState.zeni - 15)
	change_zone("valley", Vector2(260,610))

func _spawn_hit_text(at: Vector2, text: String, color := Color("#fff2a6")) -> void:
	var l := Label.new()
	l.text=text; l.position=at; l.size=Vector2(250,30); l.add_theme_font_size_override("font_size",16); l.add_theme_color_override("font_color",color); l.z_index=60
	add_child(l)
	var tw:=create_tween().set_parallel(true); tw.tween_property(l,"position",at+Vector2(0,-45),0.75); tw.tween_property(l,"modulate:a",0.0,0.75).set_delay(0.15); tw.chain().tween_callback(l.queue_free)

func _on_player_stat_changed(_a=null,_b=null,_c=null) -> void:
	if hud: hud.refresh()


func _on_network_packet(data: Dictionary)->void:
	var typ:=str(data.get("type",""))
	if typ=="STATE":
		var seen:Dictionary={}
		for entry in data.get("players",[]):
			var id:=str(entry.get("id","")); if id=="" or id==NetworkClient.player_id: continue
			if str(entry.get("zone",""))!=current_zone: continue
			seen[id]=true
			var remote:DBRemotePlayer
			if not remote_players.has(id) or not is_instance_valid(remote_players[id]):
				remote=REMOTE_SCENE.instantiate(); add_child(remote); remote_players[id]=remote
			else:
				remote=remote_players[id]
			remote.position=Vector2(float(entry.get("x",0)),float(entry.get("y",0)))
			remote.setup(str(entry.get("name","Jugador")),int(entry.get("power",10)))
		for id in remote_players.keys():
			if not seen.has(id):
				if is_instance_valid(remote_players[id]): remote_players[id].queue_free()
				remote_players.erase(id)
	elif typ=="CHAT":
		if hud: hud.show_chat("[%s] %s" % [str(data.get("name","Jugador")),str(data.get("text",""))])

func _has_arg(v: String) -> bool:
	return v in OS.get_cmdline_user_args()

func _start_world_for_test() -> void:
	start_world("forest", Vector2(520,610))
	call_deferred("_run_self_test")

func _run_self_test() -> void:
	await get_tree().create_timer(0.7).timeout
	var failures: Array[String] = []
	if player == null: failures.append("player")
	if current_map == null: failures.append("map")
	var map_tests := {
		"city":"res://scenes/world/city.tscn",
		"desert":"res://scenes/world/desert.tscn",
		"kame":"res://scenes/world/kame.tscn",
		"ice":"res://scenes/world/ice.tscn",
		"namek":"res://scenes/world/namek.tscn",
		"temple":"res://scenes/world/temple.tscn",
		"forest":"res://scenes/world/forest.tscn",
		"red_ribbon":"res://scenes/world/red_ribbon.tscn",
		"karin":"res://scenes/world/karin.tscn",
		"plains":"res://scenes/world/map_plains.tscn",
		"arena":"res://scenes/world/map_arena.tscn",
		"wasteland":"res://scenes/world/map_wasteland.tscn",
		"otherworld":"res://scenes/world/map_otherworld.tscn",
		"valley":"res://scenes/world/valley.tscn"
	}
	for map_id in map_tests.keys():
		var probe := load(map_tests[map_id]).instantiate() as MapBase
		add_child(probe)
		await get_tree().process_frame
		if probe == null or probe.zone_id != map_id: failures.append(map_id + "_map")
		if probe != null and map_id != "city" and probe.get_mob_spawns().is_empty(): failures.append(map_id + "_mobs")
		if is_instance_valid(probe): probe.queue_free()
	change_zone("red_ribbon", Vector2(430,560))
	await get_tree().process_frame
	await get_tree().process_frame
	if enemies.size() < 5: failures.append("red_ribbon_enemy_count")
	for ground_enemy in enemies:
		if is_instance_valid(ground_enemy) and ground_enemy.position.y > 650.0: failures.append("enemy_floor")
	if mob_visuals.size() < enemies.size(): failures.append("mob_visuals")
	change_zone("temple", Vector2(520,610))
	await get_tree().physics_frame
	await get_tree().physics_frame
	var boss_found := false
	for test_enemy in enemies:
		if is_instance_valid(test_enemy) and bool(test_enemy.is_boss):
			test_enemy.hp = int(test_enemy.max_hp * 0.55)
			test_enemy._physics_process(0.016)
			if test_enemy.phase == 2:
				boss_found = true
	if not boss_found: failures.append("boss_phase2")
	change_zone("city", Vector2(430,560))
	await get_tree().process_frame
	if current_zone != "city": failures.append("city_transition")
	change_zone("forest", Vector2(520,610))
	await get_tree().process_frame
	if current_zone != "forest": failures.append("forest_transition")
	change_zone("temple", Vector2(180,560))
	await get_tree().process_frame
	if current_zone != "temple" or enemies.size() < 6: failures.append("temple_transition")
	change_zone("red_ribbon", Vector2(420,560))
	await get_tree().process_frame
	var red_boss_found := false
	for candidate in enemies:
		if is_instance_valid(candidate) and candidate.enemy_id == "rr_commander": red_boss_found = true
	if not red_boss_found: failures.append("red_ribbon_boss")
	change_zone("karin", Vector2(420,860))
	await get_tree().process_frame
	var karin_boss_found := false
	for candidate in enemies:
		if is_instance_valid(candidate) and candidate.enemy_id == "ice_commander": karin_boss_found = true
	if not karin_boss_found: failures.append("karin_boss")
	change_zone("valley", Vector2(260,610))
	await get_tree().process_frame
	if current_zone != "valley": failures.append("valley_transition")
	if enemies.size() < 5: failures.append("enemy_spawn")
	var boss_probe: DBEnemy = ENEMY_SCENE.instantiate()
	add_child(boss_probe)
	boss_probe.setup(player, "rr_commander", 1)
	boss_probe.hp = int(boss_probe.max_hp * 0.50)
	boss_probe._physics_process(0.016)
	if boss_probe.phase != 2: failures.append("boss_phase")
	boss_probe.queue_free()
	var drop_probe = DROP_SCENE.instantiate()
	add_child(drop_probe)
	drop_probe.setup("ice_shard", 2)
	if drop_probe.item_id != "ice_shard" or drop_probe.amount != 2: failures.append("drop_pickup")
	drop_probe.queue_free()
	if hud == null: failures.append("hud")
	if hud != null:
		hud.open_named_menu("bestiario")
		hud.open_named_menu("mundo")
		hud.open_named_menu("forja")
		hud.open_named_menu("tienda")
		hud.menu_panel.visible = false
	if GameState.power != 10: failures.append("starting_power")
	if GameState.learned_skills != ["basic_punch"]: failures.append("starter_should_be_basic_punch_only")
	if SkillManager.can_learn(RaceManager.starter_ki_skill(GameState.race)): failures.append("ki_should_require_mission_5")
	if not SkillManager.data("super_saiyan_2").has("potential_cost"): failures.append("advanced_skill_data")
	if QuestManager.quests.has("dragon_orbs") == false: failures.append("dragon_orb_quest")
	player._hurt_timer = 0.0
	var before: int = player.hp
	player.take_damage(15)
	if player.hp >= before: failures.append("damage")
	player.hp = GameState.max_hp()
	var before_power := GameState.power
	var gain := GameState.calculate_hit_gain(120, 100, 500)
	GameState.gain_power(gain, gain)
	if GameState.power <= before_power or gain <= 0: failures.append("power_gain")
	# Real combat path: actual enemy damage grants both Power and Potential.
	if enemies.size() > 0:
		var hit_enemy: DBEnemy = enemies[0]
		hit_enemy.hp = min(hit_enemy.max_hp, 80)
		var power_before_hit := GameState.power
		var pot_before_hit := GameState.potential_points
		var actual_hit: int = hit_enemy.take_damage(12, Vector2.ZERO, 0.0)
		_reward_power_hit(hit_enemy, actual_hit)
		if GameState.power <= power_before_hit: failures.append("combat_hit_power_reward")
		if GameState.potential_points <= pot_before_hit: failures.append("combat_hit_potential_reward")
	GameState.power = 2000
	var trivial_gain := GameState.calculate_hit_gain(18, 40, 85)
	if trivial_gain != 1: failures.append("diminishing_low_mob_reward")
	var test_result := 0 if failures.is_empty() else 1
	if failures.is_empty():
		print("[SELF_TEST] PASS world, maps, player, enemies, quests, skills and progression")
	else:
		print("[SELF_TEST] FAIL ", failures)
	set_process(false)
	set_physics_process(false)
	_clear_zone()
	if is_instance_valid(hud):
		hud.queue_free()
	if is_instance_valid(player):
		player.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(test_result)
