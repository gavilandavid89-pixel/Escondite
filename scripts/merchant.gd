extends StaticBody2D
class_name MerchantNPC

var display_name := "Mercader Bulma"
var role := "merchant"
var _pulse := 0.0

func _ready() -> void:
	z_index = 10
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new(); shape.size = Vector2(34,70)
	cs.shape = shape
	add_child(cs)
	queue_redraw()

func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()

func interact() -> Dictionary:
	return {"speaker":display_name, "text":"¡Bienvenido! Tengo equipo y provisiones para viajeros.", "action":"shop"}

func _draw() -> void:
	var body := Color("#d86d3f")
	var cloth := Color("#3b65a1")
	_draw_ellipse_custom(Vector2(0,34),Vector2(25,8),Color(0,0,0,0.25))
	draw_rect(Rect2(-16,-4,32,40),body,true)
	draw_rect(Rect2(-12,9,24,7),Color("#f5c84b"),true)
	draw_circle(Vector2(0,-18),14,Color("#e4aa76"))
	var hair:=PackedVector2Array([Vector2(-14,-24),Vector2(-8,-36),Vector2(-2,-29),Vector2(5,-39),Vector2(12,-28),Vector2(15,-17),Vector2(-13,-15)])
	draw_colored_polygon(hair,Color("#5e4430"))
	draw_rect(Rect2(-18,36,16,22),cloth,true)
	draw_rect(Rect2(2,36,16,22),cloth,true)
	draw_circle(Vector2(0,-55),8.0 + sin(_pulse*3.0)*1.6,Color(1,0.78,0.22,0.14))
	draw_string(ThemeDB.fallback_font,Vector2(-70,-58),display_name,HORIZONTAL_ALIGNMENT_CENTER,140,13,Color(1,0.92,0.64))

func _draw_ellipse_custom(center:Vector2,radii:Vector2,color:Color)->void:
	var points:=PackedVector2Array()
	for i in range(24):
		var a:=TAU*float(i)/24.0
		points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(points,color)
