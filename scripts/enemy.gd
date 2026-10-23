extends CharacterBody2D
class_name DBEnemy

signal defeated(enemy: DBEnemy)
signal player_hit(amount: int)

var enemy_id := "wolf_raider"
var display_name := "Lobo Salvaje"
var max_hp := 85
var hp := 85
var move_speed := 100.0
var damage := 12
var armor_rating := 12
var mob_ki_power := 4
var mob_crit_chance := 3.0
var mob_crit_damage := 150.0
var mob_dodge_chance := 1.5
var mob_role := "melee"
var reward_zeni := 8
var target: DBPlayer
var attack_timer := 0.0
var hurt_timer := 0.0
var stun_timer := 0.0
var blind_timer := 0.0
var special_timer := 3.0
var ranged_timer := 2.2
var boss_pattern_timer := 2.4
var loot: Array = []
var mob_power := 18
var mob_type := "melee"
var is_boss := false
var mob_color := Color("#b8a58f")
var mob_accent := Color("#6f5847")
var phase := 1
var floor_y := 622.0
var spawn_position := Vector2.ZERO
var leash_distance := 920.0
var combat_slot := 0
var sprite: AnimatedSprite2D
var _bob := 0.0
var _dead := false

func _ready() -> void:
    add_to_group("enemies")
    z_index = 12

func setup(p: DBPlayer, kind: String = "wolf_raider", difficulty: int = 1) -> void:
    target = p
    enemy_id = kind
    combat_slot = (get_instance_id() % 7) - 3
    _apply_catalog(kind, difficulty)
    _setup_sprite()
    queue_redraw()

func _apply_catalog(kind: String, difficulty: int) -> void:
    if kind == "temple_guardian":
        display_name = "Guardián del Templo"
        mob_power = 230 + maxi(0, difficulty - 1) * 20
        mob_type = "boss"
        is_boss = true
        mob_role = "boss"
        var boss_profile := MobCatalog.derived_stats(kind, {"power": mob_power, "type": "boss", "boss": true, "speed": 110.0})
        max_hp = int(boss_profile.get("hp", 1564))
        damage = int(boss_profile.get("attack", 87))
        armor_rating = int(boss_profile.get("armor_rating", 120))
        mob_ki_power = int(boss_profile.get("ki_power", 90))
        mob_crit_chance = float(boss_profile.get("crit_chance", 8.0))
        mob_crit_damage = float(boss_profile.get("crit_damage", 175.0))
        mob_dodge_chance = float(boss_profile.get("dodge_chance", 4.0))
        move_speed = float(boss_profile.get("speed", 110.0))
        reward_zeni = 320
        mob_color = Color("#7e5ee6")
        mob_accent = Color("#ff7c61")
        loot = ["dragon_orb", "namek_charm", "ice_guard"]
        phase = 1
        special_timer = 3.0
        hp = max_hp
        return
    var data: Dictionary = MobCatalog.lookup(kind)
    if data.is_empty():
        data = {
            "name":"Lobo Salvaje","power":18,"hp":85,"speed":100.0,"damage":12,"zeni":8,
            "type":"melee","color":Color("#b8a58f"),"accent":Color("#6f5847"),"loot":["raw_meat"]
        }
    display_name = str(data.get("name", kind))
    mob_power = int(data.get("power",18)) + maxi(0,difficulty-1) * 12
    var profile := MobCatalog.derived_stats(kind, data)
    max_hp = int(profile.get("hp", 85))
    move_speed = float(profile.get("speed", data.get("speed",100.0))) + maxi(0,difficulty-1) * 1.5
    damage = int(profile.get("attack", 12))
    armor_rating = int(profile.get("armor_rating", 12))
    mob_ki_power = int(profile.get("ki_power", 4))
    mob_crit_chance = float(profile.get("crit_chance", 3.0))
    mob_crit_damage = float(profile.get("crit_damage", 150.0))
    mob_dodge_chance = float(profile.get("dodge_chance", 1.5))
    mob_role = str(profile.get("role", "melee"))
    reward_zeni = int(data.get("zeni",8)) + maxi(0,difficulty-1) * 2
    mob_type = str(data.get("type","melee"))
    is_boss = bool(data.get("boss", false))
    mob_color = data.get("color",Color("#b8a58f"))
    mob_accent = data.get("accent",Color("#6f5847"))
    loot = data.get("loot",[])
    hp = max_hp

func _setup_sprite() -> void:
    if sprite != null:
        sprite.queue_free()
        sprite = null
    if enemy_id in ["forest_beast", "temple_guardian"]:
        sprite = AnimatedSprite2D.new()
        sprite.sprite_frames = SpriteFrames.new()
        var frames := sprite.sprite_frames
        var prefix := "guardian" if enemy_id == "temple_guardian" else "beast"
        for anim in ["idle", "attack"]:
            frames.add_animation(anim)
            frames.set_animation_speed(anim, 5.0 if anim == "idle" else 8.0)
            frames.set_animation_loop(anim, anim == "idle")
            var count := 4 if anim == "idle" else 2
            for i in range(count):
                var path := "res://assets/sprites/enemy/%s_%s_%d.svg" % [prefix, anim, i]
                if not ResourceLoader.exists(path) and anim == "attack":
                    path = "res://assets/sprites/enemy/%s_idle_%d.svg" % [prefix, i % 4]
                var tex := load(path) as Texture2D
                if tex:
                    frames.add_frame(anim, tex)
        sprite.scale = Vector2(1.2,1.2) if enemy_id != "temple_guardian" else Vector2(1.8,1.8)
        add_child(sprite)
    queue_redraw()

func _physics_process(delta: float) -> void:
    _bob += delta
    attack_timer = maxf(0.0, attack_timer - delta)
    hurt_timer = maxf(0.0, hurt_timer - delta)
    stun_timer = maxf(0.0, stun_timer - delta)
    blind_timer = maxf(0.0, blind_timer - delta)
    special_timer = maxf(0.0, special_timer - delta)
    ranged_timer = maxf(0.0, ranged_timer - delta)
    boss_pattern_timer = maxf(0.0, boss_pattern_timer - delta)

    if is_boss and phase == 1 and float(hp) / float(max_hp) < 0.60:
        phase = 2
        move_speed *= 1.28
        damage += 14
        mob_color = mob_color.lightened(0.12)
        mob_accent = mob_accent.lightened(0.20)
        stun_timer = 0.0
        special_timer = 1.0

    if target == null or target.hp <= 0 or stun_timer > 0.0:
        velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
        move_and_slide()
        _update_sprite()
        return

    if blind_timer > 0.0:
        # Taiyōken: completely disables movement and attacks while blinded.
        velocity = velocity.move_toward(Vector2.ZERO, 1800.0 * delta)
        move_and_slide()
        _update_sprite()
        queue_redraw()
        return

    var distance := global_position.distance_to(target.global_position)
    var from_spawn := global_position.distance_to(spawn_position) if spawn_position != Vector2.ZERO else 0.0
    if is_boss and boss_pattern_timer <= 0.0 and distance < 880.0:
        _execute_boss_pattern(distance)
    var horizontal := target.global_position.x - global_position.x
    if from_spawn > leash_distance:
        var home_delta := spawn_position.x - global_position.x
        velocity.x = signf(home_delta) * move_speed * 1.10
        if absf(home_delta) < 60.0:
            velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
        if not is_on_floor():
            velocity.y += 1400.0 * delta
        else:
            velocity.y = 0.0
        move_and_slide()
        if global_position.y > floor_y:
            global_position.y = floor_y
            velocity.y = 0.0
        _update_sprite()
        queue_redraw()
        return
    if distance < 760.0:
        if mob_type == "ranged":
            if absf(horizontal) > 300.0:
                velocity.x = signf(horizontal) * move_speed
            else:
                velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
            if ranged_timer <= 0.0 and distance < 640.0:
                ranged_timer = 1.7 if is_boss else 2.0
                _fire_projectile()
        else:
            var slot_target_x := target.global_position.x + float(combat_slot) * 58.0
            var slot_delta := slot_target_x - global_position.x
            if absf(slot_delta) > 46.0:
                velocity.x = signf(slot_delta) * move_speed
            else:
                velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)
                if attack_timer <= 0.0 and distance < 120.0:
                    attack_timer = 0.95 if is_boss else 1.25
                    var hit_damage := _roll_attack_damage(damage)
                    if is_boss and phase == 2 and special_timer <= 0.0:
                        special_timer = 2.0
                        hit_damage = int(round(float(hit_damage) * 1.16))
                    player_hit.emit(hit_damage)
        if is_boss and special_timer <= 0.0 and distance < 520.0:
            special_timer = 2.6 if phase == 1 else 1.5
            player_hit.emit(_roll_attack_damage(35 if phase == 1 else 52))
    else:
        velocity.x = signf(sin(Time.get_ticks_msec() * 0.00025 + get_instance_id())) * move_speed * 0.15
    if mob_type != "ranged":
        var separation_x := 0.0
        for other in get_tree().get_nodes_in_group("enemies"):
            if other == self or not is_instance_valid(other):
                continue
            var od := global_position.distance_to(other.global_position)
            if od < 82.0:
                if od <= 0.5:
                    separation_x += -1.0 if get_instance_id() < other.get_instance_id() else 1.0
                else:
                    separation_x += (global_position.x - other.global_position.x) / od * (82.0 - od)
        if absf(separation_x) > 0.01:
            velocity.x += separation_x * 8.5
    if not is_on_floor():
        velocity.y += 1400.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()
    if global_position.y > floor_y:
        global_position.y = floor_y
        velocity.y = 0.0
    _update_sprite()
    queue_redraw()

func _execute_boss_pattern(distance: float) -> void:
    match enemy_id:
        "arena_champion":
            boss_pattern_timer = 3.2 if phase == 1 else 2.1
            var dir_x := signf(target.global_position.x - global_position.x)
            velocity.x = dir_x * move_speed * (3.0 if phase == 1 else 3.8)
            velocity.y = -220.0 if not is_on_floor() else -320.0
            if distance < 260.0:
                player_hit.emit(_roll_attack_damage(95 if phase == 1 else 135))
        "wasteland_overlord":
            boss_pattern_timer = 4.0 if phase == 1 else 2.8
            if distance < 560.0:
                player_hit.emit(_roll_attack_damage(110 if phase == 1 else 165))
            else:
                var base_dir := (target.global_position - global_position).normalized()
                var spread := [-0.22, 0.0, 0.22] if phase == 1 else [-0.36, -0.18, 0.0, 0.18, 0.36]
                for angle in spread:
                    _fire_projectile_dir(base_dir.rotated(float(angle)), int(damage * (0.80 if phase == 1 else 1.0)) + 14)
        "otherworld_judge":
            boss_pattern_timer = 4.4 if phase == 1 else 3.0
            var base_dir := (target.global_position - global_position).normalized()
            var count := 3 if phase == 1 else 6
            for i in range(count):
                var t := float(i) / maxf(1.0, float(count - 1)) - 0.5
                _fire_projectile_dir(base_dir.rotated(t * 0.75), int(damage * 0.72) + 20)
            if phase == 2 and distance > 300.0:
                global_position.x = clampf(target.global_position.x - 240.0 * signf(base_dir.x), 120.0, 4100.0)
        "temple_guardian":
            boss_pattern_timer = 4.0 if phase == 1 else 2.6
            if distance < 520.0:
                player_hit.emit(_roll_attack_damage(70 if phase == 1 else 105))
                if phase == 2:
                    target.take_damage(30)
        _:
            boss_pattern_timer = 3.0
            if distance < 480.0:
                player_hit.emit(_roll_attack_damage(70 if phase == 1 else 100))

func _fire_projectile() -> void:
    var dir := (target.global_position - global_position).normalized()
    _fire_projectile_dir(dir, int(damage * 0.8) + 6)

func _fire_projectile_dir(dir: Vector2, amount: int) -> void:
    var scene := load("res://scenes/enemies/projectile.tscn")
    var p: KIProjectile = scene.instantiate()
    get_parent().add_child(p)
    p.setup_enemy(global_position + dir * 28.0, dir, maxi(1, _roll_attack_damage(amount)), self, mob_color)

func _update_sprite() -> void:
    if sprite == null:
        return
    if hurt_timer > 0.0:
        sprite.modulate = Color(1.4,0.5,0.5,1)
    else:
        sprite.modulate = Color.WHITE
    if attack_timer > 0.0:
        sprite.play("attack")
    else:
        sprite.play("idle")

func _roll_attack_damage(base: int) -> int:
    var out := maxi(1, base)
    if randf() * 100.0 < mob_crit_chance:
        out = maxi(out + 1, int(round(float(out) * (mob_crit_damage / 100.0))))
    return out

func apply_blind(duration: float) -> void:
    if duration <= 0.0 or hp <= 0 or _dead:
        return
    blind_timer = maxf(blind_timer, duration)
    stun_timer = 0.0
    velocity = Vector2.ZERO

func is_blinded() -> bool:
    return blind_timer > 0.0

func take_damage(amount: int, knockback := Vector2.ZERO, stun := 0.0) -> int:
    if hp <= 0 or _dead:
        return 0
    if randf() * 100.0 < mob_dodge_chance:
        return 0
    var reduction := GameState.damage_reduction_from_armor(armor_rating)
    var actual := mini(maxi(1, int(round(float(amount) * (1.0 - reduction)))), hp)
    hp -= actual
    hurt_timer = 0.16
    stun_timer = maxf(stun_timer, stun)
    velocity += knockback
    queue_redraw()
    if hp <= 0:
        _dead = true
        defeated.emit(self)
        queue_free()
    return actual

func get_reward() -> Dictionary:
    return {"power":mob_power, "zeni":reward_zeni, "id":enemy_id, "loot":loot.duplicate(), "name":display_name}

func _draw() -> void:
    if blind_timer > 0.0:
        var pulse := 0.92 + 0.10 * sin(Time.get_ticks_msec() * 0.015)
        draw_circle(Vector2(0,-28), 34.0 * pulse, Color(1.0,0.90,0.38,0.20))
        draw_arc(Vector2(0,-28), 28.0 * pulse, 0.0, TAU, 24, Color(1.0,0.94,0.45,0.85), 3.0)
    if enemy_id in ["forest_beast", "temple_guardian"] and sprite != null:
        if is_boss or enemy_id == "temple_guardian":
            var aura_color := Color(0.55,0.25,0.95,0.10) if phase==1 else Color(1.0,0.18,0.10,0.16)
            draw_circle(Vector2.ZERO,60.0+sin(Time.get_ticks_msec()*0.01)*5.0,aura_color)
            var ratio := clampf(float(hp)/float(max_hp),0.0,1.0)
            draw_rect(Rect2(-60,-90,120,8),Color(0.05,0.05,0.08,0.9),true)
            draw_rect(Rect2(-60,-90,120*ratio,8),Color(0.90,0.24,0.26),true)
            return
    var squash := 1.0 + sin(_bob*7.0 + get_instance_id()*0.01)*0.03
    var yoff := sin(_bob*3.5 + get_instance_id()*0.01)*2.0
    if hurt_timer > 0.0:
        yoff -= 3.0
    draw_set_transform(Vector2(0,yoff),0,Vector2(1.0,squash))
    if enemy_id == "wolf_raider" or enemy_id == "ice_wolf":
        # quadruped wolf
        draw_colored_polygon(PackedVector2Array([Vector2(-28,15),Vector2(-12,-10),Vector2(8,-12),Vector2(27,4),Vector2(16,20),Vector2(-10,24)]),mob_color)
        draw_colored_polygon(PackedVector2Array([Vector2(3,-18),Vector2(18,-32),Vector2(31,-22),Vector2(26,-5),Vector2(8,-3)]),mob_color)
        draw_colored_polygon(PackedVector2Array([Vector2(10,-31),Vector2(12,-49),Vector2(20,-37)]),mob_accent)
        draw_colored_polygon(PackedVector2Array([Vector2(22,-29),Vector2(35,-43),Vector2(32,-21)]),mob_accent)
        draw_circle(Vector2(28,-20),3.0,Color("#ffdf52"))
        draw_line(Vector2(-20,10),Vector2(-32,23),mob_accent,6)
        if enemy_id == "ice_wolf":
            draw_arc(Vector2(0,0),34,0,TAU,18,Color(0.75,0.95,1,0.35),4)
    elif enemy_id == "saibaman" or enemy_id == "saibaman_elite":
        draw_circle(Vector2(0,-20),14,mob_color)
        draw_colored_polygon(PackedVector2Array([Vector2(-18,-16),Vector2(-25,-34),Vector2(-17,-40),Vector2(-9,-18)]),mob_accent)
        draw_colored_polygon(PackedVector2Array([Vector2(18,-16),Vector2(25,-34),Vector2(17,-40),Vector2(9,-18)]),mob_accent)
        draw_rect(Rect2(-14,-6,28,35),mob_color,true)
        draw_line(Vector2(-8,28),Vector2(-13,48),mob_accent,7)
        draw_line(Vector2(8,28),Vector2(13,48),mob_accent,7)
        draw_line(Vector2(-13,3),Vector2(-31,14),mob_accent,6)
        draw_line(Vector2(13,3),Vector2(31,14),mob_accent,6)
        draw_circle(Vector2(-5,-22),2.5,Color("#c7ff66"))
        draw_circle(Vector2(5,-22),2.5,Color("#c7ff66"))
        if enemy_id == "saibaman_elite":
            draw_arc(Vector2(0,-5),36,0,TAU,24,Color(0.70,0.28,0.95,0.45),4)
    elif enemy_id == "boar_brute":
        draw_colored_polygon(PackedVector2Array([Vector2(-31,8),Vector2(-22,-9),Vector2(2,-16),Vector2(25,-6),Vector2(34,9),Vector2(20,25),Vector2(-18,25)]),mob_color)
        draw_circle(Vector2(23,-10),12,mob_color)
        draw_colored_polygon(PackedVector2Array([Vector2(30,-8),Vector2(44,-2),Vector2(31,2)]),mob_accent)
        draw_line(Vector2(-16,22),Vector2(-22,45),mob_accent,7)
        draw_line(Vector2(14,23),Vector2(20,45),mob_accent,7)
        draw_circle(Vector2(28,-13),2.5,Color("#ffeb72"))
    else:
        # humanoid / alien silhouette
        draw_circle(Vector2(0,-26),13,mob_color)
        draw_rect(Rect2(-14,-12,28,38),mob_color,true)
        draw_rect(Rect2(-22,-4,44,9),mob_accent,true)
        draw_rect(Rect2(-17,25,12,22),mob_accent,true)
        draw_rect(Rect2(5,25,12,22),mob_accent,true)
        draw_line(Vector2(-14,3),Vector2(-29,18),mob_accent,7)
        draw_line(Vector2(14,3),Vector2(29,18),mob_accent,7)
        draw_circle(Vector2(-4,-28),2.5,Color.WHITE)
        draw_circle(Vector2(4,-28),2.5,Color.WHITE)
        if enemy_id == "desert_bandit":
            draw_rect(Rect2(-18,-40,36,8),Color("#6a2c23"),true)
            draw_circle(Vector2(0,-40),4,Color("#d7bd54"))
        elif enemy_id == "dino_scavenger":
            draw_colored_polygon(PackedVector2Array([Vector2(-22,-10),Vector2(-44,-18),Vector2(-32,0)]),mob_accent)
        elif enemy_id == "pirate_raider":
            draw_rect(Rect2(-16,-45,32,9),Color("#19274a"),true)
            draw_line(Vector2(8,-45),Vector2(22,-57),Color("#d1d7eb"),4)
        elif enemy_id == "frost_soldier":
            draw_arc(Vector2(0,-15),36,0,TAU,24,Color(0.75,0.8,1,0.35),5)
        elif enemy_id == "namek_raider":
            draw_colored_polygon(PackedVector2Array([Vector2(-12,-38),Vector2(-5,-58),Vector2(0,-42),Vector2(8,-60),Vector2(13,-38)]),mob_accent)
            draw_arc(Vector2(0,-24),18,3.3,6.1,12,Color(0.74,1,0.90,0.8),3)
    draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    var ratio := clampf(float(hp)/float(max_hp),0.0,1.0)
    draw_rect(Rect2(-31,-70,62,6),Color(0.04,0.05,0.07,0.85),true)
    draw_rect(Rect2(-31,-70,62*ratio,6),Color("#74e06a" if ratio > 0.45 else "#ffb04e"),true)
    draw_string(ThemeDB.fallback_font,Vector2(-55,-78),display_name,HORIZONTAL_ALIGNMENT_CENTER,110,11,Color(0.92,0.94,1.0,0.90))
    draw_string(ThemeDB.fallback_font,Vector2(-60,66),"PWR %d" % mob_power,HORIZONTAL_ALIGNMENT_CENTER,120,10,Color(0.75,0.86,1.0,0.70))
