extends CharacterBody2D
class_name DBPlayer

signal hp_changed(current: int, maximum: int)
signal ki_changed(current: int, maximum: int)
signal power_changed(value: int)
signal coins_changed(value: int)
signal attack_fired(origin: Vector2, direction: Vector2)
signal skill_fired(skill_id: String, origin: Vector2, direction: Vector2)
signal died
signal jumped
signal flight_changed(enabled: bool)
signal race_changed(race: String)

const GRAVITY := 1450.0
const JUMP_SPEED := -560.0
const ATTACK_COOLDOWN := 0.28
const AIR_ATTACK_RANGE := 106.0

var hp := 140
var ki := 120
var zeni := 80
var skill_cooldowns: Dictionary = {}
var joystick: Control
var control_enabled := true
var facing := 1
var _attack_timer := 0.0
var _hurt_timer := 0.0
var _attack_state := 0.0
var _skill_lock := 0.0
var _transform_timer := 0.0
var _charging := ""
var _air_combo := 0
var _air_combo_timer := 0.0
var _defense_timer := 0.0
var _barrier_timer := 0.0
var _barrier_rank := 1
var selected_skill_id := "basic_punch"
var sprite: AnimatedSprite2D
var flight_enabled := false
var transform_id := ""

func _ready() -> void:
    add_to_group("player")
    z_index = 20
    collision_layer = 2
    collision_mask = 1 | 3
    RaceManager.validate_loadout()
    _setup_sprite()
    _sync_from_state()
    race_changed.emit(GameState.race)
    queue_redraw()

func _race_dir() -> String:
    return GameState.race.replace(" ", "_")

func _setup_sprite() -> void:
    sprite = AnimatedSprite2D.new()
    sprite.name = "Sprite"
    sprite.sprite_frames = SpriteFrames.new()
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    var frames := sprite.sprite_frames
    var root := "res://assets/pixel/races/%s" % _race_dir()
    _add_frames(frames, "idle", "%s/idle_%%d.png" % root, 4, 5.0)
    _add_frames(frames, "run", "%s/run_%%d.png" % root, 4, 10.0)
    _add_frames(frames, "attack", "%s/attack_%%d.png" % root, 3, 12.0, false)
    _add_frames(frames, "jump", "%s/jump_0.png" % root, 1, 1.0, false)
    _add_frames(frames, "hurt", "%s/hurt_0.png" % root, 1, 1.0, false)
    _add_frames(frames, "transform_idle", "%s/transform_idle_%%d.png" % root, 4, 6.0)
    sprite.centered = true
    sprite.scale = Vector2(1.65, 1.65)
    add_child(sprite)

func _add_frames(frames: SpriteFrames, anim: String, pattern: String, count: int, speed: float, loop := true) -> void:
    frames.add_animation(anim)
    frames.set_animation_speed(anim, speed)
    frames.set_animation_loop(anim, loop)
    for i in range(count):
        var path := pattern if not pattern.contains("%d") else pattern % i
        var texture := load(path) as Texture2D
        if texture:
            frames.add_frame(anim, texture)

func _sync_from_state() -> void:
    zeni = GameState.zeni
    hp = clampi(GameState.hp, 1, GameState.max_hp())
    ki = clampi(GameState.ki, 0, GameState.max_ki())
    flight_enabled = GameState.flight_enabled and GameState.flight_unlocked
    transform_id = "" if GameState.transformation == "base" else GameState.transformation
    if not SkillManager.is_learned(selected_skill_id) or not SkillManager.is_allowed_for_race(selected_skill_id):
        selected_skill_id = "basic_punch"

func setup_mobile_input(input: Control) -> void:
    joystick = input

func _physics_process(delta: float) -> void:
    _attack_timer = maxf(0.0, _attack_timer - delta)
    _attack_state = maxf(0.0, _attack_state - delta)
    _hurt_timer = maxf(0.0, _hurt_timer - delta)
    _skill_lock = maxf(0.0, _skill_lock - delta)
    _transform_timer = maxf(0.0, _transform_timer - delta)
    _air_combo_timer = maxf(0.0, _air_combo_timer - delta)
    _defense_timer = maxf(0.0, _defense_timer - delta)
    _barrier_timer = maxf(0.0, _barrier_timer - delta)
    for id in skill_cooldowns.keys():
        skill_cooldowns[id] = maxf(0.0, float(skill_cooldowns[id]) - delta)

    if _air_combo_timer <= 0.0:
        _air_combo = 0
    if _transform_timer <= 0.0 and transform_id != "":
        transform_id = ""
        GameState.transformation = "base"
        GameState.changed.emit()

    if Input.is_action_just_pressed("toggle_flight") and GameState.flight_unlocked:
        toggle_flight()

    var input_x := Input.get_axis("move_left", "move_right")
    var input_y := 0.0
    if joystick != null and joystick.has_method("get_vector"):
        var v: Vector2 = joystick.get_vector()
        if absf(v.x) > absf(input_x): input_x = v.x
        input_y = v.y

    if control_enabled and _skill_lock <= 0.0:
        var speed := GameState.move_speed() + InventoryManager.equipment_bonus("speed")
        var mult := SkillManager.transformation_speed_multiplier(transform_id)
        speed *= mult
        if transform_id == "kaioken":
            var drain := maxi(1, int(round(float(GameState.max_hp()) * 0.035 * delta)))
            hp = maxi(1, hp - drain)
            GameState.hp = hp
            hp_changed.emit(hp, GameState.max_hp())
        if flight_enabled:
            velocity.x = move_toward(velocity.x, input_x * speed, 1900.0 * delta)
            velocity.y = move_toward(velocity.y, input_y * speed * 0.82, 1900.0 * delta)
            if absf(input_x) > 0.1: facing = 1 if input_x > 0 else -1
        else:
            if not is_on_floor():
                velocity.y += GRAVITY * delta
            else:
                velocity.y = minf(velocity.y, 50.0)
            velocity.x = move_toward(velocity.x, input_x * speed, 1900.0 * delta)
            if absf(input_x) > 0.1: facing = 1 if input_x > 0 else -1
            if Input.is_action_just_pressed("jump") and is_on_floor():
                velocity.y = JUMP_SPEED
                jumped.emit()
    else:
        velocity.x = move_toward(velocity.x, 0.0, 2100.0 * delta)
        if not flight_enabled and not is_on_floor(): velocity.y += GRAVITY * delta

    move_and_slide()
    _update_animation()
    _regenerate_ki(delta)
    queue_redraw()

func toggle_flight() -> void:
    if not GameState.flight_unlocked:
        return
    flight_enabled = not flight_enabled
    GameState.flight_enabled = flight_enabled
    if flight_enabled:
        velocity.y = 0.0
    else:
        if not is_on_floor(): velocity.y = minf(velocity.y, 180.0)
    flight_changed.emit(flight_enabled)
    AudioManager.play("transform", -6.0)
    GameState.changed.emit()

func _regenerate_ki(delta: float) -> void:
    var regen := GameState.ki_regen_rate()
    ki = mini(GameState.max_ki(), int(ki + regen * delta))
    GameState.ki = ki
    if int(Time.get_ticks_msec() / 100) % 3 == 0:
        ki_changed.emit(ki, GameState.max_ki())

func _update_animation() -> void:
    if sprite == null: return
    sprite.flip_h = facing < 0
    if _hurt_timer > 0.0:
        sprite.play("hurt")
    elif _attack_state > 0.0:
        sprite.play("attack")
    elif _transform_timer > 0.0:
        sprite.play("transform_idle")
    elif not flight_enabled and not is_on_floor():
        sprite.play("jump")
    elif flight_enabled:
        sprite.play("run")
    elif absf(velocity.x) > 20.0:
        sprite.play("run")
    else:
        sprite.play("idle")

func _aim_direction() -> Vector2:
    var dir := Vector2(float(facing), 0.0)
    if joystick != null and joystick.has_method("get_vector"):
        var v: Vector2 = joystick.get_vector()
        if v.length() > 0.25:
            dir = v.normalized()
    return dir

func select_skill(id: String) -> bool:
    if not SkillManager.is_learned(id) or not SkillManager.is_allowed_for_race(id):
        return false
    selected_skill_id = id
    return true

func clear_selected_skill() -> void:
    # Kept for compatibility; clearing always returns to the default skill.
    selected_skill_id = "basic_punch"

func execute_selected_or_basic() -> bool:
    # The attack button never owns an attack. It always executes the currently selected skill.
    var id := selected_skill_id
    if id == "" or not SkillManager.is_learned(id) or not SkillManager.is_allowed_for_race(id):
        id = "basic_punch"
        selected_skill_id = id
    return use_skill(id)

func try_attack() -> bool:
    # Generic execution button: whatever skill is selected is what gets executed.
    return execute_selected_or_basic()

func use_skill(id: String) -> bool:
    if hp <= 0 or _skill_lock > 0.0 or not SkillManager.is_learned(id) or not SkillManager.is_allowed_for_race(id):
        return false
    var data := SkillManager.data(id)
    if data.is_empty(): return false
    if GameState.race == "Saiyan" and id == "kaioken":
        if hp <= int(GameState.max_hp() * 0.18):
            return false
    if GameState.race == "Raza Helada" and id == "death_beam":
        # Precision stance: hold the beam a little longer for a stronger hit.
        _skill_lock = maxf(_skill_lock, 0.62)
    var cd := float(skill_cooldowns.get(id, 0.0))
    var cost := SkillManager.ki_cost(id)
    if cd > 0.01 or ki < cost: return false
    ki -= cost; GameState.ki = ki; ki_changed.emit(ki, GameState.max_ki())
    skill_cooldowns[id] = SkillManager.cooldown(id)
    QuestManager.on_skill_used()
    var skill_type := str(data.get("type", "projectile"))
    var dir := _aim_direction()
    if skill_type in ["beam"]:
        _charging = id; _skill_lock = 0.48; velocity = Vector2.ZERO; AudioManager.play("ki", -10.0)
        get_tree().create_timer(0.48).timeout.connect(func():
            if is_instance_valid(self) and _charging == id:
                _charging = ""; skill_fired.emit(id, global_position + dir * 28.0 + Vector2(0,-18), dir); AudioManager.play("kame", -4.0)
        )
    else:
        skill_fired.emit(id, global_position + dir * 26.0 + Vector2(0,-18), dir)
        AudioManager.play("ki", -8.0)
    if skill_type == "transform":
        transform_id = str(data.get("transform", id))
        GameState.transformation = transform_id
        _transform_timer = 30.0
        _skill_lock = maxf(_skill_lock, 0.65)
        AudioManager.play("transform", -1.0)
    elif skill_type == "heal":
        var heal := 55 + int(sqrt(float(GameState.power)) * 2.0) + GameState.ki_power
        if GameState.race == "Namekiano":
            heal = int(heal * 1.35)
        elif GameState.race == "Humano":
            heal = int(heal * 0.80)
            ki = mini(GameState.max_ki(), ki + 25)
            GameState.ki = ki
        elif GameState.race == "Majin":
            heal = int(heal * 1.20)
        hp = mini(GameState.max_hp(), hp + heal)
        GameState.hp = hp
        hp_changed.emit(hp, GameState.max_hp())
    elif skill_type == "defense":
        _defense_timer = 7.0 if GameState.race != "Raza Helada" else 9.5
    elif skill_type == "barrier":
        activate_barrier(SkillManager.barrier_duration(id), SkillManager.rank(id))
    queue_redraw()
    return true

func activate_barrier(duration: float, rank_value: int) -> void:
    _barrier_timer = maxf(_barrier_timer, duration)
    _barrier_rank = maxi(1, rank_value)
    if hp > 0:
        queue_redraw()

func has_barrier() -> bool:
    return _barrier_timer > 0.0

func barrier_time_left() -> float:
    return _barrier_timer

func get_skill_cooldown(id: String) -> float:
    return float(skill_cooldowns.get(id, 0.0))

func apply_active_transform_hit(damage_amount: int) -> int:
    if damage_amount <= 0 or transform_id == "":
        return 0
    var pct := SkillManager.active_transform_heal_percent(transform_id)
    if pct <= 0.0:
        return 0
    var healed := maxi(1, int(round(float(damage_amount) * pct / 100.0)))
    var before := hp
    hp = mini(GameState.max_hp(), hp + healed)
    GameState.hp = hp
    hp_changed.emit(hp, GameState.max_hp())
    return hp - before

func has_transformation(name: String) -> bool:
    return transform_id == name and _transform_timer > 0.0

func take_damage(amount: int) -> void:
    if _hurt_timer > 0.0 or hp <= 0: return
    if randf() * 100.0 < GameState.dodge_chance:
        return
    var reduction := GameState.armor_value()
    if _defense_timer > 0.0: reduction += 24
    var armor_mult := SkillManager.transformation_armor_multiplier(transform_id)
    reduction = int(round(float(reduction) * armor_mult))
    var final_damage := maxi(1, amount - reduction)
    if has_barrier():
        final_damage = 1
    elif transform_id in ["super_saiyan", "super_saiyan_2", "potential_unleashed", "golden_frost"]:
        final_damage = int(final_damage * 0.72)
    hp = maxi(0, hp - final_damage); GameState.hp = hp; _hurt_timer = 0.35
    hp_changed.emit(hp, GameState.max_hp())
    if hp <= 0: died.emit()

func gain_power(amount: int, potential_amount: int = -1) -> void:
    if amount <= 0:
        return
    GameState.gain_power(amount, potential_amount)
    power_changed.emit(GameState.power)
    if amount >= 5:
        _show_power_popup(amount, potential_amount if potential_amount >= 0 else amount)
    ChapterManager.try_advance()

func _show_power_popup(power_gain: int, potential_gain: int) -> void:
    var l := Label.new()
    l.text = "+%d PODER   +%d POTENCIAL" % [power_gain, potential_gain]
    l.position = Vector2(-145,-120)
    l.size = Vector2(290,44)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size",16)
    l.add_theme_color_override("font_color",Color(0.45,0.93,1.0))
    add_child(l)
    var tw := create_tween().set_parallel(true)
    tw.tween_property(l,"position",l.position+Vector2(0,-35),0.9)
    tw.tween_property(l,"modulate:a",0.0,0.9).set_delay(0.25)
    tw.chain().tween_callback(l.queue_free)

func spend_stat(stat: String) -> bool:
    if not GameState.stat_upgrade_counts.has(stat):
        return false
    var old_max_hp := GameState.max_hp()
    var old_max_ki := GameState.max_ki()
    if not GameState.spend_stat(stat):
        return false
    var new_max_hp := GameState.max_hp()
    var new_max_ki := GameState.max_ki()
    if stat == "vitality":
        hp = mini(new_max_hp, hp + (new_max_hp - old_max_hp))
        GameState.hp = hp
        hp_changed.emit(hp, new_max_hp)
    elif stat == "ki_power":
        ki = mini(new_max_ki, ki + (new_max_ki - old_max_ki))
        GameState.ki = ki
        ki_changed.emit(ki, new_max_ki)
    return true

func _draw() -> void:
    if has_barrier():
        var pulse := sin(Time.get_ticks_msec() * 0.008) * 2.5
        var ring := 49.0 + pulse
        draw_circle(Vector2(0,-18), ring + 7.0, Color(0.25,0.72,1.0,0.06))
        draw_arc(Vector2(0,-18), ring, 0.0, TAU, 48, Color(0.38,0.82,1.0,0.72), 3.0)
        draw_arc(Vector2(0,-18), ring - 7.0, -1.2, 1.2, 24, Color(0.78,0.96,1.0,0.55), 2.0)
    if flight_enabled:
        draw_arc(Vector2.ZERO, 40.0 + sin(Time.get_ticks_msec()*0.01)*4.0, 0, TAU, 32, Color(0.35,0.76,1.0,0.18), 4.0)
    if _transform_timer > 0.0:
        var aura_color: Color = Color(str(RaceManager.get_data(GameState.race).get("color", "#ffffff")))
        aura_color.a = 0.10
        draw_circle(Vector2(0,-18), 44.0 + sin(Time.get_ticks_msec()*0.015)*3.0, aura_color)
    if _charging != "":
        var rr := 18.0 + sin(Time.get_ticks_msec()*0.025) * 5.0
        draw_circle(Vector2(34.0 * facing,-18), rr + 8.0, Color(0.25,0.70,1.0,0.10))
        draw_circle(Vector2(34.0 * facing,-18), rr, Color(0.45,0.88,1.0,0.78))
