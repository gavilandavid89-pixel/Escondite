extends SceneTree

func _initialize() -> void:
	var output_path := OS.get_environment("INSPECTION_OUTPUT")
	if output_path.is_empty():
		push_error("INSPECTION_OUTPUT is required")
		quit(2)
		return

	# Cross-check the scene parser in a fresh headless process before the
	# graphical editor test. This isolates editor state from resource parsing.
	var enemy_source := FileAccess.get_file_as_string("res://scenes/enemies/enemy.tscn")
	var enemy_scene := ResourceLoader.load("res://scenes/enemies/enemy.tscn", "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if enemy_scene == null:
		print("[INSPECT_SCENE_PROBE] load_failed source_bytes=%d" % enemy_source.length())
	else:
		var enemy_state := enemy_scene.get_state()
		var enemy_instance := enemy_scene.instantiate()
		print("[INSPECT_SCENE_PROBE] source_bytes=%d source_node_declarations=%d packed_state_nodes=%d instantiated_children=%d child_names=%s" % [
			enemy_source.length(),
			enemy_source.count("[node name="),
			enemy_state.get_node_count(),
			enemy_instance.get_child_count(),
			JSON.stringify(enemy_instance.get_children().map(func(child): return str(child.name)))
		])
		enemy_instance.free()

	var rows: Array[Dictionary] = []
	for property in ProjectSettings.get_property_list():
		var setting_name := String(property.get("name", ""))
		if setting_name.is_empty():
			continue
		var value: Variant = ProjectSettings.get_setting(setting_name, null)
		rows.append({
			"name": setting_name,
			"type": int(property.get("type", TYPE_NIL)),
			"usage": int(property.get("usage", 0)),
			"value": var_to_str(value),
		})

	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write project settings dump: " + output_path)
		quit(3)
		return
	file.store_string(JSON.stringify(rows, "\t"))
	file.close()
	print("[INSPECT] Exported %d ProjectSettings properties to %s" % [rows.size(), output_path])
	quit(0)
