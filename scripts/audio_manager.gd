extends Node

var sfx: Dictionary = {}
var music_player: AudioStreamPlayer
var bus_muted := false

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "Music"
	add_child(music_player)
	var music_path := "res://assets/music/world_theme.wav"
	if ResourceLoader.exists(music_path):
		music_player.stream = load(music_path)
		music_player.volume_db = -18.0
		music_player.play()
		if music_player.stream is AudioStreamWAV:
			music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	for id in ["ui", "punch", "ki", "kame", "transform"]:
		var path := "res://assets/sfx/%s.wav" % id
		if ResourceLoader.exists(path):
			sfx[id] = load(path)

func play(id: String, volume_db: float = -6.0) -> void:
	if bus_muted or not sfx.has(id):
		return
	var p := AudioStreamPlayer.new()
	p.stream = sfx[id]
	p.volume_db = volume_db
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func toggle_mute() -> void:
	bus_muted = not bus_muted
	if bus_muted:
		music_player.stop()
	else:
		if music_player.stream:
			music_player.play()

