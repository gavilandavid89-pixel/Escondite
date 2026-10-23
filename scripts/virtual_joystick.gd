extends Control
class_name DBVirtualJoystick

var vector := Vector2.ZERO
var active_touch := -1
var base_radius := 78.0
var knob_radius := 32.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(180,180)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_touch == -1:
			active_touch = event.index
			_set_from_local(event.position)
		elif not event.pressed and event.index == active_touch:
			active_touch = -1
			vector = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == active_touch:
		_set_from_local(event.position)

func _set_from_local(pos: Vector2) -> void:
	var center := size * 0.5
	var delta := pos-center
	vector = delta.normalized()*minf(delta.length()/base_radius,1.0)
	queue_redraw()

func get_vector() -> Vector2:
	return vector

func _draw() -> void:
	var c:=size*0.5
	draw_circle(c,base_radius,Color(0.03,0.05,0.08,0.48))
	draw_arc(c,base_radius,0,TAU,48,Color(0.38,0.65,0.92,0.65),3)
	draw_circle(c+vector*base_radius*0.68,knob_radius,Color(0.24,0.52,0.84,0.78))
	draw_arc(c+vector*base_radius*0.68,knob_radius,0,TAU,32,Color(0.55,0.82,1,0.8),2)
