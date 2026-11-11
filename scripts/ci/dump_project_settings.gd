extends SceneTree

func _initialize() -> void:
	var output_path := OS.get_environment("INSPECTION_OUTPUT")
	if output_path.is_empty():
		push_error("INSPECTION_OUTPUT is required")
		quit(2)
		return

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
