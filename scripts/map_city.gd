extends MapBase
class_name CityMap

func _ready() -> void:
    zone_id = "city"
    zone_title = "Ciudad Capsule"
    power_hint = 1
    zone_description = "Zona segura: tiendas, entrenamiento, compañeros y una nave preparada para viajar."
    world_size = Vector2(3600,900)
    enemy_spawns = []
    mob_spawns = []
    npc_spawns = [Vector2(430,585), Vector2(760,585), Vector2(1080,585), Vector2(1440,585), Vector2(1920,585), Vector2(2240,585)]
    orb_spawns = [Vector2(1250,560)]
    super._ready()
    _create_portal(Vector2(60,620),"valley",Vector2(3960,560),"← VALLE")
    _create_portal(Vector2(3250,620),"kame",Vector2(120,560),"COSTA KAME →")
    _create_portal(Vector2(3540,620),"desert",Vector2(120,560),"DESIERTO →")
    _create_portal(Vector2(2860,620),"red_ribbon",Vector2(120,560),"BASE RED →")

func _build_world() -> void:
    super._build_world()
    _create_platform(Vector2(680,500),Vector2(300,24))
    _create_platform(Vector2(1600,470),Vector2(380,24))
    _create_platform(Vector2(2550,520),Vector2(300,24))

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,world_size),Color("#88c8e8"))
    for i in range(10):
        var x:=float(i*430-90)
        draw_colored_polygon(PackedVector2Array([Vector2(x,620),Vector2(x+120,300),Vector2(x+250,620)]),Color(0.52,0.64,0.70,0.55))
    draw_rect(Rect2(0,620,world_size.x,80),Color("#6b9d55"))
    draw_rect(Rect2(970,250,1750,370),Color("#d4d6dd"))
    for x in range(1040,2700,260):
        draw_rect(Rect2(x,330,170,290),Color("#9bb6cc"))
        draw_rect(Rect2(x+22,360,45,70),Color("#4b7295"))
        draw_rect(Rect2(x+100,360,45,70),Color("#4b7295"))
        draw_circle(Vector2(x+84,285),40,Color("#f2ca58"))
    draw_circle(Vector2(1780,180),95,Color("#eef4fb"))
    draw_rect(Rect2(1685,165,190,30),Color("#58a7df"))
    draw_rect(Rect2(970,610,1750,18),Color("#8d8f96"))
    draw_string(ThemeDB.fallback_font,Vector2(1460,700),"CAPSULE CORP",HORIZONTAL_ALIGNMENT_CENTER,640,24,Color(0.18,0.30,0.45,0.85))
