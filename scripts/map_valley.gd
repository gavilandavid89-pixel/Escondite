extends MapBase
class_name ValleyMap

func _ready() -> void:
    zone_id = "valley"
    zone_title = "Valle Azul"
    power_hint = 1
    zone_description = "Campamento de inicio; los lobos y los primeros Saibaman rondan las colinas."
    world_size = Vector2(4200,900)
    enemy_spawns = []
    mob_spawns = [
        {"kind":"wolf_raider", "position":Vector2(540,590)},
        {"kind":"wolf_raider", "position":Vector2(820,590)},
        {"kind":"saibaman", "position":Vector2(1120,590)},
        {"kind":"wolf_raider", "position":Vector2(1500,590)},
        {"kind":"saibaman", "position":Vector2(1800,590)},
        {"kind":"wolf_raider", "position":Vector2(2300,590)},
        {"kind":"saibaman", "position":Vector2(2800,590)},
        {"kind":"boar_brute", "position":Vector2(3080,590)},
        {"kind":"wolf_raider", "position":Vector2(3300,590)}
    ]
    npc_spawns = [Vector2(300,585)]
    orb_spawns = [Vector2(620,560)]
    super._ready()
    _create_portal(Vector2(4020,620),"city",Vector2(120,560),"CIUDAD →")
    _create_portal(Vector2(2020,620),"forest",Vector2(120,560),"BOSQUE →")
    _create_portal(Vector2(3700,620),"desert",Vector2(120,560),"DESIERTO →")

func _build_world() -> void:
    super._build_world()
    _create_platform(Vector2(740,580),Vector2(320,24))
    _create_platform(Vector2(1250,500),Vector2(250,24))
    _create_platform(Vector2(1850,590),Vector2(260,24))
    _create_platform(Vector2(2580,520),Vector2(300,24))
    _create_platform(Vector2(3300,450),Vector2(280,24))

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,world_size),Color("#6bc5e6"))
    for i in range(9):
        var x:=float(i*560-120)
        draw_colored_polygon(PackedVector2Array([Vector2(x,640),Vector2(x+180,330),Vector2(x+400,640)]),Color(0.31,0.48,0.58,0.70))
    draw_circle(Vector2(700,160),70,Color(1,0.86,0.42,0.75))
    draw_rect(Rect2(0,620,world_size.x,80),Color("#4f9b4f"))
    for p in [Vector2(560,650),Vector2(930,650),Vector2(1400,650),Vector2(2200,650),Vector2(3120,650),Vector2(3650,650)]:
        draw_circle(p,65,Color(0.44,0.34,0.24,0.75))
    for x in range(80,4100,240):
        var y:=580.0 + sin(x*0.017)*28.0
        draw_rect(Rect2(x-8,y-75,16,80),Color("#5b3c24"))
        draw_circle(Vector2(x,y-92),42,Color("#247343"))
        draw_circle(Vector2(x-24,y-80),28,Color("#2d8748"))
        draw_circle(Vector2(x+26,y-76),30,Color("#2a7d40"))
