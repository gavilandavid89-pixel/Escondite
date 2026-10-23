extends Node2D
class_name GameWorld

const PLAYER_SCENE=preload("res://scenes/player/player.tscn")
const ENEMY_SCENE=preload("res://scenes/enemies/enemy.tscn")
const HUD_SCENE=preload("res://scenes/ui/hud.tscn")
const MASTER_SCENE=preload("res://scenes/npcs/master.tscn")
const CITY_NPC_SCENE=preload("res://scenes/npcs/city_npc.tscn")
const ORB_SCENE=preload("res://scenes/world/dragon_orb.tscn")
var player:DBPlayer
var current_map:MapBase
var current_zone := "valley"
var enemies:Array[DBEnemy]=[]
var hud
signal zone_changed(zone_id:String,title:String)

func _ready()->void:
    start_world(GameState.current_zone,Vector2(GameState.position_x,GameState.position_y))

func start_world(zone:String="valley",spawn:Vector2=Vector2(260,610))->void:
    player=PLAYER_SCENE.instantiate()
    player.position=spawn
    add_child(player)
    var camera:=Camera2D.new()
    camera.position=Vector2(0,-140)
    camera.position_smoothing_enabled=true
    camera.position_smoothing_speed=8.0
    player.add_child(camera)
    hud=HUD_SCENE.instantiate()
    add_child(hud)
    hud.setup(self,player)
    player.setup_mobile_input(hud.get_joystick())
    player.attack_fired.connect(_on_attack)
    player.skill_fired.connect(_on_skill)
    change_zone(zone,spawn)

func change_zone(zone:String,spawn:Vector2)->void:
    if current_map: current_map.queue_free()
    current_zone=zone
    var path:="res://scenes/world/valley.tscn"
    match zone:
        "forest":path="res://scenes/world/forest.tscn"
        "city":path="res://scenes/world/city.tscn"
        "desert":path="res://scenes/world/desert.tscn"
        "kame":path="res://scenes/world/kame.tscn"
        "ice":path="res://scenes/world/ice.tscn"
        "namek":path="res://scenes/world/namek.tscn"
        "temple":path="res://scenes/world/temple.tscn"
        "red_ribbon":path="res://scenes/world/red_ribbon.tscn"
        "karin":path="res://scenes/world/karin.tscn"
        "plains":path="res://scenes/world/map_plains.tscn"
        "arena":path="res://scenes/world/map_arena.tscn"
        "wasteland":path="res://scenes/world/map_wasteland.tscn"
        "otherworld":path="res://scenes/world/map_otherworld.tscn"
    var packed:=load(path) as PackedScene
    if packed:
        current_map=packed.instantiate()
        add_child(current_map)
        move_child(current_map,0)
        if current_map.has_signal("travel_requested") and not current_map.travel_requested.is_connected(change_zone):
            current_map.travel_requested.connect(change_zone)
        current_zone=current_map.zone_id
    player.position=spawn
    GameState.current_zone=current_zone
    GameState.position_x=spawn.x
    GameState.position_y=spawn.y
    _spawn_contents()
    zone_changed.emit(current_zone,current_map.zone_title if current_map else current_zone)
    if hud: hud.on_zone_changed(current_zone,current_map.zone_title if current_map else current_zone)
    SaveManager.save_game()

func _spawn_contents()->void:
    enemies.clear()
    if current_map==null:return
    for entry in current_map.get_mob_spawns():
        var enemy:DBEnemy=ENEMY_SCENE.instantiate()
        enemy.position=entry.position
        add_child(enemy)
        enemy.setup(player,str(entry.kind),1)
        enemy.defeated.connect(_on_enemy_defeated)
        enemies.append(enemy)
    for pos in current_map.get_npc_spawns():
        var npc=MASTER_SCENE.instantiate()
        npc.position=pos
        add_child(npc)
    for pos in current_map.get_orb_spawns():
        var orb=ORB_SCENE.instantiate()
        orb.position=pos
        add_child(orb)

func _on_attack(origin:Vector2,direction:int,damage:int)->void:
    var closest:DBEnemy
    var distance:=150.0
    for enemy in enemies:
        if not is_instance_valid(enemy):continue
        var dx:=enemy.global_position.x-origin.x
        if signf(dx)==float(direction) and absf(dx)<distance:
            closest=enemy; distance=absf(dx)
    if closest: closest.take_damage(damage)

func _on_skill(id:String,origin:Vector2,direction:int)->void:
    _on_attack(origin,direction,SkillManager.damage(id))

func _on_enemy_defeated(enemy:DBEnemy)->void:
    player.add_zeni(enemy.reward_zeni)
    player.gain_power(maxi(1,int(enemy.mob_power/10)))
    hud.show_message("%s derrotado • +%d zeni" % [enemy.display_name,enemy.reward_zeni])

func interact()->void:
    if hud: hud.open_dialogue({"speaker":"Maestro","text":"Entrena, mejora tus habilidades y explora nuevas zonas."})
