extends CharacterBody2D
class_name DBPlayer

signal hp_changed(value:int, maximum:int)
signal ki_changed(value:int, maximum:int)
signal power_changed(value:int)
signal coins_changed(value:int)
signal attack_fired(origin:Vector2, direction:int, damage:int)
signal skill_fired(skill_id:String, origin:Vector2, direction:int)
signal died
signal flight_changed(enabled:bool)
signal jumped

const GRAVITY := 1400.0
const JUMP_SPEED := -470.0
var hp:int
var ki:int
var facing:int = 1
var flight_enabled := false
var control_enabled := true
var selected_skill_id := "basic_punch"
var skill_cooldowns:Dictionary = {}
var _skill_lock := 0.0
var _hurt_timer := 0.0
var _defense_timer := 0.0
var _dead := false
var joystick:Node

func _ready()->void:
    add_to_group("player")
    hp = GameState.max_hp()
    ki = GameState.max_ki()
    GameState.hp = hp
    GameState.ki = ki
    queue_redraw()

func setup_mobile_input(value:Node)->void:
    joystick = value

func _physics_process(delta:float)->void:
    _skill_lock = maxf(0.0,_skill_lock-delta)
    _hurt_timer = maxf(0.0,_hurt_timer-delta)
    _defense_timer = maxf(0.0,_defense_timer-delta)
    for id in skill_cooldowns.keys():
        skill_cooldowns[id] = maxf(0.0,float(skill_cooldowns[id])-delta)
    var ix := Input.get_axis("move_left","move_right")
    var iy := Input.get_axis("move_up","move_down")
    if joystick and joystick.has_method("get_vector"):
        var v:Vector2 = joystick.get_vector()
        if absf(v.x)>absf(ix): ix=v.x
        if flight_enabled: iy=v.y
    if control_enabled and _skill_lock<=0.0:
        var speed_value := GameState.move_speed()+InventoryManager.equipment_bonus("speed")
        speed_value *= SkillManager.transformation_speed_multiplier(GameState.transformation)
        velocity.x = move_toward(velocity.x,ix*speed_value,1900.0*delta)
        if flight_enabled:
            velocity.y = move_toward(velocity.y,iy*speed_value*0.82,1900.0*delta)
        else:
            if not is_on_floor(): velocity.y += GRAVITY*delta
            if Input.is_action_just_pressed("jump") and is_on_floor():
                velocity.y=JUMP_SPEED
                jumped.emit()
        if absf(ix)>0.1: facing=1 if ix>0 else -1
    else:
        velocity.x=move_toward(velocity.x,0.0,1800.0*delta)
        if not flight_enabled and not is_on_floor(): velocity.y+=GRAVITY*delta
    move_and_slide()
    ki=mini(GameState.max_ki(),ki+int(round(GameState.ki_regen_rate()*delta)))
    GameState.ki=ki
    ki_changed.emit(ki,GameState.max_ki())
    queue_redraw()

func toggle_flight()->void:
    if not GameState.flight_unlocked: return
    flight_enabled=not flight_enabled
    GameState.flight_enabled=flight_enabled
    if flight_enabled: velocity.y=0
    flight_changed.emit(flight_enabled)
    GameState.changed.emit()

func select_skill(id:String)->bool:
    if not GameState.learned_skills.has(id): return false
    selected_skill_id=id
    return true

func execute_selected_or_basic()->bool:
    return use_skill(selected_skill_id)

func try_attack()->bool:
    return execute_selected_or_basic()

func use_skill(id:String)->bool:
    if _skill_lock>0.0 or not GameState.learned_skills.has(id): return false
    if float(skill_cooldowns.get(id,0.0))>0.0: return false
    var cost:=SkillManager.ki_cost(id)
    if ki<cost: return false
    if id in ["super_saiyan","kaioken","potential_unleashed","giant_namek","pure_majin","golden_frost"]:
        GameState.transformation=id
        GameState.changed.emit()
    else:
        skill_fired.emit(id,global_position+Vector2(24*facing,-20),facing)
        attack_fired.emit(global_position+Vector2(24*facing,-20),facing,SkillManager.damage(id))
    ki-=cost
    GameState.ki=ki
    skill_cooldowns[id]=SkillManager.cooldown(id)
    _skill_lock=0.08
    ki_changed.emit(ki,GameState.max_ki())
    return true

func get_skill_cooldown(id:String)->float:
    return float(skill_cooldowns.get(id,0.0))

func take_damage(amount:int)->void:
    var final_damage=maxi(1,amount)
    if _defense_timer>0.0: final_damage=1
    hp=maxi(0,hp-final_damage)
    GameState.hp=hp
    hp_changed.emit(hp,GameState.max_hp())
    _hurt_timer=0.18
    if hp<=0 and not _dead:
        _dead=true
        died.emit()
    queue_redraw()

func activate_barrier(duration:float,_rank:int=1)->void:
    _defense_timer=maxf(_defense_timer,duration)

func gain_power(amount:int)->void:
    GameState.power=maxi(10,GameState.power+amount)
    power_changed.emit(GameState.power)

func add_zeni(amount:int)->void:
    GameState.zeni=maxi(0,GameState.zeni+amount)
    coins_changed.emit(GameState.zeni)

func _draw()->void:
    var body:=Color("#5ca8ed") if GameState.race!="Namekiano" else Color("#49b77c")
    draw_circle(Vector2(0,23),15,Color(0,0,0,0.22))
    draw_rect(Rect2(-13,-3,26,34),body)
    draw_rect(Rect2(-10,14,20,5),Color("#e5b34d"))
    draw_circle(Vector2(0,-18),11,Color("#e6b18a"))
    draw_colored_polygon(PackedVector2Array([Vector2(-12,-22),Vector2(-9,-35),Vector2(-3,-28),Vector2(2,-40),Vector2(8,-28),Vector2(13,-32),Vector2(11,-15)]),Color("#28202a"))
    if _hurt_timer>0.0: draw_circle(Vector2(0,-10),35,Color(1,0.2,0.2,0.25))
