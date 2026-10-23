extends Control
class_name DBMinimap

var world: GameWorld

func setup(w: GameWorld) -> void:
	world = w
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,0.03,0.05,0.92),true)
	if world == null or world.current_map == null:
		return
	var ws: Vector2 = world.current_map.world_size
	var sx: float = size.x/ws.x
	var sy: float = size.y/ws.y
	# map lanes
	draw_rect(Rect2(0,size.y*0.70,size.x,size.y*0.30),Color(0.16,0.27,0.16,0.8),true)
	for enemy in world.enemies:
		if is_instance_valid(enemy):
			var ep:=Vector2(enemy.position.x*sx,enemy.position.y*sy)
			draw_circle(ep,3,Color("#ff4b59"))
	var pp:=Vector2(world.player.position.x*sx,world.player.position.y*sy)
	draw_circle(pp,4.5,Color("#55c8ff"))
	for npc in world.get_tree().get_nodes_in_group("zone_npcs"):
		if is_instance_valid(npc):
			draw_circle(Vector2(npc.position.x*sx,npc.position.y*sy),3,Color("#ffd35c"))
	# portals as cyan edge markers
	draw_circle(Vector2(4,size.y*0.7),4,Color("#6be5ff"))
	draw_circle(Vector2(size.x-4,size.y*0.7),4,Color("#6be5ff"))
