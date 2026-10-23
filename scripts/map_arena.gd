extends MapBase
class_name ArenaMap

func _ready() -> void:
    zone_id = "arena"
    zone_title = "Arena Celestial"
    power_hint = 10
    zone_description = "Zona avanzada de entrenamiento, historia y enemigos de élite."
    world_size = Vector2(4400, 980)
    mob_spawns = [
        {"kind":"galactic_raider", "position":Vector2(480,590)},
        {"kind":"rr_heavy", "position":Vector2(1120,590)},
        {"kind":"saibaman_elite", "position":Vector2(1780,590)},
        {"kind":"namek_raider", "position":Vector2(2520,590)},
        {"kind":"galactic_raider", "position":Vector2(3220,590)},
        {"kind":"arena_champion", "position":Vector2(3300,590)}
    ]
    npc_spawns = [Vector2(420,585), Vector2(1980,585), Vector2(3600,585)]
    super._ready()
    _create_portal(Vector2(55,620),"city",Vector2(3150,560),"← CIUDAD")
    _create_portal(Vector2(4280,620),"wasteland",Vector2(100,560),"AVANZAR →")

func _build_world() -> void:
    super._build_world()
    _create_platform(Vector2(640,500),Vector2(340,24))
    _create_platform(Vector2(1320,430),Vector2(280,24))
    _create_platform(Vector2(2050,520),Vector2(420,24))
    _create_platform(Vector2(2860,400),Vector2(360,24))
    _create_platform(Vector2(3660,520),Vector2(380,24))

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,world_size),Color("#7c8bb7"))
    draw_circle(Vector2(720,170),95,Color("#fff2b0"))
    for x in range(0,4400,320):
        var y:=560.0 + sin(float(x)*0.015)*50.0
        draw_colored_polygon(PackedVector2Array([Vector2(x,650),Vector2(x+80,y-120),Vector2(x+180,y-25),Vector2(x+300,650)]),Color("#56636f"))
    draw_rect(Rect2(0,620,world_size.x,80),Color("#727f52"))
    draw_string(ThemeDB.fallback_font,Vector2(1600,210),zone_title.to_upper(),HORIZONTAL_ALIGNMENT_CENTER,1200,30,Color(0.95,0.97,1,0.76))
