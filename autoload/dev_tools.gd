extends Node
## Debug builds only: command-line flags for scripted multi-instance testing.
## Pass flags after `--`, e.g. `godot --path . -- --host --dev --autostart=3`.
##
##   --name=X --color=N        use this name/color for this run (not saved)
##   --host / --join=IP        host or join at startup
##   --port=N                  port for --host/--join (default from balance)
##   --dev                     turn on dev mode (host)
##   --autostart=N             host starts the game once N players are in
##   --force-ta=NAME|host      dev mode: force who is TA (host)
##   --week-sec=N              override week length (host)
##   --bot-goto=X,Y            walk to this pixel position in the room
##   --bot-collab              press E whenever a collaboration prompt shows
##   --bot-respond=accept|decline|capture|none   answer collaboration invites
##   --bot-play                play the correct Proof Chain card on your turn
##   --bot-report              file the first name in a report popup
##   --bot-lobby               host goes back to the lobby when the semester ends
##   --shot=PATH --shot-after=SEC   save a screenshot
##   --quit-after=SEC          quit after this many seconds

var enabled: bool = false
var flags: Dictionary[String, String] = {}
var _bot_arrived: bool = false


func _ready() -> void:
	enabled = OS.is_debug_build()
	if not enabled:
		return
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var parts := arg.substr(2).split("=", true, 1)
		flags[parts[0]] = parts[1] if parts.size() > 1 else ""
	if flags.is_empty():
		return
	log_line("flags %s" % flags)
	if has("name"):
		# Scripted runs share the real player's profile file; never write to it.
		Session.profile_saving = false
		Session.profile_name = Session.clean_name(get_flag("name"))
	if has("color"):
		Session.profile_color = get_flag("color").to_int()
	if has("week-sec"):
		Session.balance = Session.balance.duplicate()
		Session.balance.week_length_sec = get_flag("week-sec").to_float()
	if has("shot"):
		_screenshot_later(get_flag("shot"), get_flag("shot-after", "3").to_float())
	if has("quit-after"):
		get_tree().create_timer(get_flag("quit-after").to_float()).timeout.connect(get_tree().quit)
	Session.roster_changed.connect(_on_roster_changed)
	_connect_at_startup.call_deferred()


func has(flag: String) -> bool:
	return enabled and flags.has(flag)


func get_flag(flag: String, default: String = "") -> String:
	return flags.get(flag, default) if enabled else default


func log_line(text: String) -> void:
	if enabled:
		print("[Dev %s] %s" % [Session.profile_name, text])


## Direction a bot should walk this frame, or ZERO when not botting or arrived.
func bot_move_dir(from: Vector2) -> Vector2:
	if not has("bot-goto"):
		return Vector2.ZERO
	var xy := get_flag("bot-goto").split(",")
	var target := Vector2(xy[0].to_float(), xy[1].to_float())
	if from.distance_to(target) < 2.0:
		if not _bot_arrived:
			_bot_arrived = true
			log_line("arrived at %s" % target)
		return Vector2.ZERO
	return from.direction_to(target)


func _connect_at_startup() -> void:
	if has("dev"):
		Session.set_dev_mode(true)
	var port := get_flag("port", str(Session.balance.default_port)).to_int()
	if has("host"):
		var err := NetworkService.host_lan(port, Session.balance.max_players)
		if err != OK:
			log_line("couldn't host on port %d, quitting" % port)
			get_tree().quit(1)
			return
		App.go_to_lobby()
	elif has("join"):
		NetworkService.join_lan(get_flag("join"), port)
		NetworkService.connected_to_host.connect(App.go_to_lobby, CONNECT_ONE_SHOT)


func _on_roster_changed() -> void:
	if not NetworkService.is_host() or Session.in_game:
		return
	if has("force-ta"):
		var wanted := get_flag("force-ta")
		for id: int in Session.roster:
			if (wanted == "host" and id == NetworkService.HOST_ID) or Session.player_name(id) == wanted:
				Session.forced_ta = id
	if has("autostart") and Session.roster.size() >= get_flag("autostart").to_int():
		log_line("autostart with %d players" % Session.roster.size())
		Session.start_game.call_deferred()


func _screenshot_later(path: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	var err := get_viewport().get_texture().get_image().save_png(path)
	log_line("screenshot %s -> %s" % [path, error_string(err)])
