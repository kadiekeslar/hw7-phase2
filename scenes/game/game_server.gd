class_name GameServer
extends Node
## Host only. Owns all game state: the clock, who is TA, collaboration
## requests, task sessions, line of sight, reports and captures.
## Every client request is checked here before anything happens.

## Extra distance allowed on top of the interact radius, for network lag.
const DISTANCE_SLACK_PX := 12.0
const READY_TIMEOUT_SEC := 10.0
const LOS_CHECK_INTERVAL_SEC := 0.1
const CLOCK_BROADCAST_INTERVAL_SEC := 0.5

var game: Game
var balance: GameBalance
var clock: SemesterClock
var tracker: ReportTracker
var ta_peer: int = 0
var started: bool = false
var over: bool = false

var _rng := RandomNumberGenerator.new()
var _alive: Dictionary[int, bool] = {}
var _connected: Dictionary[int, bool] = {}
var _ready: Dictionary[int, bool] = {}
## request_id -> {"from", "to", "task_id", "expires_ms"}
var _requests: Dictionary[int, Dictionary] = {}
## session_id -> {"task_id", "seats": Array[int], "logic": TaskLogic}
var _sessions: Dictionary[int, Dictionary] = {}
## peer -> request id or session id they're tied up in.
var _in_request: Dictionary[int, int] = {}
var _in_session: Dictionary[int, int] = {}
var _next_id: int = 1
var _wait_elapsed: float = 0.0
var _los_accum: float = 0.0
var _clock_accum: float = 0.0


func setup(p_game: Game) -> void:
	game = p_game
	balance = game.balance
	_rng.randomize()
	clock = SemesterClock.new(balance.week_length_sec, balance.semester_weeks)
	tracker = ReportTracker.new(clock.weeks_to_sec(balance.report_expiry_weeks),
			clock.weeks_to_sec(balance.report_cooldown_weeks))
	ta_peer = Session.ta_peer
	for id: int in game.players:
		_alive[id] = true
		_connected[id] = id == NetworkService.HOST_ID or id in multiplayer.get_peers()
	Session.player_left_game.connect(_on_player_left)
	on_peer_ready(NetworkService.HOST_ID)


func now_real() -> float:
	return Time.get_ticks_msec() / 1000.0


func _process(delta: float) -> void:
	if not started:
		_wait_elapsed += delta
		if _wait_elapsed >= READY_TIMEOUT_SEC:
			_start()
		return
	if over:
		return
	clock.advance(delta)
	_clock_accum += delta
	if _clock_accum >= CLOCK_BROADCAST_INTERVAL_SEC:
		_clock_accum = 0.0
		game.cl_clock.rpc(clock.elapsed_sec, true)
	if tracker.expire_if_due(clock.elapsed_sec):
		_to(ta_peer, game.cl_report_closed, ["Your report expired."])
	_expire_requests()
	_los_accum += delta
	if _los_accum >= LOS_CHECK_INTERVAL_SEC:
		_los_accum = 0.0
		_check_line_of_sight()
	if clock.is_over():
		_end_semester()


## Sends a host -> client RPC to one peer, or runs it here if that peer is the host.
func _to(peer: int, method: Callable, args: Array) -> void:
	if peer == 0 or not _connected.get(peer, false):
		return
	if peer == multiplayer.get_unique_id():
		method.callv(args)
	else:
		method.get_object().callv(&"rpc_id", [peer, method.get_method()] + args)


# --- Start, end, disconnects -----------------------------------------------

func on_peer_ready(peer: int) -> void:
	if not game.players.has(peer):
		return
	_ready[peer] = true
	if peer != NetworkService.HOST_ID:
		for player: Player in game.players.values():
			player.show_to_peer(peer)
	if started:
		_send_state_to(peer)
		return
	for id: int in game.players:
		if _connected[id] and not _ready.get(id, false):
			return
	_start()


func _start() -> void:
	if started:
		return
	started = true
	DevTools.log_line("game started, TA is %s" % game.player_name(ta_peer))
	game.cl_clock.rpc(clock.elapsed_sec, true)
	_to(ta_peer, game.cl_ta_cooldown, [tracker.cooldown_until_sec])


func _send_state_to(peer: int) -> void:
	game.cl_clock.rpc_id(peer, clock.elapsed_sec, not over)
	for id: int in _alive:
		if not _alive[id]:
			game.cl_player_failed.rpc_id(peer, id)


func _end_semester() -> void:
	over = true
	for id: int in game.players:
		game.players[id].frozen = true
	for request_id: int in _requests.keys():
		_close_request(request_id, "", "")
	for session_id: int in _sessions.keys():
		_end_session(session_id, false, "The semester ended.")
	game.cl_clock.rpc(clock.elapsed_sec, false)
	game.cl_semester_over.rpc()
	DevTools.log_line("semester over")


func _on_player_left(peer: int) -> void:
	_connected[peer] = false
	if game.players.has(peer):
		game.players[peer].frozen = true
	_drop_from_requests_and_sessions(peer, "%s disconnected." % game.player_name(peer))
	tracker.forget_student(peer)
	if not started:
		on_peer_ready(NetworkService.HOST_ID)


func _drop_from_requests_and_sessions(peer: int, message: String) -> void:
	if _in_request.has(peer):
		_close_request(_in_request[peer], message, message)
	if _in_session.has(peer):
		_end_session(_in_session[peer], false, message)


func _fail(peer: int) -> void:
	_alive[peer] = false
	game.players[peer].frozen = true
	_drop_from_requests_and_sessions(peer, "%s failed the class." % game.player_name(peer))
	tracker.forget_student(peer)
	game.cl_player_failed.rpc(peer)
	DevTools.log_line("%s failed the class" % game.player_name(peer))


# --- Collaboration requests ------------------------------------------------

func _can_act(peer: int) -> bool:
	return started and not over and _alive.get(peer, false) and _connected.get(peer, false) \
			and not _in_request.has(peer) and not _in_session.has(peer)


## The task station both players are standing at, or &"" if none.
func _shared_station(a: int, b: int) -> StringName:
	var reach := balance.interact_radius_px + DISTANCE_SLACK_PX
	var stations := game.stations()
	for task_id: StringName in stations:
		var pos := stations[task_id]
		if game.players[a].position.distance_to(pos) <= reach \
				and game.players[b].position.distance_to(pos) <= reach:
			return task_id
	return &""


func request_collab(from: int, to: int) -> void:
	if from == to or not game.players.has(to) or not _can_act(from) or not _can_act(to):
		return
	var task_id := _shared_station(from, to)
	if task_id == &"":
		return
	var request_id := _next_id
	_next_id += 1
	var timeout := balance.collab_request_timeout_sec
	_requests[request_id] = {
		"from": from, "to": to, "task_id": task_id,
		"expires_ms": Time.get_ticks_msec() + int(timeout * 1000.0),
	}
	_in_request[from] = request_id
	_in_request[to] = request_id
	game.players[from].frozen = true
	# Only the TA's own invite carries the capture option.
	var can_capture := to == ta_peer and from != ta_peer
	var capture_ready := can_capture and tracker.can_capture(clock.elapsed_sec)
	_to(to, game.cl_invite, [request_id, from, task_id, can_capture, capture_ready, timeout])
	_to(from, game.cl_waiting, [to, task_id, timeout])
	DevTools.log_line("%s asked %s" % [game.player_name(from), game.player_name(to)])


func respond(sender: int, request_id: int, choice: Game.Choice) -> void:
	if not _requests.has(request_id) or _requests[request_id]["to"] != sender:
		return
	var request := _requests[request_id]
	var from: int = request["from"]
	var to: int = request["to"]
	var to_name := game.player_name(to)
	match choice:
		Game.Choice.DECLINE:
			_close_request(request_id, "%s declined." % to_name, "")
			DevTools.log_line("%s declined" % to_name)
		Game.Choice.ACCEPT:
			_close_request(request_id, "", "")
			_start_session(request["task_id"], [from, to])
		Game.Choice.CAPTURE:
			if to != ta_peer or from == ta_peer or not tracker.can_capture(clock.elapsed_sec):
				return
			_close_request(request_id, "", "You captured %s." % game.player_name(from))
			tracker.record_capture(clock.elapsed_sec)
			_to(ta_peer, game.cl_report_closed, [""])
			_to(ta_peer, game.cl_ta_cooldown, [tracker.cooldown_until_sec])
			_fail(from)


func _expire_requests() -> void:
	var now := Time.get_ticks_msec()
	for request_id: int in _requests.keys():
		if now >= _requests[request_id]["expires_ms"]:
			var to_name := game.player_name(_requests[request_id]["to"])
			_close_request(request_id, "%s didn't answer." % to_name, "The request timed out.")
			DevTools.log_line("request to %s timed out" % to_name)


func _close_request(request_id: int, message_from: String, message_to: String) -> void:
	if not _requests.has(request_id):
		return
	var request: Dictionary = _requests[request_id]
	_requests.erase(request_id)
	var from: int = request["from"]
	var to: int = request["to"]
	_in_request.erase(from)
	_in_request.erase(to)
	game.players[from].frozen = over or not _alive[from]
	_to(from, game.cl_request_closed, [message_from])
	_to(to, game.cl_request_closed, [message_to])


# --- Task sessions ---------------------------------------------------------

func _start_session(task_id: StringName, peers: Array[int]) -> void:
	var seats := peers.duplicate()
	seats.shuffle()
	var logic := TaskRegistry.create_logic(task_id, balance, _rng)
	var session_id := _next_id
	_next_id += 1
	_sessions[session_id] = {"task_id": task_id, "seats": seats, "logic": logic}
	for seat: int in seats.size():
		var peer: int = seats[seat]
		_in_session[peer] = session_id
		game.players[peer].frozen = true
		var partners: Array = []
		for other: int in seats:
			if other != peer:
				partners.append(game.player_name(other))
		_to(peer, game.cl_task_started, [session_id, task_id, partners, logic.payload_for(seat, now_real())])
	DevTools.log_line("session %d started: %s" % [session_id, ", ".join(seats.map(game.player_name))])


func task_action(sender: int, session_id: int, action: Dictionary) -> void:
	if not _sessions.has(session_id) or _in_session.get(sender, -1) != session_id:
		return
	var session := _sessions[session_id]
	var seats: Array = session["seats"]
	var logic: TaskLogic = session["logic"]
	var acting_seat := seats.find(sender)
	var feedback := logic.handle_action(acting_seat, action, now_real())
	for seat: int in seats.size():
		var seat_feedback := feedback if seat == acting_seat else {}
		_to(seats[seat], game.cl_task_update, [session_id, logic.payload_for(seat, now_real()), seat_feedback])
	if logic.is_complete():
		_end_session(session_id, true, "%s complete!" % TaskRegistry.display_name(session["task_id"]))


func task_cancel(sender: int, session_id: int) -> void:
	if _sessions.has(session_id) and _in_session.get(sender, -1) == session_id:
		var task_name := TaskRegistry.display_name(_sessions[session_id]["task_id"])
		_end_session(session_id, false, "%s left the %s." % [game.player_name(sender), task_name])


func _end_session(session_id: int, completed: bool, message: String) -> void:
	if not _sessions.has(session_id):
		return
	var session: Dictionary = _sessions[session_id]
	_sessions.erase(session_id)
	for peer: int in session["seats"]:
		_in_session.erase(peer)
		game.players[peer].frozen = over or not _alive[peer]
		_to(peer, game.cl_task_finished, [session_id, completed, message])
	DevTools.log_line("session %d ended: %s" % [session_id, message])


# --- Line of sight and reports ---------------------------------------------

func _check_line_of_sight() -> void:
	if ta_peer == 0 or not _alive.get(ta_peer, false) or not _connected.get(ta_peer, false):
		return
	if not tracker.can_create_report(clock.elapsed_sec):
		return
	var blocker := LineOfSight.raycast_blocker(game.get_world_2d().direct_space_state, Player.WALL_LAYER)
	var ta_pos := game.players[ta_peer].position
	for session: Dictionary in _sessions.values():
		var students := {}
		for peer: int in session["seats"]:
			if peer != ta_peer and _alive[peer]:
				students[peer] = game.players[peer].position
		if students.size() < 2:
			continue
		var seen := LineOfSight.visible_ids(ta_pos, balance.vision_radius_px, students, blocker)
		if seen.size() >= 2 and tracker.create_report(clock.elapsed_sec, seen):
			_to(ta_peer, game.cl_report_available, [seen, tracker.expires_in(clock.elapsed_sec)])
			DevTools.log_line("report available on %s" % ", ".join(seen.map(game.player_name)))
			return


func file_report(sender: int, target: int) -> void:
	if sender != ta_peer or not tracker.file_report(clock.elapsed_sec, target):
		return
	# Milestone 1: filing a report has no effect yet beyond the cooldown.
	_to(ta_peer, game.cl_report_closed, ["Report filed on %s." % game.player_name(target)])
	_to(ta_peer, game.cl_ta_cooldown, [tracker.cooldown_until_sec])
	DevTools.log_line("report filed on %s" % game.player_name(target))
