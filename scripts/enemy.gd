extends CharacterBody2D
class_name DBEnemy

signal defeated(enemy:DBEnemy)
signal player_hit(amount:int)
var enemy_id := "wolf_raider"
var display_name := "Lobo Salvaje"
var max_hp := 85
var hp := 85
var move_speed := 100.0
var damage := 12
var armor_rating := 12
var target:DBPlayer
var attack_timer := 0.0
var stun_timer := 0.0
var blind_timer := 0.0
var mob_power := 18
var mob_type := "melee"
var is_boss := false
var mob_color := Color("#b8a58f")
var mob_accent := Color("#6f5847")
var loot:Array=[]
var reward_zeni := 8
var spawn_position := Vector2.ZERO
var floor_y := 622.0
var _dead := false

func _ready()->void:
    add_to_group("enemies")
    z_index=12

func setup(p:DBPlayer,kind:String="wolf_raider",difficulty:int=1)->void:
    target=p
    enemy_id=kind
    var data:Dictionary=MobCatalog.lookup(kind)
    if data.is_empty(): data=MobCatalog.lookup("wolf_raider")
    display_name=str(data.get("name",kind))
    mob_power=int(data.get("power",18))+maxi(0,difficulty-1)*12
    var profile:Dictionary=MobCatalog.derived_stats(kind,data)
    max_hp=int(profile.get("hp",85))
    hp=max_hp
    move_speed=float(profile.get("speed",100.0))
    damage=int(profile.get("attack",12))
    armor_rating=int(profile.get("armor_rating",12))
    mob_type=str(data.get("type","melee"))
    is_boss=bool(data.get("boss",false))
    mob_color=data.get("color",Color("#b8a58f"))
    mob_accent=data.get("accent",Color("#6f5847"))
    loot=data.get("loot",[])
    reward_zeni=int(data.get("zeni",8))
    spawn_position=global_position
    queue_redraw()

func _physics_process(delta:float)->void:
    attack_timer=maxf(0.0,attack_timer-delta)
    stun_timer=maxf(0.0,stun_timer-delta)
    blind_timer=maxf(0.0,blind_timer-delta)
    if target==null or target.hp<=0 or stun_timer>0.0 or blind_timer>0.0:
        velocity.x=move_toward(velocity.x,0.0,900*delta)
    else:
        var dx:=target.global_position.x-global_position.x
        if absf(dx)>55.0: velocity.x=signf(dx)*move_speed
        else:
            velocity.x=0
            if attack_timer<=0.0:
                target.take_damage(damage)
                player_hit.emit(damage)
                attack_timer=1.15
        if not is_on_floor(): velocity.y+=1400.0*delta
    move_and_slide()
    if global_position.y>floor_y: global_position.y=floor_y; velocity.y=0
    queue_redraw()

func apply_blind(duration:float)->void:
    blind_timer=maxf(blind_timer,duration)
    velocity=Vector2.ZERO

func is_blinded()->bool:
    return blind_timer>0.0

func apply_stun(duration:float)->void:
    stun_timer=maxf(stun_timer,duration)
    velocity=Vector2.ZERO

func take_damage(amount:int)->void:
    if _dead:return
    hp=maxi(0,hp-maxi(1,amount))
    if hp<=0:
        _dead=true
        defeated.emit(self)
        queue_free()
    queue_redraw()

func _draw()->void:
    draw_circle(Vector2(0,18),18,Color(0,0,0,0.22))
    draw_rect(Rect2(-17,-15,34,33),mob_color)
    draw_circle(Vector2(0,-22),14,mob_color)
    draw_colored_polygon(PackedVector2Array([Vector2(-14,-27),Vector2(-8,-40),Vector2(-2,-29),Vector2(6,-40),Vector2(13,-27)]),mob_accent)
    draw_rect(Rect2(-24,-50,48,5),Color(0.12,0.12,0.15))
    draw_rect(Rect2(-24,-50,48.0*float(hp)/maxf(1.0,float(max_hp)),5),Color("#e84a56"))
