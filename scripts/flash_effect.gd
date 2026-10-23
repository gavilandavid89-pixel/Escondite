extends Node2D
var radius:=220.0
var life:=0.5
var max_life:=0.5
func setup(r:float,d:float)->void: radius=r; life=d; max_life=d; queue_redraw()
func _process(delta:float)->void:
	life-=delta; queue_redraw(); if life<=0: queue_free()
func _draw()->void:
	var p:=1.0-life/max_life
	var r:=radius*p
	draw_circle(Vector2.ZERO,r,Color(1,0.94,0.58,0.09*(1-p)))
	draw_arc(Vector2.ZERO,r,0,TAU,64,Color(1,0.94,0.58,0.85*(1-p)),8)
