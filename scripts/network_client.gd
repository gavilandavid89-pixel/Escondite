extends Node

signal status_changed(text: String)
signal packet_received(data: Dictionary)

var peer: StreamPeerTCP
var buffer := ""
var player_id := ""
var connected := false
var host := "127.0.0.1"
var port := 4010
var identity := {"name":"Guerrero","power":10,"zone":"valley"}

func _process(_delta: float) -> void:
    if peer == null:
        return
    peer.poll()
    var status := peer.get_status()
    if status == StreamPeerTCP.STATUS_CONNECTED and not connected:
        connected = true
        send_packet({"type":"AUTH","name":identity.name,"power":identity.power,"zone":identity.zone})
        status_changed.emit("ONLINE • servidor conectado")
    if status == StreamPeerTCP.STATUS_ERROR or status == StreamPeerTCP.STATUS_NONE:
        if connected:
            connected = false
            status_changed.emit("DESCONECTADO • modo local")
    if connected:
        _read_packets()

func configure_identity(name_value:String, power_value:int, zone_value:String)->void:
    identity={"name":name_value,"power":max(10,power_value),"zone":zone_value}

func connect_to_server(new_host: String = "127.0.0.1", new_port: int = 4010) -> void:
    host = new_host
    port = new_port
    peer = StreamPeerTCP.new()
    var err := peer.connect_to_host(host, port)
    if err != OK:
        status_changed.emit("SIN CONEXIÓN • modo local")
        return
    status_changed.emit("Conectando...")

func disconnect_from_server() -> void:
    if peer:
        peer.disconnect_from_host()
    connected = false
    status_changed.emit("DESCONECTADO • modo local")

func send_packet(data: Dictionary) -> void:
    if not connected or peer == null:
        return
    peer.put_data((JSON.stringify(data) + "\n").to_utf8_buffer())

func _read_packets() -> void:
    while peer.get_available_bytes() > 0:
        var bytes: PackedByteArray = peer.get_data(peer.get_available_bytes())[1]
        buffer += bytes.get_string_from_utf8()
        while buffer.find("\n") >= 0:
            var idx := buffer.find("\n")
            var line := buffer.substr(0, idx)
            buffer = buffer.substr(idx + 1)
            var data = JSON.parse_string(line)
            if data is Dictionary:
                if str(data.get("type", "")) == "WELCOME":
                    player_id = str(data.get("id", ""))
                elif str(data.get("type", "")) == "AUTH_OK":
                    var state = get_node_or_null("/root/GameState")
                    if state:
                        state.current_zone = str(data.get("zone", state.current_zone))
                        state.position_x = float(data.get("x", state.position_x))
                        state.position_y = float(data.get("y", state.position_y))
                        state.zeni = int(data.get("zeni", state.zeni))
                        state.changed.emit()
                packet_received.emit(data)
