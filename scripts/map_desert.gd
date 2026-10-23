extends MapBase
class_name DesertMap

func _ready() -> void:
    zone_id = "desert"
    zone_title = "Desierto Carmesí"
    power_hint = 4
    zone_description = "Cañones secos y ruinas: bandidos y dinos carroñeros vigilan las rutas."
    world_size = Vector2(4300,900)
    mob_spawns = [
        {"kind":"desert_bandit", "position":Vector2(420,590)},
        {"kind":"dino_scavenger", "position":Vector2(740,590)},
        {"kind":"desert_bandit", "position":Vector2(1080,590)},
        {"kind":"dino_scavenger", "position":Vector2(1450,590)},
        {"kind":"desert_bandit", "position":Vector2(1830,590)},
        {"kind":"desert_bandit", "position":Vector2(2200,590)},
        {"kind":"dino_scavenger", "position":Vector2(2660,590)},
        {"kind":"desert_bandit", "position":Vector2(3140,590)},
        {"kind":"dino_scavenger", "position":Vector2(3650,590)},
        {"kind":"desert_bandit", "position":Vector2(4040,590)},
        {"kind":"dino_matriarch", "position":Vector2(3770,560)}
    ]
    npc_spawns = [Vector2(180,585)]
    orb_spawns = [Vector2(3380,420)]
    super._ready()
    _create_portal(Vector2(70,620),"valley",Vector2(3600,560),"← VALLE")
    _create_portal(Vector2(4200,620),"city",Vector2(3400,560),"CIUDAD →")
    _create_portal(Vector2(3950,620),"kame",Vector2(120,560),"COSTA KAME →")
    _create_portal(Vector2(4180,620),"red_ribbon",Vector2(3920,560),"BASE RED →")
    _create_portal(Vector2(4150,620),"red_ribbon",Vector2(4000,560),"BASE RED →")

func _build_world() -> void:
    super._build_world()
    _create_platform(Vector2(680,500),Vector2(260,24))
    _create_platform(Vector2(1420,440),Vector2(320,24))
    _create_platform(Vector2(2240,520),Vector2(260,24))
    _create_platform(Vector2(3000,455),Vector2(300,24))
    _create_platform(Vector2(3750,500),Vector2(250,24))

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,world_size),Color("#d98e59"))
    draw_circle(Vector2(760,150),82,Color(1.0,0.84,0.46,0.88))
    for i in range(10):
        var x:=float(i*480-120)
        var h:=250.0 + float((i%3)*55)
        draw_colored_polygon(PackedVector2Array([Vector2(x,620),Vector2(x+160,620-h),Vector2(x+350,620)]),Color(0.50,0.29,0.22,0.78))
        draw_colored_polygon(PackedVector2Array([Vector2(x+75,620),Vector2(x+160,620-h),Vector2(x+230,620)]),Color(0.70,0.40,0.25,0.60))
    draw_rect(Rect2(0,620,world_size.x,80),Color("#a85f39"))
    for x in range(160,4150,360):
        draw_line(Vector2(x,620),Vector2(x+25,560),Color("#543a2a"),10)
        draw_line(Vector2(x+25,560),Vector2(x+5,525),Color("#543a2a"),8)
        draw_line(Vector2(x+25,560),Vector2(x+55,520),Color("#543a2a"),8)
    draw_string(ThemeDB.fallback_font,Vector2(1700,200),"RUINAS DE LA TORRE ROJA",HORIZONTAL_ALIGNMENT_CENTER,900,23,Color(0.35,0.18,0.10,0.6))
