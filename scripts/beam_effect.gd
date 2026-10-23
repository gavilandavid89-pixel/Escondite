extends Node2D
var dir:=Vector2.RIGHT
var beam_length:=300.0
var beam_width:=20.0
var life:=0.5
var max_life:=0.5
var tint:=Color("#63c9ff")
func setup(d:Vector2,l:float,w:float,duration:float,c:Color)->void:
	dir=d.normalized(); beam_length=l; beam_width=w; life=duration; max_life=duration; tint=c; queue_redraw()
func _process(delta:float)->void:
	life-=delta; queue_redraw(); if life<=0: queue_free()
func _draw()->void:
	var a:=clampf(life/max_life,0,1)
	var side:=dir.orthogonal()*beam_width
	var end:=dir*beam_length
	draw_polygon(PackedVector2Array([side,-side,end-side*0.7,end+side*0.7]),PackedColorArray([Color(tint.r,tint.g,tint.b,0.2*a),Color(tint.r,tint.g,tint.b,0.2*a),Color(tint.r,tint.g,tint.b,0.2*a),Color(tint.r,tint.g,tint.b,0.2*a)]))
	draw_line(Vector2.ZERO,end,Color(tint.r,tint.g,tint.b,0.9*a),beam_width*2.2)
	draw_line(Vector2.ZERO,end,Color(1,1,1,0.95*a),beam_width*0.65)
