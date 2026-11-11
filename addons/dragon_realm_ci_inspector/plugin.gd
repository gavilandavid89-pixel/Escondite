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
	print("[DRAGON_INSPECTOR] bridge_ready command_file=%s" % _command_file)

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
	if scene_path.is_empty():
		push_error("[DRAGON_INSPECTOR] %s missing scene path" % command_id)
		return
	EditorInterface.open_scene_from_path(scene_path)

	await get_tree().process_frame
	await get_tree().process_frame
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		push_error("[DRAGON_INSPECTOR] %s no_edited_scene_root scene=%s" % [command_id, scene_path])
		return
	if root.scene_file_path != scene_path:
		push_error("[DRAGON_INSPECTOR] %s wrong_scene expected=%s actual=%s" % [command_id, scene_path, root.scene_file_path])
		return

	var node_path := str(command.get("node_path", "."))
	var selected: Node = root if node_path == "." else root.get_node_or_null(NodePath(node_path))
	if selected == null:
		push_error("[DRAGON_INSPECTOR] %s node_not_found scene=%s node=%s" % [command_id, scene_path, node_path])
		return

	var selection := EditorInterface.get_selection()
	selection.clear()
	EditorInterface.edit_node(selected)
	await get_tree().process_frame
	if not selection.get_selected_nodes().has(selected):
		push_error("[DRAGON_INSPECTOR] %s selection_failed scene=%s node=%s" % [command_id, scene_path, node_path])
		return

	print("[DRAGON_INSPECTOR] VERIFIED id=%s scene=%s node=%s type=%s" % [command_id, scene_path, node_path, selected.get_class()])
