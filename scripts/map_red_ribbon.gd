extends MapBase
class_name RedRibbonMap

func _ready() -> void:
    zone_id = "red_ribbon"
    zone_title = "Base del Ejército Red"
    power_hint = 7
    zone_description = "Fortaleza militar inspirada en las bases del APK: patrullas, torres y un comandante."
    world_size = Vector2(4200,900)
    mob_spawns = [
        {"kind":"rr_scout", "position":Vector2(520,590)},
        {"kind":"rr_scout", "position":Vector2(900,590)},
        {"kind":"rr_scout", "position":Vector2(1280,590)},
        {"kind":"rr_scout", "position":Vector2(1650,590)},
        {"kind":"rr_scout", "position":Vector2(2050,590)},
        {"kind":"rr_scout", "position":Vector2(2420,590)},
        {"kind":"rr_scout", "position":Vector2(2800,590)},
        {"kind":"rr_heavy", "position":Vector2(3180,590)},
        {"kind":"rr_commander", "position":Vector2(3550,570)}
    ]
    npc_spawns = [Vector2(260,585)]
    orb_spawns = [Vector2(3150,440)]
    super._ready()
    _create_portal(Vector2(60,620),"city",Vector2(3220,560),"← CIUDAD")
    _create_portal(Vector2(4140,620),"desert",Vector2(100,560),"DESIERTO →")
    _create_portal(Vector2(3970,620),"karin",Vector2(100,880),"TORRE →")
    _create_portal(Vector2(3970,620),"karin",Vector2(80,900),"TORRE →")

func _build_world() -> void:
    super._build_world()
    _create_platform(Vector2(720,520),Vector2(240,24))
    _create_platform(Vector2(1450,450),Vector2(260,24))
    _create_platform(Vector2(2230,510),Vector2(300,24))
    _create_platform(Vector2(2920,430),Vector2(280,24))

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,world_size),Color("#4b5363"))
    draw_circle(Vector2(720,150),74,Color(1.0,0.76,0.45,0.72))
    draw_rect(Rect2(0,620,4200,80),Color("#42444f"))
    draw_rect(Rect2(620,290,420,330),Color("#8b3034"))
    draw_rect(Rect2(720,235,220,80),Color("#4c2025"))
    draw_rect(Rect2(1850,340,500,280),Color("#6f2930"))
    draw_rect(Rect2(2700,280,650,340),Color("#58252c"))
    for x in range(160,4100,260):
        draw_line(Vector2(x,610),Vector2(x,540),Color("#333740"),8)
        draw_circle(Vector2(x,525),26,Color("#a2a9b8"))
    draw_string(ThemeDB.fallback_font,Vector2(1550,180),"BASE DEL EJÉRCITO RED",HORIZONTAL_ALIGNMENT_CENTER,1200,26,Color(1.0,0.82,0.72,0.65))
