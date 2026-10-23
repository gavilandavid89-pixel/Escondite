extends MapBase
class_name IceMap

func _ready() -> void:
    zone_id = "ice"
    zone_title = "Montañas del Norte"
    power_hint = 8
    zone_description = "Paso helado inspirado en las zonas frías del APK: lobos de hielo y soldados glaciales."
    world_size = Vector2(4400,900)
    mob_spawns = [
        {"kind":"ice_wolf", "position":Vector2(430,590)},
        {"kind":"ice_wolf", "position":Vector2(820,590)},
        {"kind":"frost_soldier", "position":Vector2(1180,590)},
        {"kind":"ice_wolf", "position":Vector2(1550,590)},
        {"kind":"frost_soldier", "position":Vector2(1950,590)},
        {"kind":"ice_wolf", "position":Vector2(2310,590)},
        {"kind":"frost_soldier", "position":Vector2(2700,590)},
        {"kind":"ice_wolf", "position":Vector2(3140,590)},
        {"kind":"frost_soldier", "position":Vector2(3540,590)},
        {"kind":"ice_wolf", "position":Vector2(3970,590)},
        {"kind":"ice_commander", "position":Vector2(3750,550)}
    ]
    npc_spawns = [Vector2(180,585)]
    orb_spawns = [Vector2(3550,390)]
    super._ready()
    _create_portal(Vector2(60,620),"forest",Vector2(3650,560),"← BOSQUE")
    _create_portal(Vector2(4280,620),"namek",Vector2(120,560),"NAVE →")
    _create_portal(Vector2(4120,620),"temple",Vector2(3150,560),"TEMPLO ←")

func _build_world() -> void:
    super._build_world()
    _create_platform(Vector2(780,500),Vector2(300,24))
    _create_platform(Vector2(1500,430),Vector2(300,24))
    _create_platform(Vector2(2260,520),Vector2(340,24))
    _create_platform(Vector2(3000,455),Vector2(310,24))
    _create_platform(Vector2(3700,500),Vector2(300,24))

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,world_size),Color("#9dc8dd"))
    draw_circle(Vector2(720,150),72,Color(0.86,0.96,1.0,0.86))
    for i in range(9):
        var x:=float(i*520-120)
        draw_colored_polygon(PackedVector2Array([Vector2(x,620),Vector2(x+210,260+float((i%2)*50)),Vector2(x+430,620)]),Color(0.45,0.62,0.72,0.78))
        draw_colored_polygon(PackedVector2Array([Vector2(x+95,620),Vector2(x+210,260+float((i%2)*50)),Vector2(x+300,620)]),Color(0.82,0.94,0.98,0.72))
    draw_rect(Rect2(0,620,world_size.x,80),Color("#e6f4fb"))
    for x in range(120,4300,210):
        draw_circle(Vector2(x,580),24,Color(0.85,0.96,1,0.75))
        draw_line(Vector2(x,580),Vector2(x,535),Color(0.63,0.82,0.92,0.85),6)
    draw_string(ThemeDB.fallback_font,Vector2(1600,205),"ENTRADA A LA CUEVA GLACIAL",HORIZONTAL_ALIGNMENT_CENTER,1100,23,Color(0.22,0.40,0.53,0.62))
