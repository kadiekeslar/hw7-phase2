extends Node
## All connection code (LAN/direct IP now, room codes via noray later) lives
## here, so gameplay code never knows which path connected the players.

signal hosting_started
signal connected_to_host
signal connection_failed(reason: String)
signal host_left
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

const HOST_ID := 1
const CONNECT_TIMEOUT_SEC := 8.0

var _connect_timer: SceneTreeTimer


func _ready() -> void:
	multiplayer.peer_connected.connect(func(id: int) -> void: peer_joined.emit(id))
	multiplayer.peer_disconnected.connect(func(id: int) -> void: peer_left.emit(id))
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host_lan(port: int, max_players: int) -> Error:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, max_players - 1)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	hosting_started.emit()
	return OK


func join_lan(address: String, port: int) -> Error:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_connect_timer = get_tree().create_timer(CONNECT_TIMEOUT_SEC)
	_connect_timer.timeout.connect(_on_connect_timeout.bind(_connect_timer))
	return OK


func leave() -> void:
	_connect_timer = null
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func is_connected_to_game() -> bool:
	var peer := multiplayer.multiplayer_peer
	return not peer is OfflineMultiplayerPeer \
			and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func is_host() -> bool:
	return is_connected_to_game() and multiplayer.is_server()


## This machine's LAN IPv4 addresses, for the host to read out to other players.
func local_addresses() -> Array[String]:
	var result: Array[String] = []
	for address: String in IP.get_local_addresses():
		if address.count(".") == 3 and not address.begins_with("127.") and not address.begins_with("169.254."):
			result.append(address)
	return result


func kick(peer_id: int) -> void:
	if is_host():
		(multiplayer.multiplayer_peer as ENetMultiplayerPeer).disconnect_peer(peer_id)


func _on_connected_to_server() -> void:
	_connect_timer = null
	connected_to_host.emit()


func _on_connection_failed() -> void:
	_connect_timer = null
	leave()
	connection_failed.emit("Couldn't connect to the host.")


func _on_connect_timeout(timer: SceneTreeTimer) -> void:
	if timer != _connect_timer:
		return
	leave()
	connection_failed.emit("Couldn't reach the host. Check the IP and port.")


func _on_server_disconnected() -> void:
	leave()
	host_left.emit()
