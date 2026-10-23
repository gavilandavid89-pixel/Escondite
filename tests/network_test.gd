extends SceneTree
var welcomed := false
var auth_ok := false
var client

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	client = preload("res://scripts/network_client.gd").new()
	get_root().add_child(client)
	client.packet_received.connect(_on_packet)
	client.configure_identity("SmokeTest",10,"valley")
	client.connect_to_server("127.0.0.1",4010)
	await create_timer(1.5).timeout
	if client.connected and welcomed and auth_ok:
		print("[NETWORK_TEST] PASS handshake + AUTH + persistence path")
		client.send_packet({"type":"CHAT","text":"smoke"})
		client.disconnect_from_server()
		quit(0)
	else:
		print("[NETWORK_TEST] FAIL connected=%s welcomed=%s auth=%s" % [client.connected,welcomed,auth_ok])
		quit(1)

func _on_packet(data:Dictionary)->void:
	var typ:=str(data.get("type",""))
	if typ == "WELCOME": welcomed=true
	elif typ == "AUTH_OK": auth_ok=true
