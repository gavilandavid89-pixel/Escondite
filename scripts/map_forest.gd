extends MapBase
class_name ForestMap

func _ready() -> void:
    zone_id = "forest"
    zone_title = "Bosque Oscuro"
    power_hint = 3
    zone_description = "Bosque nocturno con Saibaman, lobos y una ruta oculta hacia las montañas."
    world_size = Vector2(4200,900)
    enemy_spawns = []
    mob_spawns = [
        {"kind":"saibaman", "position":Vector2(520,590)},
        {"kind":"wolf_raider", "position":Vector2(900,590)},
        {"kind":"saibaman", "position":Vector2(1250,590)},
        {"kind":"saibaman", "position":Vector2(1650,590)},
        {"kind":"wolf_raider", "position":Vector2(2050,590)},
        {"kind":"saibaman_elite", "position":Vector2(2450,590)},
        {"kind":"saibaman", "position":Vector2(2860,590)},
        {"kind":"wolf_raider", "position":Vector2(3260,590)},
        {"kind":"saibaman_elite", "position":Vector2(3660,590)},
        {"kind":"boar_brute", "position":Vector2(3420,590)}
    ]
    npc_spawns = [Vector2(210,585)]
    orb_spawns = [Vector2(1180,430)]
    super._ready()
    _create_portal(Vector2(60,620),"valley",Vector2(3900,560),"← VALLE")
    _create_portal(Vector2(3720,620),"ice",Vector2(120,560),"MONTAÑAS →")
    _create_portal(Vector2(4040,620),"temple",Vector2(150,560),"TEMPLO →")

func _build_world() -> void:
    super._build_world()
    _create_platform(Vector2(900,520),Vector2(220,24))
    _create_platform(Vector2(1500,470),Vector2(240,24))
    _create_platform(Vector2(2300,540),Vector2(250,24))
    _create_platform(Vector2(3050,480),Vector2(310,24))
    _create_platform(Vector2(3650,420),Vector2(250,24))

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,world_size),Color("#1c2940"))
    draw_circle(Vector2(680,150),75,Color(0.85,0.92,1.0,0.78))
    for i in range(12):
        var x:=float(i*380-60)
        draw_colored_polygon(PackedVector2Array([Vector2(x,620),Vector2(x+140,260+float((i%3)*35)),Vector2(x+280,620)]),Color(0.09,0.16,0.14,0.90))
    draw_rect(Rect2(0,620,world_size.x,80),Color("#233e2b"))
    for x in range(60,4160,180):
        var y:=585.0 + sin(x*0.021)*35
        draw_rect(Rect2(x-6,y-105,12,105),Color("#3b2b24"))
        draw_circle(Vector2(x,y-125),48,Color("#183f2a"))
        draw_circle(Vector2(x-25,y-112),34,Color("#205334"))
    for i in range(25):
        var p:=Vector2(80+i*163,350+sin(i*2.3)*120)
        draw_circle(p,3.5,Color(0.35,0.85,0.58,0.35))
