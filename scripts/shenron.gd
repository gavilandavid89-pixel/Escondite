extends StaticBody2D
class_name ShenronNPC

var _time:=0.0

func _ready()->void:
	z_index=11
	var cs:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new(); shape.size=Vector2(44,90); cs.shape=shape
	add_child(cs)
	queue_redraw()

func _process(delta:float)->void:
	_time += delta
	queue_redraw()

func interact()->Dictionary:
	if QuestManager.quests["dragon_orbs"].completed:
		return {"speaker":"Shenron", "text":"Has reunido las siete esferas. Tu voluntad y tu entrenamiento han abierto un nuevo camino.", "action":"wish"}
	return {"speaker":"Shenron", "text":"Aún puedo sentir que faltan esferas. Regresa cuando hayas reunido las siete.", "action":"none"}

func _draw()->void:
	var pulse:=1.0+sin(_time*2.0)*0.06
	for i in range(5):
		var col:=Color(0.20,0.95,0.55,0.10-float(i)*0.012)
		draw_arc(Vector2(0,-12),58.0+i*7.0,0.15,PI*1.85,40,col,4.0)
	_draw_ellipse_custom(Vector2(0,38),Vector2(24,7),Color(0,0,0,0.20))
	draw_circle(Vector2(0,-22),18*pulse,Color("#4adf65"))
	draw_circle(Vector2(0,-22),13*pulse,Color("#b5ffd0"))
	draw_colored_polygon(PackedVector2Array([Vector2(-17,-20),Vector2(-28,-35),Vector2(-10,-31),Vector2(0,-48),Vector2(10,-31),Vector2(28,-35),Vector2(17,-20),Vector2(10,-8),Vector2(-10,-8)]),Color("#43b95a"))
	draw_circle(Vector2(-7,-23),3,Color("#ffe46b")); draw_circle(Vector2(7,-23),3,Color("#ffe46b"))
	draw_string(ThemeDB.fallback_font,Vector2(-55,-70),"SHENRON",HORIZONTAL_ALIGNMENT_CENTER,110,13,Color(0.75,1,0.80))

func _draw_ellipse_custom(center:Vector2,radii:Vector2,color:Color)->void:
	var points:=PackedVector2Array()
	for i in range(24):
		var a:=TAU*float(i)/24.0
		points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(points,color)
