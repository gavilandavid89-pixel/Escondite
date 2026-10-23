extends Control
class_name DialogueBox

signal closed
var panel: Panel
var speaker: Label
var body: Label
var next_button: Button
var lines: Array[String] = []
var index := 0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	panel = Panel.new()
	panel.position = Vector2(150, 470)
	panel.size = Vector2(980, 210)
	panel.add_theme_stylebox_override("panel", _style(Color(0.03,0.04,0.07,0.97),Color(0.30,0.64,0.95,0.9),16))
	add_child(panel)
	speaker = Label.new(); speaker.position=Vector2(24,18); speaker.size=Vector2(400,35); speaker.add_theme_font_size_override("font_size",22); speaker.add_theme_color_override("font_color",Color(1,0.84,0.35)); panel.add_child(speaker)
	body = Label.new(); body.position=Vector2(24,65); body.size=Vector2(700,105); body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_theme_font_size_override("font_size",18); body.add_theme_color_override("font_color",Color(0.90,0.94,1)); panel.add_child(body)
	next_button = Button.new(); next_button.text="CONTINUAR"; next_button.position=Vector2(760,120); next_button.size=Vector2(170,54); next_button.add_theme_font_size_override("font_size",17); panel.add_child(next_button); next_button.pressed.connect(_next)

func open_dialogue(name: String, texts: Array[String]) -> void:
	lines = texts; index = 0; visible = true; speaker.text=name; body.text=lines[0] if not lines.is_empty() else ""; next_button.grab_focus()

func _next() -> void:
	index += 1
	if index >= lines.size():
		visible = false; closed.emit(); return
	body.text=lines[index]

func _style(bg:Color,border:Color,r:int)->StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border; s.set_border_width_all(2); s.set_corner_radius_all(r); return s
