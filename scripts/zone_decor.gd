extends Node2D

var zone_id := "valley"
var world_size := Vector2(4200,900)
var t := 0.0

func setup(zone: String, size: Vector2) -> void:
    zone_id = zone
    world_size = size
    z_index = 1
    queue_redraw()

func _process(delta: float) -> void:
    t += delta
    if int(t * 8.0) % 2 == 0:
        queue_redraw()

func _draw() -> void:
    var w := world_size.x
    # Distant silhouette layer gives every map depth before foreground details.
    var mountain_color := Color(0.05,0.10,0.16,0.30)
    if zone_id in ["namek"]:
        mountain_color = Color(0.08,0.20,0.16,0.28)
    elif zone_id in ["desert", "wasteland"]:
        mountain_color = Color(0.22,0.10,0.08,0.30)
    elif zone_id in ["ice", "temple", "karin"]:
        mountain_color = Color(0.30,0.46,0.60,0.28)
    elif zone_id in ["otherworld"]:
        mountain_color = Color(0.27,0.18,0.43,0.22)
    for i in range(9):
        var mx := fposmod(float(i * 520 + 120), w)
        var mh := 90.0 + float((i % 4) * 26)
        draw_colored_polygon(PackedVector2Array([Vector2(mx-190,620),Vector2(mx,620-mh),Vector2(mx+210,620)]), mountain_color)

    # Shared atmospheric layer: soft clouds, distant silhouettes and small
    # foreground details. Individual maps still provide their own identity.
    if zone_id in ["forest", "ice", "namek"]:
        for i in range(10):
            var x := fposmod(float(i * 510 + 180), w)
            var y := 150.0 + float((i % 3) * 46)
            draw_circle(Vector2(x,y), 34.0, Color(0.92,0.97,1.0,0.06))
            draw_circle(Vector2(x+30,y+6), 25.0, Color(0.92,0.97,1.0,0.05))
    else:
        for i in range(8):
            var x := fposmod(float(i * 590 + 90), w)
            var y := 135.0 + float((i % 2) * 58)
            draw_circle(Vector2(x,y), 28.0, Color(1,1,1,0.09))
            draw_circle(Vector2(x+26,y+4), 20.0, Color(1,1,1,0.07))

    # Flying silhouettes make the sky feel inhabited.
    for i in range(5):
        var fx := fposmod(float(i * 760 + 280) + sin(t * 0.20 + i) * 70.0, maxf(w, 1.0))
        var fy := 230.0 + float(i % 3) * 48.0
        draw_arc(Vector2(fx, fy), 10.0, PI + 0.2, TAU - 0.2, 8, Color(0.06,0.10,0.15,0.24), 2.0)
        draw_arc(Vector2(fx + 12, fy), 10.0, 0.2, PI - 0.2, 8, Color(0.06,0.10,0.15,0.24), 2.0)

    # Zone-specific accents.
    if zone_id == "city":
        for x in range(1120, 2700, 180):
            draw_circle(Vector2(x, 310), 5.0, Color(1.0,0.85,0.38,0.65))
            draw_line(Vector2(x,315),Vector2(x,610),Color(0.35,0.55,0.78,0.14),2.0)
    elif zone_id == "forest":
        for x in range(120, int(w)-120, 140):
            var sway := sin(t*1.8 + x*0.03) * 5.0
            draw_line(Vector2(x,620),Vector2(x+sway,586),Color(0.38,0.82,0.43,0.5),3.0)
            draw_line(Vector2(x,603),Vector2(x-4+sway,579),Color(0.28,0.72,0.36,0.45),2.0)
    elif zone_id == "desert":
        for x in range(90, int(w)-90, 260):
            draw_arc(Vector2(x,616), 18.0, PI, TAU, 14, Color(0.34,0.19,0.13,0.45), 4.0)
    elif zone_id == "kame":
        for x in range(100, int(w)-100, 260):
            draw_circle(Vector2(x, 684 + sin(x*0.025+t)*3.0), 3.0, Color(1.0,0.95,0.72,0.45))
    elif zone_id == "namek":
        for x in range(180, int(w)-180, 330):
            draw_circle(Vector2(x,470 + sin(x*0.03+t)*6.0), 5.0, Color(0.74,1.0,0.88,0.48))
    elif zone_id in ["ice", "temple", "karin", "otherworld"]:
        for x in range(120, int(w)-120, 240):
            draw_line(Vector2(x, 610),Vector2(x+12,545),Color(0.74,0.89,1.0,0.35),4.0)
            draw_circle(Vector2(x+16,540),7.0,Color(0.84,0.96,1.0,0.28))
    elif zone_id in ["red_ribbon", "plains", "arena", "wasteland"]:
        for x in range(160, int(w)-160, 310):
            draw_circle(Vector2(x,585), 18.0, Color(0.20,0.23,0.29,0.45))
            draw_line(Vector2(x-18,610),Vector2(x+18,595),Color(0.18,0.20,0.24,0.32),3.0)

    if zone_id == "city":
        for x in range(180, int(w)-160, 260):
            var h := 70.0 + float((x / 260 as int) % 3) * 28.0
            draw_rect(Rect2(x, 600-h, 110, h), Color(0.10,0.18,0.28,0.55))
            for yy in range(int(620-h), 590, 24):
                draw_rect(Rect2(x+14, yy, 9, 7), Color(0.94,0.76,0.28,0.30))
                draw_rect(Rect2(x+38, yy, 9, 7), Color(0.48,0.77,1.0,0.22))
    elif zone_id == "valley":
        for x in range(80, int(w)-80, 180):
            draw_line(Vector2(x,636),Vector2(x+5,614),Color(0.25,0.62,0.28,0.45),3.0)
            draw_line(Vector2(x+5,626),Vector2(x-3,617),Color(0.34,0.76,0.32,0.35),2.0)
    elif zone_id == "kame":
        for x in range(0, int(w), 180):
            draw_arc(Vector2(x,675),58.0,0.08,2.96,18,Color(0.35,0.78,0.92,0.24),2.0)
    elif zone_id == "plains":
        for x in range(300, int(w)-300, 420):
            draw_line(Vector2(x,610),Vector2(x,450),Color(0.76,0.86,0.96,0.22),5.0)
            draw_line(Vector2(x,450),Vector2(x+56,466),Color(1.0,0.52,0.32,0.20),5.0)
    elif zone_id == "arena":
        draw_arc(Vector2(2150,470),220.0,PI*1.02,PI*1.98,36,Color(0.93,0.86,0.45,0.25),7.0)
        for x in range(900, int(w)-900, 520):
            draw_line(Vector2(x,610),Vector2(x,330),Color(0.82,0.72,0.44,0.18),4.0)
    elif zone_id == "wasteland":
        for x in range(160, int(w)-160, 360):
            draw_rect(Rect2(x,535,48,88),Color(0.16,0.14,0.15,0.38))
            draw_line(Vector2(x+24,535),Vector2(x+42,514),Color(0.60,0.36,0.25,0.28),5.0)
    elif zone_id == "otherworld":
        for x in range(180, int(w)-180, 280):
            draw_circle(Vector2(x,380 + sin(x*0.02+t)*24.0), 5.0, Color(0.73,0.60,1.0,0.38))
            draw_circle(Vector2(x+18,395 + sin(x*0.014+t)*18.0), 3.0, Color(1.0,0.86,0.60,0.32))
