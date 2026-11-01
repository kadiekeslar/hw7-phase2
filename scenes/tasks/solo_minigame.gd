extends Minigame
## Shared presentation for the new solo programming puzzle and timed grading.

var _box: VBoxContainer
var _content: VBoxContainer
var _status: Label
var _timer: Label
var _submit: Button
var _deadline_ms: int = 0
var _duration: float = 1.0
var _payload: Dictionary = {}
var _bot_pending: bool = false


func start(payload: Dictionary) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := UI.color_swatch(Color(0.2, 0.15, 0.25, 0.9))
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_box = UI.panel_with_vbox(UI.center_screen(self), 4)
	_box.custom_minimum_size.x = 320
	_box.add_child(UI.centered_label(TaskRegistry.display_name(task_id), 12))
	_content = UI.vbox(2)
	_box.add_child(_content)
	_timer = UI.centered_label("")
	_box.add_child(_timer)
	_submit = UI.button("Finish grading batch", func() -> void: action_requested.emit({"submit": true}))
	_box.add_child(_submit)
	_status = UI.centered_label("")
	_box.add_child(_status)
	_box.add_child(UI.button("Cancel (unfinished work is lost)", func() -> void: cancel_requested.emit()))
	apply_update(payload, {})


func apply_update(payload: Dictionary, feedback: Dictionary) -> void:
	_payload = payload
	_status.text = feedback.get("message", "")
	var grading: bool = payload["kind"] == "grading"
	_submit.visible = grading
	_timer.visible = grading
	if grading:
		_deadline_ms = Time.get_ticks_msec() + ceili(float(payload["seconds_left"]) * 1000.0)
		_duration = payload["duration"]
		if _content.get_child_count() == 0:
			_content.add_child(UI.centered_label("Stay at this desk to grade a batch of papers."))
	else:
		for child: Node in _content.get_children():
			_content.remove_child(child)
			child.queue_free()
		_content.add_child(UI.centered_label(payload["goal"]))
		_content.add_child(UI.centered_label("Click the code blocks in execution order.", 8, UI.MUTED))
		var cards: Array = payload["cards"]
		var selected: Array = payload["selected"]
		for index: int in cards.size():
			var prefix := "%d. " % (selected.find(index) + 1) if index in selected else "    "
			var button := UI.button(prefix + String(cards[index]), func() -> void: action_requested.emit({"card": index}))
			button.disabled = index in selected
			_content.add_child(button)
		_maybe_bot_program()


func _process(_delta: float) -> void:
	if _payload.get("kind", "") != "grading":
		return
	var seconds := maxf(0.0, (_deadline_ms - Time.get_ticks_msec()) / 1000.0)
	_timer.text = "Grading: %.1fs remaining" % seconds
	_submit.disabled = seconds > 0
	if seconds <= 0 and DevTools.has("bot-grade") and not _bot_pending:
		_bot_pending = true
		action_requested.emit({"submit": true})


func progress() -> float:
	if _payload.get("kind", "") == "grading":
		return clampf(1.0 - float(_deadline_ms - Time.get_ticks_msec()) / (1000.0 * _duration), 0, 1)
	return float(_payload.get("selected", []).size()) / 5.0


func _maybe_bot_program() -> void:
	if not DevTools.has("bot-program") or _bot_pending:
		return
	_bot_pending = true
	await get_tree().create_timer(0.05).timeout
	_bot_pending = false
	# A test bot tries each unused block; the server still validates the order.
	var cards: Array = _payload.get("cards", [])
	var selected: Array = _payload.get("selected", [])
	for index: int in cards.size():
		if index not in selected:
			action_requested.emit({"card": index})
