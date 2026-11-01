class_name Hud
extends CanvasLayer
## All in-game UI. Shows only what this player may know; the host decides what
## each client is told.

const ROLE_REVEAL_SEC := 4.0
const TOAST_SEC := 3.0
const BANNER_SEC := 3.5
const BOT_DELAY_SEC := 1.0

## TA only: in-game time when the report/capture cooldown ends.
var ta_cooldown_until: float = 0.0

var _game: Game
var _is_ta: bool = false
var _role_label: Label
var _week_label: Label
var _ta_label: Label
var _collab_row: Control
var _collab_button: Button
var _toast: Label
var _toast_until_ms: int = 0
var _banner: Label
var _banner_until_ms: int = 0
var _reveal: Control
var _reveal_until_ms: int = 0

var _invite: VBoxContainer
var _invite_text: Label
var _invite_capture: Button
var _invite_request_id: int = -1
var _invite_expires_ms: int = 0
var _invite_from_name: String = ""

var _waiting: VBoxContainer
var _waiting_text: Label
var _waiting_expires_ms: int = 0
var _waiting_name: String = ""

var _report: VBoxContainer
var _report_names: VBoxContainer
var _report_timer: Label
var _report_expires_ms: int = 0

var _task_layer: Control
var _minigame: Minigame
var _session_id: int = -1

var _failed_overlay: Control
var _over_overlay: Control
var _menu_overlay: Control
var _locally_failed: bool = false
var _prompt_target: int = 0
var _prompt_since_ms: int = 0


func setup(game: Game) -> void:
	_game = game
	_is_ta = Session.my_role == RoleAssigner.Role.TA
	DevTools.log_line("my role: %s" % ("TA" if _is_ta else "Student"))
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Top bar: role, week, and the TA's private status.
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	root.add_child(bar)
	var bar_row := UI.hbox(8)
	bar.add_child(bar_row)
	_role_label = UI.label("TA" if _is_ta else "Student", 8, UI.ALERT if _is_ta else UI.INK)
	bar_row.add_child(_role_label)
	_week_label = UI.centered_label("Week 1 of %d" % game.balance.semester_weeks)
	_week_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_row.add_child(_week_label)
	_ta_label = UI.label("", 8, UI.ALERT)
	bar_row.add_child(_ta_label)

	# Shown when you're at a task station next to someone you can work with.
	_collab_row = CenterContainer.new()
	_collab_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_collab_row.position = Vector2(0, 270 - 30)
	_collab_row.size = Vector2(480, 20)
	_collab_row.visible = false
	root.add_child(_collab_row)
	_collab_button = UI.button("", _ask_partner)
	_collab_row.add_child(_collab_button)

	_toast = _outlined_label(8)
	_toast.position = Vector2(0, 22)
	_toast.size = Vector2(480, 12)
	root.add_child(_toast)

	_banner = _outlined_label(16)
	_banner.position = Vector2(0, 110)
	_banner.size = Vector2(480, 24)
	_banner.add_theme_color_override("font_color", Color("#ffd6a0"))
	root.add_child(_banner)

	# Invite (someone asked you), anchored low so the room stays visible.
	_invite = _bottom_panel(root)
	_invite_text = UI.centered_label("")
	_invite.add_child(_invite_text)
	var invite_buttons := UI.hbox()
	invite_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	invite_buttons.add_child(UI.button("Accept", _respond.bind(Game.Choice.ACCEPT)))
	invite_buttons.add_child(UI.button("Decline", _respond.bind(Game.Choice.DECLINE)))
	_invite_capture = UI.button("Capture", _respond.bind(Game.Choice.CAPTURE))
	invite_buttons.add_child(_invite_capture)
	_invite.add_child(invite_buttons)

	_waiting = _bottom_panel(root)
	_waiting_text = UI.centered_label("")
	_waiting.add_child(_waiting_text)

	# TA only: report popup on the right edge.
	var report_panel := PanelContainer.new()
	report_panel.position = Vector2(480 - 130, 40)
	report_panel.custom_minimum_size = Vector2(124, 0)
	root.add_child(report_panel)
	_report = UI.vbox(3)
	report_panel.add_child(_report)
	_report.add_child(UI.label("Report to the professor:", 8, UI.ALERT))
	_report_names = UI.vbox(2)
	_report.add_child(_report_names)
	_report_timer = UI.label("", 8, UI.MUTED)
	_report.add_child(_report_timer)
	report_panel.visible = false

	_task_layer = Control.new()
	_task_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_task_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_task_layer)

	_reveal = _overlay(root, Color(0.18, 0.13, 0.22, 0.75))
	var reveal_box := UI.panel_with_vbox(UI.center_screen(_reveal), 6)
	reveal_box.custom_minimum_size = Vector2(260, 0)
	if _is_ta:
		reveal_box.add_child(UI.centered_label("You are the TA", 16, UI.ALERT))
		reveal_box.add_child(_wrapped("Stay hidden. When a student asks you to collaborate, you can secretly capture them. Watch for students working together: you can report them."))
	else:
		reveal_box.add_child(UI.centered_label("You are a Student", 16))
		reveal_box.add_child(_wrapped("Finish your work. Some tasks need a partner, but anyone you work with could be the TA."))
	_reveal.visible = true
	_reveal_until_ms = Time.get_ticks_msec() + int(ROLE_REVEAL_SEC * 1000.0)

	_failed_overlay = _overlay(root, Color(0.16, 0.2, 0.36, 0.8))
	var failed_box := UI.panel_with_vbox(UI.center_screen(_failed_overlay), 6)
	failed_box.add_child(UI.centered_label("You failed the class", 16, UI.ALERT))
	failed_box.add_child(UI.centered_label("You were captured by the TA."))
	failed_box.add_child(UI.centered_label("Wait here until the semester ends.", 8, UI.MUTED))

	_over_overlay = _overlay(root, Color(0.18, 0.13, 0.22, 0.75))
	var over_box := UI.panel_with_vbox(UI.center_screen(_over_overlay), 6)
	over_box.add_child(UI.centered_label("Semester over", 16))
	if NetworkService.is_host():
		over_box.add_child(UI.button("Back to lobby", Session.return_to_lobby))
	else:
		over_box.add_child(UI.centered_label("Waiting for the host...", 8, UI.MUTED))

	_menu_overlay = _overlay(root, Color(0.18, 0.13, 0.22, 0.5))
	var menu_box := UI.panel_with_vbox(UI.center_screen(_menu_overlay), 6)
	menu_box.add_child(UI.centered_label("Paused (the game keeps running)"))
	menu_box.add_child(UI.button("Resume", func() -> void: _menu_overlay.visible = false))
	menu_box.add_child(UI.button("Leave game", Session.leave))

	_invite.get_parent().visible = false
	_waiting.get_parent().visible = false


func _outlined_label(size: int) -> Label:
	var l := UI.centered_label("", size, Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color("#2a2030"))
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _wrapped(text: String) -> Label:
	var l := UI.centered_label(text)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _bottom_panel(root: Control) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(120, 200)
	panel.custom_minimum_size = Vector2(240, 0)
	root.add_child(panel)
	var box := UI.vbox(4)
	panel.add_child(box)
	return box


func _overlay(root: Control, shade: Color) -> Control:
	var overlay := UI.color_swatch(shade)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	root.add_child(overlay)
	return overlay


# --- Per frame -------------------------------------------------------------

func _process(delta: float) -> void:
	var now := Time.get_ticks_msec()
	if _game.server:
		_game.clock_elapsed = _game.server.clock.elapsed_sec
	elif _game.clock_running:
		_game.clock_elapsed += delta
	_update_week()
	if _is_ta:
		_update_ta_status()
	_reveal.visible = now < _reveal_until_ms
	_toast.visible = now < _toast_until_ms
	_banner.visible = now < _banner_until_ms
	if _invite.get_parent().visible:
		_invite_text.text = "%s wants to do the Problem Set with you (%d)" % [_invite_from_name, _seconds_left(_invite_expires_ms)]
	if _waiting.get_parent().visible:
		_waiting_text.text = "Waiting for %s... (%d)" % [_waiting_name, _seconds_left(_waiting_expires_ms)]
	if _report.get_parent().visible:
		_report_timer.text = "Expires in %ds" % _seconds_left(_report_expires_ms)
	if _game.local_player:
		_game.local_player.input_blocked = _modal_open()
	_update_prompt()


func _seconds_left(expires_ms: int) -> int:
	return maxi(0, ceili((expires_ms - Time.get_ticks_msec()) / 1000.0))


func _update_week() -> void:
	var week_len := _game.balance.week_length_sec
	var weeks := _game.balance.semester_weeks
	var week := mini(int(_game.clock_elapsed / week_len) + 1, weeks)
	var left := maxf(0.0, week * week_len - _game.clock_elapsed)
	_week_label.text = "Week %d of %d  -  %d:%02d left this week" % [week, weeks, int(left) / 60, int(left) % 60]


func _update_ta_status() -> void:
	var cooldown := ta_cooldown_until - _game.clock_elapsed
	if cooldown > 0.0:
		_ta_label.text = "Cooldown %d:%02d" % [int(cooldown) / 60, int(cooldown) % 60]
	else:
		_ta_label.text = "Report/capture ready"


func _modal_open() -> bool:
	return _reveal.visible or _minigame != null or _invite.get_parent().visible \
			or _waiting.get_parent().visible or _locally_failed or _game.semester_over \
			or _menu_overlay.visible


func _update_prompt() -> void:
	_prompt_target = _find_partner() if not _modal_open() else 0
	_collab_row.visible = _prompt_target != 0
	if _prompt_target == 0:
		_prompt_since_ms = 0
		return
	if _prompt_since_ms == 0:
		_prompt_since_ms = Time.get_ticks_msec()
	_collab_button.text = "Collaborate with %s" % _game.player_name(_prompt_target)
	if DevTools.has("bot-collab") and Time.get_ticks_msec() - _prompt_since_ms > BOT_DELAY_SEC * 1000.0:
		_prompt_since_ms = Time.get_ticks_msec() + 5000
		DevTools.log_line("bot asks %s" % _game.player_name(_prompt_target))
		_ask_partner()


## The nearest other player standing at the same task station as you, or 0.
func _find_partner() -> int:
	var me := _game.local_player
	if me == null or not me.visible:
		return 0
	var radius := _game.balance.interact_radius_px
	var stations := _game.stations()
	for task_id: StringName in stations:
		var station := stations[task_id]
		if me.position.distance_to(station) > radius:
			continue
		var best := 0
		var best_dist := INF
		for player: Player in _game.players.values():
			if player == me or not player.visible:
				continue
			if player.position.distance_to(station) <= radius:
				var dist := player.position.distance_to(me.position)
				if dist < best_dist:
					best = player.peer_id
					best_dist = dist
		if best != 0:
			return best
	return 0


func _ask_partner() -> void:
	if _prompt_target != 0 and not _modal_open():
		_game.rq_collab.rpc_id(NetworkService.HOST_ID, _prompt_target)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") and _minigame == null and not _game.semester_over:
		get_viewport().set_input_as_handled()
		_menu_overlay.visible = not _menu_overlay.visible


# --- Messages from the game ------------------------------------------------

func toast(text: String) -> void:
	if text.is_empty():
		return
	DevTools.log_line("toast: %s" % text)
	_toast.text = text
	_toast_until_ms = Time.get_ticks_msec() + int(TOAST_SEC * 1000.0)


func show_invite(request_id: int, from_peer: int, _task_id: StringName, can_capture: bool, capture_ready: bool, timeout: float) -> void:
	_invite_request_id = request_id
	_invite_from_name = _game.player_name(from_peer)
	_invite_expires_ms = Time.get_ticks_msec() + int(timeout * 1000.0)
	_invite_capture.visible = can_capture
	_invite_capture.disabled = not capture_ready
	_invite_capture.text = "Capture" if capture_ready else "Capture (cooldown)"
	DevTools.log_line("invite from %s, capture button: %s" % [_invite_from_name, _invite_capture.text if can_capture else "hidden"])
	_invite.get_parent().visible = true
	_menu_overlay.visible = false
	if DevTools.has("bot-respond"):
		_bot_respond(request_id)


func _bot_respond(request_id: int) -> void:
	var answer := DevTools.get_flag("bot-respond")
	if answer == "none":
		return
	await get_tree().create_timer(BOT_DELAY_SEC).timeout
	if _invite_request_id != request_id:
		return
	DevTools.log_line("bot answers %s" % answer)
	match answer:
		"accept":
			_respond(Game.Choice.ACCEPT)
		"decline":
			_respond(Game.Choice.DECLINE)
		"capture":
			_respond(Game.Choice.CAPTURE)


func _respond(choice: Game.Choice) -> void:
	if _invite_request_id < 0:
		return
	_game.rq_respond.rpc_id(NetworkService.HOST_ID, _invite_request_id, choice)


func show_waiting(target: int, _task_id: StringName, timeout: float) -> void:
	_waiting_name = _game.player_name(target)
	_waiting_expires_ms = Time.get_ticks_msec() + int(timeout * 1000.0)
	_waiting.get_parent().visible = true


## Closes whichever request popup is open (invite or waiting).
func close_request(message: String) -> void:
	_invite_request_id = -1
	_invite.get_parent().visible = false
	_waiting.get_parent().visible = false
	toast(message)


func open_task(session_id: int, task_id: StringName, partner_names: Array, payload: Dictionary) -> void:
	if _minigame:
		_minigame.queue_free()
	_menu_overlay.visible = false
	var scene := load(TaskRegistry.scene_path(task_id)) as PackedScene
	_minigame = scene.instantiate() as Minigame
	_minigame.task_id = task_id
	_minigame.partner_names.assign(partner_names)
	_session_id = session_id
	_task_layer.add_child(_minigame)
	_minigame.action_requested.connect(func(action: Dictionary) -> void:
		_game.rq_task_action.rpc_id(NetworkService.HOST_ID, session_id, action))
	_minigame.cancel_requested.connect(func() -> void:
		_game.rq_task_cancel.rpc_id(NetworkService.HOST_ID, session_id))
	_minigame.start(payload)


func update_task(session_id: int, payload: Dictionary, feedback: Dictionary) -> void:
	if _minigame and session_id == _session_id:
		_minigame.apply_update(payload, feedback)


func finish_task(session_id: int, completed: bool, message: String) -> void:
	if _minigame == null or session_id != _session_id:
		return
	if completed:
		_minigame.complete()
	else:
		_minigame.cancel()
	_minigame.queue_free()
	_minigame = null
	_session_id = -1
	toast(message)


func show_failed(peer_id: int) -> void:
	DevTools.log_line("sees %s fail" % _game.player_name(peer_id))
	if peer_id == multiplayer.get_unique_id():
		_locally_failed = true
		_failed_overlay.visible = true
		_menu_overlay.visible = false
		return
	_banner.text = "%s failed the class" % _game.player_name(peer_id)
	_banner_until_ms = Time.get_ticks_msec() + int(BANNER_SEC * 1000.0)


func show_report(ids: Array, expires_in: float) -> void:
	for child: Node in _report_names.get_children():
		child.queue_free()
	for id: int in ids:
		_report_names.add_child(UI.button(_game.player_name(id), _file_report.bind(id)))
	_report_expires_ms = Time.get_ticks_msec() + int(expires_in * 1000.0)
	_report.get_parent().visible = true
	DevTools.log_line("report popup: %s" % ", ".join(ids.map(_game.player_name)))
	if DevTools.has("bot-report"):
		await get_tree().create_timer(BOT_DELAY_SEC).timeout
		if _report.get_parent().visible:
			DevTools.log_line("bot reports %s" % _game.player_name(ids[0]))
			_file_report(ids[0])


func _file_report(target: int) -> void:
	_game.rq_file_report.rpc_id(NetworkService.HOST_ID, target)


func close_report(message: String) -> void:
	_report.get_parent().visible = false
	toast(message)


func show_semester_over() -> void:
	_failed_overlay.visible = false
	_menu_overlay.visible = false
	_invite.get_parent().visible = false
	_waiting.get_parent().visible = false
	if _minigame:
		_minigame.queue_free()
		_minigame = null
	_over_overlay.visible = true
	DevTools.log_line("semester over screen")
	if DevTools.has("bot-lobby") and NetworkService.is_host():
		await get_tree().create_timer(BOT_DELAY_SEC).timeout
		Session.return_to_lobby()
