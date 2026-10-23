extends Area2D
class_name MapPortal

signal entered(target_zone: String, spawn_x: float, spawn_y: float)

var target_zone := "forest"
var spawn_position := Vector2(120, 560)
var label_text := "SALIR"

func setup(zone: String, spawn: Vector2, text_value: String) -> void:
	collision_layer = 0
	collision_mask = 2
	target_zone = zone
	spawn_position = spawn
	label_text = text_value
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(50, 120)
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body is DBPlayer:
		entered.emit(target_zone, spawn_position.x, spawn_position.y)

func _draw() -> void:
	draw_rect(Rect2(-25,-60,50,120), Color(0.30,0.70,1.0,0.08), true)
	draw_arc(Vector2.ZERO, 30.0 + sin(Time.get_ticks_msec()*0.004)*3.0, 0, TAU, 28, Color(0.40,0.82,1,0.65), 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(-48,-70), label_text, HORIZONTAL_ALIGNMENT_CENTER, 96, 13, Color(0.72,0.92,1.0))
