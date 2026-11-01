class_name DinnerPanel
extends CanvasLayer
## Dinner UI only. All eligibility, timing, chat and voting are host-validated.

var _game: Game
var _overlay: Control
var _title: Label
var _timer: Label
var _coursework_bar: ProgressBar
var _messages: RichTextLabel
var _entry: LineEdit
var _votes: GridContainer
var _status: Label
var _call_button: Button
var _phase: String = "closed"
var _deadline_ms: int = 0
var _chat_lines: Array[String] = []
var _voted: bool = false
var _bot_voted: bool = false
var _bot_chatted: bool = false


func setup(game: Game) -> void:
	_game = game
	layer = 2
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_call_button = UI.button("Call dinner (1/game)", func() -> void:
		_game.rq_dinner.rpc_id(NetworkService.HOST_ID))
	_call_button.position = Vector2(6, 248)
	root.add_child(_call_button)

	_overlay = UI.color_swatch(Color(0.18, 0.13, 0.22, 0.95))
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	root.add_child(_overlay)
	var box := UI.panel_with_vbox(UI.center_screen(_overlay), 3)
	box.custom_minimum_size.x = 360
	_title = UI.centered_label("Rev Noodle dinner", 12)
	box.add_child(_title)
	_coursework_bar = ProgressBar.new()
	_coursework_bar.custom_minimum_size = Vector2(350, 10)
	_coursework_bar.show_percentage = false
	box.add_child(_coursework_bar)
	_timer = UI.centered_label("")
	box.add_child(_timer)
	_messages = RichTextLabel.new()
	_messages.custom_minimum_size = Vector2(350, 70)
	_messages.bbcode_enabled = false
	_messages.scroll_following = true
	_messages.add_theme_font_size_override("normal_font_size", 8)
	box.add_child(_messages)
	var row := UI.hbox(3)
	_entry = LineEdit.new()
	_entry.placeholder_text = "Discuss what you saw (Enter to send)"
	_entry.max_length = game.balance.chat_character_limit
	_entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry.text_submitted.connect(_send_chat)
	row.add_child(_entry)
	row.add_child(UI.button("Send", func() -> void: _send_chat(_entry.text)))
	box.add_child(row)
	_votes = GridContainer.new()
	_votes.columns = 4
	box.add_child(_votes)
	_status = UI.centered_label("")
	box.add_child(_status)
	if DevTools.has("bot-call-dinner"):
		_bot_call_dinner()


func _process(_delta: float) -> void:
	_call_button.visible = not _game.dinner_active and not _game.semester_over and not _game.hud.is_failed() and _game.local_player != null and not _game.local_player.input_blocked
	if _phase == "closed":
		return
	var left := maxi(0, ceili((_deadline_ms - Time.get_ticks_msec()) / 1000.0))
	_timer.text = "%s: %ds (semester clock paused)" % [_phase.capitalize(), left]


func show_phase(phase: String, seconds: float, eligible: Array, message: String) -> void:
	var starting := phase == "discussion" and _phase != "discussion"
	_title.text = "Rev Noodle - Coursework %d%%" % roundi(_game.coursework_at_dinner * 100)
	_coursework_bar.value = _game.coursework_at_dinner * 100
	_phase = phase
	_deadline_ms = Time.get_ticks_msec() + int(seconds * 1000.0)
	_overlay.visible = phase != "closed"
	if phase == "closed":
		_entry.release_focus()
		return
	for child: Node in _votes.get_children():
		_votes.remove_child(child)
		child.queue_free()
	_entry.editable = phase in ["discussion", "voting"]
	_status.text = message
	if starting:
		_chat_lines.clear()
		_messages.text = ""
		_entry.text = ""
		_voted = false
		_bot_voted = false
		_bot_chatted = false
	if phase == "voting":
		for id: int in eligible:
			_votes.add_child(UI.button(_game.player_name(id), _vote.bind(id)))
		_votes.add_child(UI.button("Skip", _vote.bind(0)))
		if _voted:
			vote_received()
	DevTools.log_line("dinner phase: %s" % phase)
	_bot_actions.call_deferred()


func _send_chat(text: String) -> void:
	if _phase not in ["discussion", "voting"]:
		return
	_game.rq_chat.rpc_id(NetworkService.HOST_ID, text)
	_entry.text = ""


func add_message(sender: int, text: String) -> void:
	_chat_lines.append("%s: %s" % [_game.player_name(sender), text])
	if _chat_lines.size() > 30:
		_chat_lines.pop_front()
	_messages.text = "\n".join(_chat_lines)
	DevTools.log_line("dinner chat: %s" % text)


func _vote(target: int) -> void:
	if _phase == "voting" and not _voted:
		_game.rq_vote.rpc_id(NetworkService.HOST_ID, target)


func vote_received() -> void:
	_voted = true
	_status.text = "Vote recorded. Waiting for the other players."
	for child: Node in _votes.get_children():
		(child as Button).disabled = true


func call_used() -> void:
	_call_button.disabled = true
	_call_button.text = "Dinner call used"


func _unhandled_input(event: InputEvent) -> void:
	if _overlay.visible and event.is_action_pressed("open_chat"):
		_entry.grab_focus()
		get_viewport().set_input_as_handled()


## Scripted flags are debug-only, like the inherited puzzle bots.
func _bot_actions() -> void:
	if _phase == "discussion" and DevTools.has("bot-chat") and not _bot_chatted:
		_bot_chatted = true
		_send_chat(DevTools.get_flag("bot-chat"))
	if _phase == "voting" and DevTools.has("bot-vote") and not _bot_voted:
		_bot_voted = true
		var wanted := DevTools.get_flag("bot-vote")
		var target := 0
		for id: int in Session.roster:
			if _game.player_name(id) == wanted:
				target = id
		_vote(target)


func _bot_call_dinner() -> void:
	await get_tree().create_timer(DevTools.get_flag("bot-call-dinner").to_float()).timeout
	if not _game.semester_over:
		_game.rq_dinner.rpc_id(NetworkService.HOST_ID)
