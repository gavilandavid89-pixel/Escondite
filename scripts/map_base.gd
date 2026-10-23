extends Node2D
class_name MapBase

signal travel_requested(target_zone: String, spawn: Vector2)

var zone_id := "valley"
var zone_title := "Valle Azul"
var power_hint := 1
var zone_description := "Zona inicial."
var world_size := Vector2(4200, 900)
var enemy_spawns: Array[Vector2] = []
var mob_spawns: Array[Dictionary] = []
var npc_spawns: Array[Vector2] = []
var portal_defs: Array[Dictionary] = []
var orb_spawns: Array[Vector2] = []

func _ready() -> void:
    _build_world()
    var decor_script := load("res://scripts/zone_decor.gd")
    var decor: Node2D = decor_script.new()
    decor.name = "ZoneDecor"
    decor.setup(zone_id, world_size)
    add_child(decor)
    queue_redraw()

func _build_world() -> void:
    _create_platform(Vector2(world_size.x*0.5, 700), Vector2(world_size.x, 80))

func _create_platform(center: Vector2, size: Vector2) -> void:
    var body := StaticBody2D.new()
    body.collision_layer = 1
    body.collision_mask = 2 | 4
    body.position = center
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new(); shape.size = size; cs.shape = shape
    body.add_child(cs)
    add_child(body)

func _create_portal(pos: Vector2, target: String, spawn: Vector2, text: String) -> void:
    var portal_script := load("res://scripts/map_portal.gd")
    var portal: Area2D = portal_script.new()
    portal.position = pos
    portal.setup(target, spawn, text)
    portal.entered.connect(_on_portal_entered)
    add_child(portal)

func _on_portal_entered(target: String, spawn_x: float, spawn_y: float) -> void:
    travel_requested.emit(target, Vector2(spawn_x, spawn_y))

func get_enemy_spawns() -> Array[Vector2]:
    return enemy_spawns.duplicate()

func get_mob_spawns() -> Array[Dictionary]:
    return mob_spawns.duplicate()

func get_npc_spawns() -> Array[Vector2]:
    return npc_spawns.duplicate()

func get_orb_spawns() -> Array[Vector2]:
    return orb_spawns.duplicate()

func has_boss() -> bool:
    return false
