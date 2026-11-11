@tool
extends EditorPlugin

var _poll_timer: Timer
var _command_dir := ""
var _last_command_id := ""
var _processing_command := false

func _enter_tree() -> void:
	_command_dir = OS.get_environment("DRAGON_EDITOR_COMMAND_DIR")
	_poll_timer = Timer.new()
	_poll_timer.wait_time = 0.35
	_poll_timer.timeout.connect(_poll_command)
	add_child(_poll_timer)
	_poll_timer.start()
	print("[DRAGON_INSPECTOR] bridge_ready command_dir=%s" % _command_dir)

func _exit_tree() -> void:
	if is_instance_valid(_poll_timer):
		_poll_timer.stop()
		_poll_timer.queue_free()

func _poll_command() -> void:
	if _processing_command or _command_dir.is_empty() or not DirAccess.dir_exists_absolute(_command_dir):
		return
	var files := DirAccess.get_files_at(_command_dir)
	files.sort()
	for filename in files:
		if not filename.ends_with(".json"):
			continue
		var command_path := _command_dir.path_join(filename)
		var raw := FileAccess.get_file_as_string(command_path)
		if raw.is_empty():
			continue
		var parser := JSON.new()
		if parser.parse(raw.strip_edges()) != OK:
			continue
		var parsed: Variant = parser.data
		if not (parsed is Dictionary):
			continue
		var command: Dictionary = parsed
		var command_id := str(command.get("id", ""))
		if command_id.is_empty() or command_id == _last_command_id:
			continue
		_last_command_id = command_id
		DirAccess.remove_absolute(command_path)
		_processing_command = true
		_process_command(command, command_id)
		return

func _process_command(command: Dictionary, command_id: String) -> void:

	var scene_path := str(command.get("scene", ""))
	print("[DRAGON_INSPECTOR] RECEIVED id=%s scene=%s node=%s" % [command_id, scene_path, str(command.get("node_path", "."))])
	if scene_path.is_empty():
		push_error("[DRAGON_INSPECTOR] %s missing scene path" % command_id)
		_processing_command = false
		return
	EditorInterface.open_scene_from_path(scene_path)

	await get_tree().process_frame
	await get_tree().process_frame
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		push_error("[DRAGON_INSPECTOR] %s no_edited_scene_root scene=%s" % [command_id, scene_path])
		_processing_command = false
		return
	if root.scene_file_path != scene_path:
		push_error("[DRAGON_INSPECTOR] %s wrong_scene expected=%s actual=%s" % [command_id, scene_path, root.scene_file_path])
		_processing_command = false
		return
	# Capture the actual scene workspace, not a stale Script editor tab.
	EditorInterface.set_main_screen_editor("2D")
	await get_tree().process_frame

	var node_path := str(command.get("node_path", "."))
	var selected: Node = root if node_path == "." else root.get_node_or_null(NodePath(node_path))
	if selected == null and node_path != ".":
		# Some editor scene roots expose instanced children differently through
		# get_node_or_null; search by leaf name, then verify the exact relative path.
		var candidate := root.find_child(node_path.get_file(), true, false)
		if candidate != null and str(root.get_path_to(candidate)) == node_path:
			selected = candidate
	if selected == null:
		push_error("[DRAGON_INSPECTOR] %s node_not_found scene=%s node=%s" % [command_id, scene_path, node_path])
		_processing_command = false
		return

	var selection := EditorInterface.get_selection()
	selection.clear()
	EditorInterface.edit_node(selected)
	await get_tree().process_frame
	if not selection.get_selected_nodes().has(selected):
		push_error("[DRAGON_INSPECTOR] %s selection_failed scene=%s node=%s" % [command_id, scene_path, node_path])
		_processing_command = false
		return

	print("[DRAGON_INSPECTOR] VERIFIED id=%s scene=%s node=%s type=%s" % [command_id, scene_path, node_path, selected.get_class()])
	_processing_command = false
