extends Node2D
class_name DBRemotePlayer

var display_name := "Guerrero"
var power := 10
var body_color := Color("#66c0ff")

func setup(name_value:String, power_value:int)->void:
    display_name = name_value
    power = max(10, power_value)
    body_color = Color.from_hsv(float(abs(display_name.hash())%360)/360.0,0.55,0.9)
    queue_redraw()

func _draw()->void:
    draw_circle(Vector2(0,20),14,Color(0,0,0,0.25))
    draw_rect(Rect2(-11,-6,22,25),body_color,true)
    draw_circle(Vector2(0,-19),10,Color(0.9,0.67,0.50))
    var hair:=PackedVector2Array([Vector2(-12,-24),Vector2(-6,-35),Vector2(-1,-27),Vector2(5,-37),Vector2(12,-29),Vector2(9,-18),Vector2(-10,-17)])
    draw_colored_polygon(hair,Color(0.08,0.06,0.08))
    draw_string(ThemeDB.fallback_font,Vector2(-65,-47),"%s • PWR %d"%[display_name,power],HORIZONTAL_ALIGNMENT_CENTER,130,11,Color(0.80,0.92,1.0))
