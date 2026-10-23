extends StaticBody2D
class_name MasterNPC

signal interacted(npc: MasterNPC)

var display_name := "Maestro Kaio"
var role := "mentor"
var _pulse := 0.0

func _ready() -> void:
    z_index = 10
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new(); shape.size = Vector2(34,70)
    cs.shape = shape; cs.position = Vector2(0,0)
    add_child(cs)
    queue_redraw()

func _process(delta: float) -> void:
    _pulse += delta
    queue_redraw()

func interact() -> Dictionary:
    interacted.emit(self)
    return {"speaker":display_name, "text":"El poder no está en golpear primero. Aprende a dominar el KI y podrás despertar transformaciones."}

func _draw() -> void:
    _draw_ellipse(Vector2(0,34), Vector2(24,8), Color(0,0,0,0.25))
    draw_rect(Rect2(-16,-4,32,40), Color(0.42,0.56,0.72), true)
    draw_rect(Rect2(-12,8,24,5), Color(0.88,0.72,0.25), true)
    draw_circle(Vector2(0,-18),14,Color(0.84,0.58,0.40))
    var hair:=PackedVector2Array([Vector2(-14,-25),Vector2(-8,-38),Vector2(-2,-29),Vector2(5,-41),Vector2(10,-30),Vector2(16,-35),Vector2(12,-17),Vector2(-13,-16)])
    draw_colored_polygon(hair,Color(0.22,0.18,0.15))
    draw_circle(Vector2(0, -55), 9.0 + sin(_pulse*3.0)*2.0, Color(0.45,0.85,1.0,0.12))
    draw_arc(Vector2(0,-18), 30, -1.5, 1.5, 24, Color(0.55,0.85,1.0,0.35), 3.0)
    draw_string(ThemeDB.fallback_font, Vector2(-95,-60), display_name, HORIZONTAL_ALIGNMENT_CENTER, 190, 11, Color(1,0.92,0.64))

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points:=PackedVector2Array()
    for i in range(24):
        var a:=TAU*float(i)/24.0
        points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
    draw_colored_polygon(points,color)
