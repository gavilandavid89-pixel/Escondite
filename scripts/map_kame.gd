extends MapBase
class_name KameMap

func _ready() -> void:
    zone_id = "kame"
    zone_title = "Costa Kame"
    power_hint = 6
    zone_description = "Playas tranquilas, cuevas y piratas de poca monta; perfecta para entrenar control del KI."
    world_size = Vector2(4000,900)
    mob_spawns = [
        {"kind":"pirate_raider", "position":Vector2(460,590)},
        {"kind":"pirate_raider", "position":Vector2(850,590)},
        {"kind":"dino_scavenger", "position":Vector2(1210,590)},
        {"kind":"pirate_raider", "position":Vector2(1580,590)},
        {"kind":"pirate_raider", "position":Vector2(2020,590)},
        {"kind":"dino_scavenger", "position":Vector2(2380,590)},
        {"kind":"pirate_raider", "position":Vector2(2760,590)},
        {"kind":"pirate_raider", "position":Vector2(3240,590)},
        {"kind":"pirate_raider", "position":Vector2(3620,590)}
    ]
    npc_spawns = [Vector2(230,585)]
    orb_spawns = [Vector2(2900,500)]
    super._ready()
    _create_portal(Vector2(55,620),"city",Vector2(3150,560),"← CIUDAD")
    _create_portal(Vector2(3850,620),"desert",Vector2(3880,560),"DESIERTO ←")
    _create_portal(Vector2(3650,620),"red_ribbon",Vector2(80,560),"BASE RED →")

func _build_world() -> void:
    super._build_world()
    _create_platform(Vector2(700,500),Vector2(260,24))
    _create_platform(Vector2(1420,460),Vector2(300,24))
    _create_platform(Vector2(2200,520),Vector2(280,24))
    _create_platform(Vector2(2960,450),Vector2(320,24))
    _create_platform(Vector2(3560,500),Vector2(240,24))

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,world_size),Color("#7bc8df"))
    draw_circle(Vector2(650,150),76,Color(1.0,0.90,0.58,0.85))
    draw_rect(Rect2(0,610,world_size.x,90),Color("#dfc46c"))
    draw_rect(Rect2(0,670,world_size.x,230),Color("#2e9ac6"))
    for x in range(0,4000,110):
        var wave_y:=665.0 + sin(x*0.06)*9.0
        draw_line(Vector2(x,wave_y),Vector2(x+55,wave_y-4),Color(0.78,0.95,1.0,0.55),3)
    draw_circle(Vector2(620,545),130,Color(0.94,0.88,0.66,0.82))
    draw_rect(Rect2(530,500,180,120),Color("#f5f0df"))
    draw_circle(Vector2(1060,560),130,Color(0.18,0.56,0.42,0.18))
    for x in range(160,3900,280):
        draw_line(Vector2(x,610),Vector2(x+25,555),Color("#6d5936"),7)
        draw_circle(Vector2(x+15,548),28,Color("#36a36f"))
