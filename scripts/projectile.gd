extends Area2D
class_name KIProjectile

signal enemy_hit(enemy: Node, actual_damage: int)

var direction := Vector2.RIGHT
var speed := 620.0
var damage := 50
var life := 1.2
var owner_node: Node
var target_mode := "enemies"
var color := Color(0.35,0.80,1.0)
var skill_id := ""
var skill_rank := 1
var visual: Sprite2D

func setup(at: Vector2, dir: Vector2, amount: int, owner_ref: Node, tint: Color, vfx_id: String = "", vfx_rank: int = 1) -> void:
    global_position = at
    direction = dir.normalized()
    damage = amount
    owner_node = owner_ref
    target_mode = "enemies"
    color = tint
    skill_id = vfx_id
    skill_rank = clampi(vfx_rank, 1, 10)
    z_index = 30
    _setup_visual()
    queue_redraw()

func setup_enemy(at: Vector2, dir: Vector2, amount: int, owner_ref: Node, tint: Color) -> void:
    global_position = at
    direction = dir.normalized()
    damage = amount
    owner_node = owner_ref
    target_mode = "player"
    speed = 420.0
    life = 2.0
    color = tint
    z_index = 30
    _setup_visual()
    queue_redraw()

func _setup_visual() -> void:
    if visual != null and is_instance_valid(visual):
        visual.queue_free()
    visual = Sprite2D.new()
    visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(visual)
    if skill_id != "":
        var dir := SkillManager.effect_dir(skill_id)
        var path := "%s/rank_%02d.png" % [dir, skill_rank]
        if dir != "" and ResourceLoader.exists(path):
            visual.texture = load(path) as Texture2D
            visual.modulate = color
            var s := 0.50 + 0.07 * float(skill_rank - 1)
            visual.scale = Vector2(s, s)
            visual.rotation = 0.0
            return
    visual.texture = null

func _physics_process(delta: float) -> void:
    position += direction * speed * delta
    life -= delta
    if life <= 0.0:
        queue_free()
        return
    if target_mode == "enemies":
        for n in get_tree().get_nodes_in_group("enemies"):
            if n == owner_node or not is_instance_valid(n):
                continue
            if n.global_position.distance_to(global_position) < 42.0 and n.has_method("take_damage"):
                var rolled_damage := GameState.critical_damage(damage) if owner_node is DBPlayer else damage
                var actual: int = n.take_damage(rolled_damage, Vector2.ZERO, 0.0)
                enemy_hit.emit(n, actual)
                queue_free()
                return
    else:
        var player := get_tree().get_first_node_in_group("player")
        if player and player != owner_node and is_instance_valid(player) and player.global_position.distance_to(global_position) < 42.0:
            if player.has_method("take_damage"):
                player.take_damage(damage)
            queue_free()
            return
    queue_redraw()

func _draw() -> void:
    if visual != null and visual.texture != null:
        return
    draw_circle(Vector2.ZERO, 16.0, Color(color.r,color.g,color.b,0.16))
    draw_circle(Vector2.ZERO, 9.0, color)
    draw_circle(Vector2.ZERO, 3.5, Color.WHITE)
    draw_line(-direction * 5.0, -direction * 24.0, Color(color.r,color.g,color.b,0.25), 8.0)
