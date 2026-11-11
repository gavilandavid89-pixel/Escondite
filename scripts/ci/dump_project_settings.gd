extends SceneTree

func _initialize() -> void:
	var output_path := OS.get_environment("INSPECTION_OUTPUT")
	if output_path.is_empty():
		push_error("INSPECTION_OUTPUT is required")
		quit(2)
		return

	# Cross-check multiple collision scenes in a fresh headless process.
	# This separates a scene-specific parse problem from editor state/cache issues.
	for probe_path in ["res://scenes/enemies/enemy.tscn", "res://scenes/player/player.tscn"]:
		var probe_source := FileAccess.get_file_as_string(probe_path)
		for cache_mode in [ResourceLoader.CACHE_MODE_IGNORE, ResourceLoader.CACHE_MODE_REPLACE]:
			var probe_scene := ResourceLoader.load(probe_path, "PackedScene", cache_mode) as PackedScene
			if probe_scene == null:
				print("[INSPECT_SCENE_PROBE] path=%s mode=%d load_failed source_bytes=%d declarations=%d" % [
					probe_path, cache_mode, probe_source.length(), probe_source.count("[node name=")
				])
			else:
				var probe_state := probe_scene.get_state()
				var probe_instance := probe_scene.instantiate()
				print("[INSPECT_SCENE_PROBE] path=%s mode=%d source_bytes=%d declarations=%d packed_nodes=%d children=%d child_names=%s" % [
					probe_path, cache_mode, probe_source.length(), probe_source.count("[node name="),
					probe_state.get_node_count(), probe_instance.get_child_count(),
					JSON.stringify(probe_instance.get_children().map(func(child): return str(child.name)))
				])
				probe_instance.free()

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
