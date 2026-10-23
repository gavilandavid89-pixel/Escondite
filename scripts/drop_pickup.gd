extends Node2D
class_name DropPickup

var item_id := "iron"
var amount := 1
var life := 25.0
var _time := 0.0

func setup(id: String, qty: int) -> void:
    item_id = id
    amount = qty
    queue_redraw()

func _process(delta: float) -> void:
    _time += delta
    life -= delta
    queue_redraw()
    if life <= 0.0:
        queue_free()

func _draw() -> void:
    var bob := sin(_time * 4.0) * 3.0
    var tint := Color("#7bcf7a")
    if item_id == "ice_shard": tint = Color("#8ee9ff")
    elif item_id == "namek_crystal": tint = Color("#68ffb0")
    elif item_id == "zenicoin" or item_id == "pirate_coin": tint = Color("#ffd85e")
    elif item_id == "bandit_cloth": tint = Color("#c48370")
    elif item_id == "dino_hide": tint = Color("#d79a5a")
    elif item_id == "galactic_badge": tint = Color("#b8a3ff")
    elif item_id == "rr_insignia": tint = Color("#ff5f68")
    elif item_id == "karin_talisman": tint = Color("#b8a56a")
    draw_circle(Vector2(0,8+bob),14,Color(0,0,0,0.20))
    draw_circle(Vector2(0,bob),9,tint)
    draw_circle(Vector2(-3,bob-3),2.4,Color.WHITE)
    draw_arc(Vector2(0,bob),12,0,TAU,18,Color(tint.r,tint.g,tint.b,0.45),2)
    if amount > 1:
        draw_string(ThemeDB.fallback_font,Vector2(12,bob+5),"x%d" % amount,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(1,0.92,0.60))
