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

	# Reload even when the requested scene is already the active tab. The
	# previous CI trace showed the editor and PackedScene cache both exposing
	# only the root although the checked-in .tscn declares child nodes.
	EditorInterface.reload_scene_from_path(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	root = EditorInterface.get_edited_scene_root()
	if root == null or root.scene_file_path != scene_path:
		push_error("[DRAGON_INSPECTOR] %s scene_reload_failed expected=%s" % [command_id, scene_path])
		_processing_command = false
		return

	# Record the exact scene declarations read from disk in this CI process.
	# This separates a checkout/file problem from an editor resource-cache issue.
	var scene_source := FileAccess.get_file_as_string(scene_path)
	var declared_node_count := scene_source.count("[node name=")
	print("[DRAGON_INSPECTOR] SOURCE_FILE id=%s scene=%s bytes=%d declared_nodes=%d content=%s" % [
		command_id, scene_path, scene_source.length(), declared_node_count, JSON.stringify(scene_source)
	])

	# Independently instantiate the serialized PackedScene and compare its
	# hierarchy against the live Scene dock root before trusting node lookup.
	var packed := ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		push_error("[DRAGON_INSPECTOR] %s packed_scene_load_failed scene=%s" % [command_id, scene_path])
		_processing_command = false
		return
	var packed_state := packed.get_state()
	var serialized_nodes: Array[Dictionary] = []
	for state_index in range(packed_state.get_node_count()):
		serialized_nodes.append({
			"path": str(packed_state.get_node_path(state_index)),
			"type": str(packed_state.get_node_type(state_index))
		})
	print("[DRAGON_INSPECTOR] PACKED_STATE id=%s scene=%s node_count=%d nodes=%s" % [
		command_id, scene_path, packed_state.get_node_count(), JSON.stringify(serialized_nodes)
	])

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

	# Expand and select the real item in the editor's Scene dock. This is
	# deliberately a UI-level verification: the screenshot must show the
	# requested node in the hierarchy, not merely a programmatic Node lookup.
	var scene_dock_item := _find_scene_dock_item(selected)
	if scene_dock_item.is_empty():
		push_error("[DRAGON_INSPECTOR] %s scene_dock_item_not_found scene=%s node=%s" % [command_id, scene_path, node_path])
		_processing_command = false
		return
	var scene_tree: Tree = scene_dock_item["tree"]
	var scene_item: TreeItem = scene_dock_item["item"]
	var ancestor: TreeItem = scene_item
	while ancestor != null:
		ancestor.collapsed = false
		ancestor = ancestor.get_parent()
	scene_tree.set_selected(scene_item, 0)
	scene_tree.ensure_cursor_is_visible()
	scene_tree.queue_redraw()
	await get_tree().process_frame
	if scene_tree.get_selected() != scene_item:
		push_error("[DRAGON_INSPECTOR] %s scene_dock_selection_failed scene=%s node=%s" % [command_id, scene_path, node_path])
		_processing_command = false
		return

	print("[DRAGON_INSPECTOR] SCENE_DOCK_SELECTED id=%s scene=%s node=%s type=%s" % [command_id, scene_path, node_path, selected.get_class()])
	print("[DRAGON_INSPECTOR] VERIFIED id=%s scene=%s node=%s type=%s" % [command_id, scene_path, node_path, selected.get_class()])
	_processing_command = false

func _find_scene_dock_item(target: Node) -> Dictionary:
	var base := EditorInterface.get_base_control()
	if base == null:
		return {}
	var trees := base.find_children("*", "Tree", true, false)
	for candidate in trees:
		if not (candidate is Tree):
			continue
		var tree := candidate as Tree
		var root_item := tree.get_root()
		if root_item == null:
			continue
		var edited_root := EditorInterface.get_edited_scene_root()
		var target_path := str(edited_root.get_path_to(target)) if edited_root != null else ""
		var match_item := _find_tree_item_for_node(root_item, target, target_path, ".")
		if match_item != null:
			return {"tree": tree, "item": match_item}
	return {}

func _find_tree_item_for_node(item: TreeItem, target: Node, target_path: String, current_path: String) -> TreeItem:
	var metadata: Variant = item.get_metadata(0)
	if metadata is Node and metadata == target:
		return item
	if current_path == "." and target_path == "." and item.get_text(0) == str(target.name):
		return item
	var child := item.get_first_child()
	while child != null:
		var child_name := child.get_text(0)
		var child_path := child_name if current_path == "." else current_path + "/" + child_name
		if child_path == target_path and child_name == str(target.name):
			return child
		var match_item := _find_tree_item_for_node(child, target, target_path, child_path)
		if match_item != null:
			return match_item
		child = child.get_next()
	return null
