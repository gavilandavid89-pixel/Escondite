extends MapBase
class_name TempleMap

func _ready() -> void:
    zone_id = "temple"
    zone_title = "Templo del KI"
    power_hint = 12
    zone_description = "Prueba avanzada: Saibaman Élite, ejecutores y el Guardián del Templo."
    world_size = Vector2(3400,900)
    mob_spawns = [
        {"kind":"saibaman_elite", "position":Vector2(650,590)},
        {"kind":"frost_soldier", "position":Vector2(1050,590)},
        {"kind":"saibaman_elite", "position":Vector2(1500,590)},
        {"kind":"frost_soldier", "position":Vector2(1950,590)},
        {"kind":"saibaman_elite", "position":Vector2(2400,590)}
    ]
    npc_spawns = [Vector2(250,585)]
    orb_spawns = []
    super._ready()
    _create_portal(Vector2(60,620),"forest",Vector2(3980,560),"← BOSQUE")
    _create_portal(Vector2(3300,620),"ice",Vector2(4120,560),"MONTAÑAS →")
    _create_portal(Vector2(3150,620),"karin",Vector2(3450,320),"TORRE →")
    _create_portal(Vector2(3150,620),"karin",Vector2(3500,330),"TORRE →")

func _build_world() -> void:
    super._build_world()
    _create_platform(Vector2(720,520),Vector2(260,24))
    _create_platform(Vector2(1200,430),Vector2(260,24))
    _create_platform(Vector2(1800,520),Vector2(300,24))
    _create_platform(Vector2(2450,450),Vector2(300,24))

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,world_size),Color("#3a3150"))
    draw_circle(Vector2(640,150),82,Color(0.75,0.68,1.0,0.32))
    draw_rect(Rect2(1200,260,1000,360),Color("#5b516c"))
    draw_colored_polygon(PackedVector2Array([Vector2(1050,260),Vector2(1700,80),Vector2(2350,260)]),Color("#75698e"))
    for x in range(1200,2200,120):
        draw_rect(Rect2(x,390,55,230),Color("#3e344e"))
    draw_rect(Rect2(0,620,world_size.x,80),Color("#665c68"))
    for x in range(100,3300,260):
        draw_circle(Vector2(x,570),45,Color(0.38,0.31,0.46,0.65))
    for x in range(1320,2140,160):
        draw_arc(Vector2(x,330),26,0,TAU,20,Color(0.38,0.82,1.0,0.32),3)
