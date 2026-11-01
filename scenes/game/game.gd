class_name Game
extends Node2D
## The game scene, on every peer. Builds the room and players and carries every
## game RPC. Host-only rules live in GameServer; all UI lives in Hud.
## Clients only send requests; the host checks each one before acting on it.

enum Choice { ACCEPT, DECLINE, CAPTURE }

var balance: GameBalance
var world: Node2D
var room: UcLounge
var hud: Hud
## Host only.
var server: GameServer
var players: Dictionary[int, Player] = {}
var local_player: Player
## Mirrored from the host's SemesterClock.
var clock_elapsed: float = 0.0
var clock_running: bool = false
var semester_over: bool = false


func _ready() -> void:
	balance = Session.balance
	room = UcLounge.new()
	room.name = "Room"
	add_child(room)
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	room.build(world, balance)

	var ids := Session.sorted_peer_ids()
	for i: int in ids.size():
		var id := ids[i]
		var player := Player.new()
		player.setup(id, Session.player_name(id), PlayerColors.get_color(Session.player_color(id)), balance)
		player.place_at(room.spawn_points[i % room.spawn_points.size()])
		world.add_child(player)
		players[id] = player
	local_player = players.get(multiplayer.get_unique_id())

	var camera := Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(UcLounge.SIZE.x)
	camera.limit_bottom = int(UcLounge.SIZE.y)
	if local_player:
		local_player.add_child(camera)
	else:
		add_child(camera)

	hud = Hud.new()
	hud.name = "Hud"
	add_child(hud)
	hud.setup(self)

	if multiplayer.is_server():
		server = GameServer.new()
		server.name = "Server"
		add_child(server)
		server.setup(self)
	else:
		_rq_ready.rpc_id(NetworkService.HOST_ID)


func player_name(peer_id: int) -> String:
	return Session.player_name(peer_id)


## Every station's task id and position.
func stations() -> Dictionary[StringName, Vector2]:
	return room.stations


# --- Client -> host requests -----------------------------------------------

func _sender() -> int:
	var id := multiplayer.get_remote_sender_id()
	return id if id != 0 else multiplayer.get_unique_id()


@rpc("any_peer", "reliable")
func _rq_ready() -> void:
	if server:
		server.on_peer_ready(_sender())


@rpc("any_peer", "call_local", "reliable")
func rq_collab(target: int) -> void:
	if server:
		server.request_collab(_sender(), target)


@rpc("any_peer", "call_local", "reliable")
func rq_respond(request_id: int, choice: Choice) -> void:
	if server:
		server.respond(_sender(), request_id, choice)


@rpc("any_peer", "call_local", "reliable")
func rq_task_action(session_id: int, action: Dictionary) -> void:
	if server:
		server.task_action(_sender(), session_id, action)


@rpc("any_peer", "call_local", "reliable")
func rq_task_cancel(session_id: int) -> void:
	if server:
		server.task_cancel(_sender(), session_id)


@rpc("any_peer", "call_local", "reliable")
func rq_file_report(target: int) -> void:
	if server:
		server.file_report(_sender(), target)


# --- Host -> client messages -----------------------------------------------

@rpc("authority", "call_local", "unreliable_ordered")
func cl_clock(elapsed: float, running: bool) -> void:
	clock_elapsed = elapsed
	clock_running = running


@rpc("authority", "call_local", "reliable")
func cl_semester_over() -> void:
	semester_over = true
	clock_running = false
	hud.show_semester_over()


@rpc("authority", "call_local", "reliable")
func cl_invite(request_id: int, from_peer: int, task_id: StringName, can_capture: bool, capture_ready: bool, timeout: float) -> void:
	hud.show_invite(request_id, from_peer, task_id, can_capture, capture_ready, timeout)


@rpc("authority", "call_local", "reliable")
func cl_waiting(target: int, task_id: StringName, timeout: float) -> void:
	hud.show_waiting(target, task_id, timeout)


@rpc("authority", "call_local", "reliable")
func cl_request_closed(message: String) -> void:
	hud.close_request(message)


@rpc("authority", "call_local", "reliable")
func cl_task_started(session_id: int, task_id: StringName, partner_names: Array, payload: Dictionary) -> void:
	hud.open_task(session_id, task_id, partner_names, payload)


@rpc("authority", "call_local", "reliable")
func cl_task_update(session_id: int, payload: Dictionary, feedback: Dictionary) -> void:
	hud.update_task(session_id, payload, feedback)


@rpc("authority", "call_local", "reliable")
func cl_task_finished(session_id: int, completed: bool, message: String) -> void:
	hud.finish_task(session_id, completed, message)


@rpc("authority", "call_local", "reliable")
func cl_player_failed(peer_id: int) -> void:
	if players.has(peer_id):
		players[peer_id].visible = false
	hud.show_failed(peer_id)


## TA only.
@rpc("authority", "call_local", "reliable")
func cl_report_available(ids: Array, expires_in: float) -> void:
	hud.show_report(ids, expires_in)


## TA only.
@rpc("authority", "call_local", "reliable")
func cl_report_closed(message: String) -> void:
	hud.close_report(message)


## TA only: in-game time when the report/capture cooldown ends.
@rpc("authority", "call_local", "reliable")
func cl_ta_cooldown(until_elapsed: float) -> void:
	hud.ta_cooldown_until = until_elapsed


@rpc("authority", "call_local", "reliable")
func cl_toast(text: String) -> void:
	hud.toast(text)
