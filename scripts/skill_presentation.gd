extends Node2D
class_name SkillPresentation

signal impact_ready

var skill_id := ""
var rank := 1
var mode := "beam"
var impact_delay := 0.0
var duration := 0.5
var _final_scale := Vector2.ONE

@onready var sprite: Sprite2D = $Sprite

func setup_effect(id: String, skill_rank: int, direction: Vector2, effect_mode: String = "beam", tint: Color = Color.WHITE) -> void:
    skill_id = id
    rank = clampi(skill_rank, 1, 10)
    mode = effect_mode
    var texture := _find_rank_texture(id, rank)
    if texture == null:
        queue_free()
        return
    sprite.texture = texture
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.modulate = tint
    rotation = direction.angle() + (PI if effect_mode == "beam" else 0.0)
    z_index = 25

    var r := float(rank - 1)
    var base := 0.50 + 0.08 * r
    if mode == "beam":
        var stretch := 1.0 if rank <= 3 else 1.0 + 0.12 * float(rank - 3)
        _final_scale = Vector2(base * stretch, base * (1.0 + 0.03 * r))
        duration = 0.40 + 0.015 * r
        impact_delay = duration * 0.82
    elif mode == "area":
        _final_scale = Vector2.ONE * (0.62 + 0.13 * r)
        duration = 0.30 + 0.018 * r
        impact_delay = duration * 0.86
    elif mode == "projectile":
        _final_scale = Vector2.ONE * (0.50 + 0.07 * r)
        duration = 0.20
        impact_delay = 0.0
    else:
        _final_scale = Vector2.ONE * base
        duration = 0.30
        impact_delay = duration * 0.8

    scale = _final_scale * (0.90 if mode != "projectile" else 1.0)
    var appear := create_tween()
    appear.tween_property(self, "scale", _final_scale, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

    get_tree().create_timer(impact_delay).timeout.connect(func():
        if is_instance_valid(self):
            impact_ready.emit()
    )
    get_tree().create_timer(duration).timeout.connect(func():
        if is_instance_valid(self):
            var fade := create_tween()
            fade.tween_property(self, "modulate:a", 0.0, 0.10)
            fade.tween_callback(queue_free)
    )

func _find_rank_texture(id: String, skill_rank: int) -> Texture2D:
    var sm: Node = get_node_or_null("/root/SkillManager")
    if sm == null:
        return null
    var dir: String = str(sm.effect_dir(id))
    if dir == "":
        return null
    var path := "%s/rank_%02d.png" % [dir, skill_rank]
    if ResourceLoader.exists(path):
        return load(path) as Texture2D
    return null
