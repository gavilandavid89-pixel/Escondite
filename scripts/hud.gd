extends CanvasLayer

const JOYSTICK_SCRIPT = preload("res://scripts/virtual_joystick.gd")
var world:GameWorld
var player:DBPlayer
var joystick:Node
var info_label:Label
var hp_bar:ProgressBar
var ki_bar:ProgressBar
var zone_label:Label
var message_label:Label
var interact_button:Button
var menu_panel:Panel
var menu_content:VBoxContainer
var open_panel_name := ""

func setup(w:GameWorld,p:DBPlayer)->void:
    world=w
    player=p
    _build()
    GameState.changed.connect(refresh)
    QuestManager.quest_updated.connect(refresh)
    InventoryManager.changed.connect(refresh)
    SkillManager.changed.connect(refresh)
    refresh()

func _build()->void:
    var root:=Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)
    var top:=Panel.new()
    top.position=Vector2(14,14); top.size=Vector2(370,110)
    root.add_child(top)
    info_label=_label(top,"GUERRERO",Vector2(12,6),Vector2(280,25),18)
    hp_bar=ProgressBar.new(); hp_bar.position=Vector2(12,37); hp_bar.size=Vector2(280,18); top.add_child(hp_bar)
    ki_bar=ProgressBar.new(); ki_bar.position=Vector2(12,61); ki_bar.size=Vector2(280,16); top.add_child(ki_bar)
    zone_label=_label(top,"VALLE AZUL",Vector2(12,84),Vector2(340,20),12)
    message_label=_label(root,"",Vector2(400,20),Vector2(560,38),16)
    var attack:=Button.new(); attack.text="ATACAR"; attack.position=Vector2(1040,650); attack.size=Vector2(140,58); root.add_child(attack)
    attack.pressed.connect(func(): player.try_attack())
    var fly:=Button.new(); fly.text="VOLAR"; fly.position=Vector2(1040,580); fly.size=Vector2(140,54); root.add_child(fly)
    fly.pressed.connect(func():
        player.toggle_flight()
        fly.text="BAJAR" if player.flight_enabled else "VOLAR"
    )
    var interact:=Button.new(); interact.text="INTERACTUAR"; interact.position=Vector2(880,650); interact.size=Vector2(150,58); root.add_child(interact)
    interact_button=interact
    interact.pressed.connect(func(): world.interact())
    var menu:=Button.new(); menu.text="MENÚ"; menu.position=Vector2(14,136); menu.size=Vector2(110,42); root.add_child(menu)
    menu.pressed.connect(func(): open_named_menu("personaje"))
    joystick=JOYSTICK_SCRIPT.new()
    joystick.position=Vector2(28,480)
    root.add_child(joystick)
    menu_panel=Panel.new(); menu_panel.position=Vector2(370,140); menu_panel.size=Vector2(410,390); menu_panel.visible=false; root.add_child(menu_panel)
    menu_content=VBoxContainer.new(); menu_content.position=Vector2(14,14); menu_content.size=Vector2(380,360); menu_panel.add_child(menu_content)

func _label(parent:Node,text_value:String,pos:Vector2,dimensions:Vector2,font_size:int)->Label:
    var result:=Label.new()
    result.text=text_value; result.position=pos; result.size=dimensions
    result.add_theme_font_size_override("font_size",font_size)
    parent.add_child(result)
    return result

func get_joystick()->Node:
    return joystick

func refresh()->void:
    if player==null:return
    info_label.text="%s  •  PODER %d  •  ZENI %d" % [GameState.player_name,GameState.power,GameState.zeni]
    hp_bar.max_value=GameState.max_hp(); hp_bar.value=player.hp
    ki_bar.max_value=GameState.max_ki(); ki_bar.value=player.ki
    zone_label.text=world.current_zone.to_upper()

func on_zone_changed(zone_id:String,title:String)->void:
    zone_label.text=title.to_upper()
    show_message("Zona: "+title)

func show_message(value:String)->void:
    if message_label: message_label.text=value

func set_combat_message(value:String)->void:
    show_message(value)

func set_interact_visible(value:bool)->void:
    if interact_button: interact_button.visible=value

func show_chat(value:String)->void:
    show_message(value)

func open_dialogue(data:Dictionary)->void:
    show_message(str(data.get("speaker","NPC"))+": "+str(data.get("text","")))

func open_named_menu(name_value:String)->void:
    open_panel_name=name_value
    menu_panel.visible=true
    for child in menu_content.get_children(): child.queue_free()
    var title:=Label.new(); title.text=name_value.to_upper(); menu_content.add_child(title)
    var close:=Button.new(); close.text="Cerrar"; close.pressed.connect(func(): menu_panel.visible=false); menu_content.add_child(close)
    var stats:=Label.new(); stats.text="HP %d/%d    KI %d/%d\nPoder %d    Potencial %d\nRaza: %s" % [player.hp,GameState.max_hp(),player.ki,GameState.max_ki(),GameState.power,GameState.potential_points,GameState.race]; menu_content.add_child(stats)
    for id in GameState.learned_skills:
        var skill_button:=Button.new()
        skill_button.text=str(id)
        skill_button.pressed.connect(func(): player.select_skill(str(id)); show_message("Habilidad seleccionada: "+str(id)); menu_panel.visible=false)
        menu_content.add_child(skill_button)
