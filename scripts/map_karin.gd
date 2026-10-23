extends MapBase
class_name KarinMap

func _ready() -> void:
    zone_id = "karin"
    zone_title = "Torre Sagrada"
    power_hint = 13
    zone_description = "Zona vertical de entrenamiento: guardianes, saques galácticos y pruebas del maestro."
    world_size = Vector2(3600,1200)
    mob_spawns = [
        {"kind":"namek_guardian", "position":Vector2(550,820)},
        {"kind":"galactic_raider", "position":Vector2(950,720)},
        {"kind":"namek_guardian", "position":Vector2(1350,600)},
        {"kind":"galactic_raider", "position":Vector2(1780,510)},
        {"kind":"galactic_raider", "position":Vector2(2200,420)},
        {"kind":"namek_guardian", "position":Vector2(2600,330)},
        {"kind":"ice_commander", "position":Vector2(3180,280)}
    ]
    npc_spawns = [Vector2(260,860)]
    orb_spawns = [Vector2(2880,240)]
    super._ready()
    _create_portal(Vector2(50,900),"ice",Vector2(4100,560),"← MONTAÑAS")
    _create_portal(Vector2(3540,340),"temple",Vector2(120,560),"TEMPLO →")

func _build_world() -> void:
    super._build_world()
    _create_platform(Vector2(520,760),Vector2(300,24))
    _create_platform(Vector2(1050,660),Vector2(280,24))
    _create_platform(Vector2(1580,560),Vector2(300,24))
    _create_platform(Vector2(2150,470),Vector2(300,24))
    _create_platform(Vector2(2750,380),Vector2(340,24))
    _create_platform(Vector2(3260,300),Vector2(300,24))

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,world_size),Color("#2d3550"))
    draw_circle(Vector2(620,170),84,Color(0.82,0.74,1.0,0.34))
    draw_colored_polygon(PackedVector2Array([Vector2(0,900),Vector2(1100,420),Vector2(2450,420),Vector2(3600,900)]),Color("#4c4969"))
    draw_rect(Rect2(1420,130,260,760),Color("#7f705e"))
    draw_rect(Rect2(1480,80,160,70),Color("#c4a26a"))
    draw_arc(Vector2(1555,95),75,PI,TAU,30,Color("#efd189"),12)
    for y in [760.0,660.0,560.0,470.0,380.0,300.0]:
        draw_circle(Vector2(450,y),35,Color(0.48,0.83,1.0,0.18))
    draw_string(ThemeDB.fallback_font,Vector2(1200,190),"TORRE SAGRADA",HORIZONTAL_ALIGNMENT_CENTER,1200,28,Color(0.83,0.82,1.0,0.68))
