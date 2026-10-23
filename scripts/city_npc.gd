extends StaticBody2D
class_name CityNPC

var display_name := "Habitante"
var role := "citizen"
var dialogue_text := "La Ciudad Capsule siempre está llena de movimiento."
var tint := Color("#4e79a7")
var outfit := Color("#d6e2f0")
var pulse := 0.0

func setup(npc_name: String, npc_role: String, text: String, body_color: Color, cloth_color: Color) -> void:
    display_name=npc_name; role=npc_role; dialogue_text=text; tint=body_color; outfit=cloth_color

func _ready() -> void:
    z_index=10
    var cs:=CollisionShape2D.new(); var shape:=RectangleShape2D.new(); shape.size=Vector2(32,68); cs.shape=shape; add_child(cs)
    queue_redraw()

func _process(delta: float) -> void:
    pulse += delta
    queue_redraw()

func interact() -> Dictionary:
    var action := ""
    if role == "merchant": action="shop"
    if role == "trainer": action="train"
    return {"speaker":display_name,"text":dialogue_text,"action":action}

func _draw() -> void:
    _draw_ellipse_custom(Vector2(0,34),Vector2(22,7),Color(0,0,0,0.22))
    draw_rect(Rect2(-14,-4,28,38),outfit,true)
    draw_rect(Rect2(-13,7,26,6),tint.lightened(0.12),true)
    draw_rect(Rect2(-11,34,9,22),tint.darkened(0.2),true)
    draw_rect(Rect2(2,34,9,22),tint.darkened(0.2),true)
    draw_circle(Vector2(0,-18),13,tint)
    draw_rect(Rect2(-13,-31,26,8),tint.darkened(0.22),true)
    draw_circle(Vector2(-4,-18),2,Color("#17202b")); draw_circle(Vector2(4,-18),2,Color("#17202b"))
    draw_circle(Vector2(0,-54),7.0+sin(pulse*3.0)*1.4,Color(0.35,0.8,1,0.10))
    draw_string(ThemeDB.fallback_font,Vector2(-82,-58),display_name,HORIZONTAL_ALIGNMENT_CENTER,164,11,Color(1,0.92,0.65))

func _draw_ellipse_custom(center:Vector2,radii:Vector2,color:Color)->void:
    var points:=PackedVector2Array()
    for i in range(24):
        var a:=TAU*float(i)/24.0
        points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
    draw_colored_polygon(points,color)
