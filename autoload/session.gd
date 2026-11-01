extends Node
## The lobby roster, this player's saved profile, and this player's own role.
## The host owns the roster; clients get copies. Only the host knows who the TA is.

signal roster_changed
signal settings_changed
## A player disconnected during a game (host only).
signal player_left_game(peer_id: int)

const PROFILE_PATH := "user://profile.cfg"
const MAX_NAME_LENGTH := 16

var balance: GameBalance = preload("res://config/game_balance.tres")

var profile_name: String = ""
var profile_color: int = 0
## Turned off by DevTools for scripted test runs.
var profile_saving: bool = true

## peer_id -> {"name": String, "color": int}
var roster: Dictionary[int, Dictionary] = {}
## Temporary: lets 2-4 players start a game. Set by the host on the main menu.
var dev_mode: bool = false
## Dev mode only: the peer forced to be TA, or 0 for random. Host only.
var forced_ta: int = 0

var in_game: bool = false
var my_role: RoleAssigner.Role = RoleAssigner.Role.STUDENT
## Host only.
var ta_peer: int = 0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	load_profile()
	NetworkService.hosting_started.connect(_on_hosting_started)
	NetworkService.connected_to_host.connect(_on_connected_to_host)
	NetworkService.peer_left.connect(_on_peer_left)
	NetworkService.host_left.connect(_on_host_left)


# --- Profile ---------------------------------------------------------------

func load_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PROFILE_PATH) == OK:
		profile_name = cfg.get_value("profile", "name", "")
		profile_color = cfg.get_value("profile", "color", 0)
	if profile_name.is_empty():
		profile_name = "Student %d" % _rng.randi_range(100, 999)


func save_profile() -> void:
	if not profile_saving:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "name", profile_name)
	cfg.set_value("profile", "color", profile_color)
	cfg.save(PROFILE_PATH)


static func clean_name(raw: String) -> String:
	var cleaned := raw.strip_edges().strip_escapes()
	return cleaned.substr(0, MAX_NAME_LENGTH)


# --- Lobby -----------------------------------------------------------------

func min_players() -> int:
	return balance.dev_min_players if dev_mode else balance.min_players


func can_start() -> bool:
	return NetworkService.is_host() and not in_game and roster.size() >= min_players()


func sorted_peer_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(roster.keys())
	ids.sort()
	return ids


func player_name(peer_id: int) -> String:
	return roster[peer_id]["name"] if roster.has(peer_id) else "?"


func player_color(peer_id: int) -> int:
	return roster[peer_id]["color"] if roster.has(peer_id) else 0


func color_taken(color: int, by_other_than: int) -> bool:
	for id: int in roster:
		if id != by_other_than and roster[id]["color"] == color:
			return true
	return false


## Changes this player's name and color, saves the profile and tells the host.
func update_profile(new_name: String, new_color: int) -> void:
	var cleaned := clean_name(new_name)
	if not cleaned.is_empty():
		profile_name = cleaned
	profile_color = new_color
	save_profile()
	if NetworkService.is_connected_to_game():
		_rq_update_profile.rpc_id(NetworkService.HOST_ID, profile_name, profile_color)


func set_dev_mode(enabled: bool) -> void:
	dev_mode = enabled
	if not enabled:
		forced_ta = 0
	if NetworkService.is_host():
		_cl_settings.rpc(dev_mode)
	settings_changed.emit()


func start_game() -> void:
	if not can_start():
		return
	var ids := sorted_peer_ids()
	ta_peer = RoleAssigner.pick_ta(ids, _rng, forced_ta if dev_mode else 0)
	for id: int in ids:
		var role := RoleAssigner.Role.TA if id == ta_peer else RoleAssigner.Role.STUDENT
		_cl_start_game.rpc_id(id, role)


## Host: brings everyone back from the game to the lobby.
func return_to_lobby() -> void:
	if NetworkService.is_host():
		_cl_return_to_lobby.rpc()


func leave() -> void:
	NetworkService.leave()
	_reset()
	App.go_to_menu()


func _reset() -> void:
	roster.clear()
	in_game = false
	ta_peer = 0
	forced_ta = 0
	my_role = RoleAssigner.Role.STUDENT


func _on_hosting_started() -> void:
	_reset()
	roster[NetworkService.HOST_ID] = {"name": profile_name, "color": profile_color}
	roster_changed.emit()


func _on_connected_to_host() -> void:
	_rq_register.rpc_id(NetworkService.HOST_ID, profile_name, profile_color)


func _on_peer_left(peer_id: int) -> void:
	if not NetworkService.is_host() or not roster.has(peer_id):
		return
	if in_game:
		# Keep them in the roster so their frozen character stays in the game.
		player_left_game.emit(peer_id)
		return
	roster.erase(peer_id)
	_broadcast_roster()


func _on_host_left() -> void:
	_reset()
	App.go_to_menu("Host left.")


# --- Host-side helpers -----------------------------------------------------

func _unique_name(wanted: String, peer_id: int) -> String:
	var base := clean_name(wanted)
	if base.is_empty():
		base = "Student"
	var candidate := base
	var n := 2
	while _name_taken(candidate, peer_id):
		var suffix := " %d" % n
		candidate = base.substr(0, MAX_NAME_LENGTH - suffix.length()) + suffix
		n += 1
	return candidate


func _name_taken(candidate: String, peer_id: int) -> bool:
	for id: int in roster:
		if id != peer_id and String(roster[id]["name"]).to_lower() == candidate.to_lower():
			return true
	return false


func _free_color(wanted: int, peer_id: int) -> int:
	if wanted >= 0 and wanted < PlayerColors.COLORS.size() and not color_taken(wanted, peer_id):
		return wanted
	for c: int in PlayerColors.COLORS.size():
		if not color_taken(c, peer_id):
			return c
	return 0


func _broadcast_roster() -> void:
	var packed: Array = []
	for id: int in sorted_peer_ids():
		packed.append([id, roster[id]["name"], roster[id]["color"]])
	_cl_roster.rpc(packed, dev_mode)
	roster_changed.emit()


# --- RPCs: client -> host --------------------------------------------------

@rpc("any_peer", "reliable")
func _rq_register(wanted_name: String, wanted_color: int) -> void:
	if not NetworkService.is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	if in_game:
		_cl_rejected.rpc_id(sender, "That game has already started.")
		return
	if roster.size() >= balance.max_players:
		_cl_rejected.rpc_id(sender, "That lobby is full.")
		return
	roster[sender] = {"name": _unique_name(wanted_name, sender), "color": _free_color(wanted_color, sender)}
	_broadcast_roster()


@rpc("any_peer", "call_local", "reliable")
func _rq_update_profile(wanted_name: String, wanted_color: int) -> void:
	if not NetworkService.is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = NetworkService.HOST_ID
	if not roster.has(sender) or in_game:
		return
	roster[sender] = {"name": _unique_name(wanted_name, sender), "color": _free_color(wanted_color, sender)}
	_broadcast_roster()


# --- RPCs: host -> clients -------------------------------------------------

@rpc("authority", "reliable")
func _cl_roster(packed: Array, host_dev_mode: bool) -> void:
	roster.clear()
	for entry: Array in packed:
		roster[entry[0]] = {"name": entry[1], "color": entry[2]}
	dev_mode = host_dev_mode
	roster_changed.emit()


@rpc("authority", "reliable")
func _cl_settings(host_dev_mode: bool) -> void:
	dev_mode = host_dev_mode
	settings_changed.emit()


@rpc("authority", "reliable")
func _cl_rejected(reason: String) -> void:
	NetworkService.leave()
	_reset()
	App.go_to_menu(reason)


@rpc("authority", "call_local", "reliable")
func _cl_start_game(role: RoleAssigner.Role) -> void:
	my_role = role
	in_game = true
	App.go_to_game()


@rpc("authority", "call_local", "reliable")
func _cl_return_to_lobby() -> void:
	in_game = false
	my_role = RoleAssigner.Role.STUDENT
	if NetworkService.is_host():
		ta_peer = 0
		# Drop anyone who disconnected during the game.
		for id: int in sorted_peer_ids():
			if id != NetworkService.HOST_ID and id not in multiplayer.get_peers():
				roster.erase(id)
		_broadcast_roster()
	App.go_to_lobby()
