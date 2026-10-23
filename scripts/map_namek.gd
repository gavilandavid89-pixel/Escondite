extends MapBase
class_name NamekMap

func _ready() -> void:
    zone_id = "namek"
    zone_title = "Pantanos de Namek"
    power_hint = 10
    zone_description = "Zona alienígena inspirada en las áreas de Namek del APK: cristales, agua y guerreros hostiles."
    world_size = Vector2(4500,900)
    mob_spawns = [
        {"kind":"namek_raider", "position":Vector2(420,590)},
        {"kind":"frost_soldier", "position":Vector2(820,590)},
        {"kind":"namek_raider", "position":Vector2(1250,590)},
        {"kind":"saibaman_elite", "position":Vector2(1700,590)},
        {"kind":"namek_raider", "position":Vector2(2120,590)},
        {"kind":"frost_soldier", "position":Vector2(2580,590)},
        {"kind":"namek_raider", "position":Vector2(3050,590)},
        {"kind":"saibaman_elite", "position":Vector2(3500,590)},
        {"kind":"namek_guardian", "position":Vector2(3850,590)},
        {"kind":"namek_raider", "position":Vector2(4010,590)}
    ]
    npc_spawns = [Vector2(190,585)]
    orb_spawns = [Vector2(2980,420)]
    super._ready()
    _create_portal(Vector2(60,620),"ice",Vector2(4250,560),"← MONTAÑAS")
    _create_portal(Vector2(4400,620),"city",Vector2(3180,560),"NAVE →")
    _create_portal(Vector2(4150,620),"karin",Vector2(3450,240),"TORRE →")
    _create_portal(Vector2(4150,620),"karin",Vector2(3400,260),"TORRE →")

func _build_world() -> void:
    super._build_world()
    _create_platform(Vector2(720,500),Vector2(300,24))
    _create_platform(Vector2(1450,450),Vector2(300,24))
    _create_platform(Vector2(2230,530),Vector2(330,24))
    _create_platform(Vector2(3050,455),Vector2(320,24))
    _create_platform(Vector2(3750,510),Vector2(300,24))

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,world_size),Color("#69cfad"))
    draw_circle(Vector2(700,145),78,Color(0.76,1.0,0.88,0.82))
    draw_rect(Rect2(0,620,world_size.x,80),Color("#5db790"))
    for i in range(10):
        var x:=float(i*470-100)
        draw_colored_polygon(PackedVector2Array([Vector2(x,620),Vector2(x+150,300+float((i%3)*30)),Vector2(x+340,620)]),Color(0.20,0.42,0.35,0.55))
    for x in range(250,4300,360):
        draw_circle(Vector2(x,590),38,Color(0.49,0.83,0.76,0.60))
        draw_line(Vector2(x,590),Vector2(x,500),Color(0.35,0.68,0.60,0.80),8)
        draw_circle(Vector2(x,500),42,Color(0.56,0.91,0.78,0.58))
    for x in range(400,4200,520):
        draw_circle(Vector2(x,560),50,Color(0.18,0.58,0.55,0.48))
        draw_circle(Vector2(x,560),30,Color(0.70,0.98,0.88,0.25))
    draw_string(ThemeDB.fallback_font,Vector2(1650,200),"PANTANOS DE NAMEK",HORIZONTAL_ALIGNMENT_CENTER,1150,25,Color(0.08,0.32,0.29,0.62))
