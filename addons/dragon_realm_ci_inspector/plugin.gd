@tool
extends EditorPlugin

var _poll_timer: Timer
var _command_file := ""
var _last_command_id := ""

func _enter_tree() -> void:
	_command_file = OS.get_environment("DRAGON_EDITOR_COMMAND_FILE")
	_poll_timer = Timer.new()
	_poll_timer.wait_time = 0.35
	_poll_timer.timeout.connect(_poll_command)
	add_child(_poll_timer)
	_poll_timer.start()
	print("[DRAGON_INSPECTOR] Editor inspection bridge ready")

func _exit_tree() -> void:
	if is_instance_valid(_poll_timer):
		_poll_timer.stop()
		_poll_timer.queue_free()

func _poll_command() -> void:
	if _command_file.is_empty() or not FileAccess.file_exists(_command_file):
		return
	var raw := FileAccess.get_file_as_string(_command_file)
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return
	var command: Dictionary = parsed
	var command_id := str(command.get("id", ""))
	if command_id.is_empty() or command_id == _last_command_id:
		return
	_last_command_id = command_id
	var scene_path := str(command.get("scene", ""))
	if not scene_path.is_empty():
		var error := EditorInterface.open_scene_from_path(scene_path)
		if error != OK:
			push_error("[DRAGON_INSPECTOR] Could not open %s: %s" % [scene_path, error_string(error)])
			return
		await get_tree().process_frame
		await get_tree().process_frame
	var node_path := str(command.get("node_path", ""))
	var root := EditorInterface.get_edited_scene_root()
	if root != null:
		EditorInterface.get_selection().clear()
		if not node_path.is_empty():
			var selected := root.get_node_or_null(NodePath(node_path))
			if selected != null:
				EditorInterface.get_selection().add_node(selected)
			else:
				push_warning("[DRAGON_INSPECTOR] Node not found: %s in %s" % [node_path, scene_path])
	print("[DRAGON_INSPECTOR] READY id=%s scene=%s node=%s" % [command_id, scene_path, node_path])
