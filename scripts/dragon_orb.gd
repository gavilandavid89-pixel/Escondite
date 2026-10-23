extends Area2D
class_name DragonOrbPickup

signal collected
var _time := 0.0
var orb_index := 1
var orb_id := ""

func setup(index_value:int=1, id_value:String="") -> void:
	orb_index = index_value
	orb_id = id_value
	collision_layer = 0
	collision_mask = 2
	var cs:=CollisionShape2D.new()
	var shape:=CircleShape2D.new(); shape.radius=22.0; cs.shape=shape
	add_child(cs)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _process(delta:float)->void:
	_time += delta
	position.y += sin(_time*2.3)*0.12
	queue_redraw()

func _on_body_entered(body:Node)->void:
	if body is DBPlayer:
		collected.emit()
		queue_free()

func _draw()->void:
	draw_circle(Vector2.ZERO,26.0,Color(1.0,0.45,0.18,0.10))
	draw_circle(Vector2.ZERO,17.0,Color("#f39a3f"))
	draw_circle(Vector2.ZERO,12.0,Color("#ffd767"))
	# estrella estilizada
	for i in range(orb_index):
		var a:=TAU*float(i)/7.0-PI*0.5
		draw_circle(Vector2(cos(a)*7.0,sin(a)*7.0),1.6,Color("#b64824"))
