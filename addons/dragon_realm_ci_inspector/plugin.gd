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

func _scene_tree_signature(node: Node, prefix: String = ".") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for child in node.get_children():
		var child_path := child.name if prefix == "." else prefix + "/" + str(child.name)
		result.append({"path": child_path, "type": child.get_class()})
		result.append_array(_scene_tree_signature(child, child_path))
	return result

func _process_command(command: Dictionary, command_id: String) -> void:
	var scene_path := str(command.get("scene", ""))
	var node_path := str(command.get("node_path", "."))
	print("[DRAGON_INSPECTOR] RECEIVED id=%s scene=%s node=%s" % [command_id, scene_path, node_path])
	if scene_path.is_empty():
		push_error("[DRAGON_INSPECTOR] %s missing scene path" % command_id)
		_processing_command = false
		return

	# Do not reopen the already active scene: open_scene_from_path can be a
	# no-op for the current tab, and matching scene_file_path alone is not a
	# reliable signal that a newly requested load has completed.
	var root := EditorInterface.get_edited_scene_root()
	if root == null or root.scene_file_path != scene_path:
		EditorInterface.open_scene_from_path(scene_path)
		root = null
		for frame in range(120):
			await get_tree().process_frame
			root = EditorInterface.get_edited_scene_root()
			if root != null and root.scene_file_path == scene_path:
				break
	if root == null or root.scene_file_path != scene_path:
		push_error("[DRAGON_INSPECTOR] %s scene_open_timeout expected=%s actual=%s" % [command_id, scene_path, str(root.scene_file_path if root != null else "<null>")])
		_processing_command = false
		return

	# Independently instantiate the serialized PackedScene and compare its
	# hierarchy against the live Scene dock root before trusting node lookup.
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("[DRAGON_INSPECTOR] %s packed_scene_load_failed scene=%s" % [command_id, scene_path])
		_processing_command = false
		return
	var reference_root := packed.instantiate()
	if reference_root == null:
		push_error("[DRAGON_INSPECTOR] %s packed_scene_instantiate_failed scene=%s" % [command_id, scene_path])
		_processing_command = false
		return
	var expected_tree := _scene_tree_signature(reference_root)
	var live_tree := _scene_tree_signature(root)
	var expected_root_type := reference_root.get_class()
	var live_root_type := root.get_class()
	var expected_root_name := str(reference_root.name)
	var live_root_name := str(root.name)
	reference_root.free()
	if expected_root_type != live_root_type or expected_root_name != live_root_name or expected_tree != live_tree:
		print("[DRAGON_INSPECTOR] TREE_MISMATCH id=%s scene=%s expected_root=%s:%s live_root=%s:%s expected_children=%s live_children=%s" % [
			command_id, scene_path, expected_root_name, expected_root_type,
			live_root_name, live_root_type, JSON.stringify(expected_tree), JSON.stringify(live_tree)
		])
		push_error("[DRAGON_INSPECTOR] %s live_scene_tree_differs_from_packed_scene scene=%s" % [command_id, scene_path])
		_processing_command = false
		return
	print("[DRAGON_INSPECTOR] TREE_MATCH id=%s scene=%s descendants=%d" % [command_id, scene_path, expected_tree.size()])

	EditorInterface.set_main_screen_editor("2D")
	await get_tree().process_frame

	var selected: Node
	if node_path == ".":
		selected = root
	else:
		var requested_path := NodePath(node_path)
		selected = root.get_node_or_null(requested_path)
		if selected == null:
			push_error("[DRAGON_INSPECTOR] %s node_not_found_in_verified_tree scene=%s node=%s" % [command_id, scene_path, node_path])
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
