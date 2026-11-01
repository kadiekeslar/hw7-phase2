extends Minigame
## Problem Set: take turns playing the clue card that continues the chain.

var _title: Label
var _chain_box: HBoxContainer
var _hand_box: HBoxContainer
var _status: Label
var _payload: Dictionary = {}
var _locked_until_ms: int = 0
var _bot_pending: bool = false


func start(payload: Dictionary) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := UI.color_swatch(Color(0.2, 0.15, 0.25, 0.45))
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var box := UI.panel_with_vbox(UI.center_screen(self), 6)
	box.custom_minimum_size = Vector2(300, 0)
	_title = UI.centered_label("Problem Set with %s" % ", ".join(partner_names), 8)
	box.add_child(_title)
	box.add_child(UI.centered_label("Take turns. Play the card that starts with the last symbol.", 8, UI.MUTED))
	_chain_box = UI.hbox(3)
	_chain_box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_chain_box)
	box.add_child(UI.centered_label("Your clues", 8, UI.MUTED))
	_hand_box = UI.hbox(4)
	_hand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_hand_box)
	_status = UI.centered_label("")
	box.add_child(_status)
	box.add_child(UI.centered_label("Esc: leave (progress is lost)", 8, UI.MUTED))
	apply_update(payload, {})


func apply_update(payload: Dictionary, feedback: Dictionary) -> void:
	_payload = payload
	_locked_until_ms = Time.get_ticks_msec() + int(float(payload.get("locked_for", 0.0)) * 1000.0)
	_draw_chain()
	_draw_hand(feedback.get("wrong_card", -1))
	_update_status()
	_maybe_bot_play()


func progress() -> float:
	var chain: Array = _payload.get("chain", [])
	var length: int = _payload.get("length", 1)
	return float(chain.size() - 1) / float(maxi(1, length - 1))


func complete() -> void:
	_status.text = "Problem Set complete!"


func cancel() -> void:
	pass


func _process(_delta: float) -> void:
	if not _payload.is_empty():
		_update_status()


func _draw_chain() -> void:
	for child: Node in _chain_box.get_children():
		child.queue_free()
	var chain: Array = _payload["chain"]
	var length: int = _payload["length"]
	for i: int in length:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(22, 22)
		var icon := SymbolIcon.new(chain[i] if i < chain.size() else -1, Vector2(14, 14))
		slot.add_child(icon)
		_chain_box.add_child(slot)
		if i < length - 1:
			_chain_box.add_child(UI.label(">", 8, UI.MUTED))


func _draw_hand(wrong_index: int) -> void:
	for child: Node in _hand_box.get_children():
		child.queue_free()
	var hand: Array = _payload["hand"]
	for i: int in hand.size():
		var card: Array = hand[i]
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(44, 24)
		var center := CenterContainer.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		button.add_child(center)
		var row := UI.hbox(2)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(SymbolIcon.new(card[0], Vector2(12, 12)))
		row.add_child(UI.label(">", 8, UI.CREAM))
		row.add_child(SymbolIcon.new(card[1], Vector2(12, 12)))
		center.add_child(row)
		button.pressed.connect(_on_card_pressed.bind(i))
		_hand_box.add_child(button)
		if i == wrong_index:
			_shake(button)


func _update_status() -> void:
	var locked_ms := _locked_until_ms - Time.get_ticks_msec()
	if _payload.get("complete", false):
		_status.text = "Problem Set complete!"
	elif locked_ms > 0:
		_status.text = "Wrong card! Hand locked %.1fs" % (locked_ms / 1000.0)
		_status.add_theme_color_override("font_color", UI.ALERT)
		return
	elif _payload.get("my_turn", false):
		_status.text = "Your turn"
	else:
		_status.text = "%s's turn" % ", ".join(partner_names)
	_status.add_theme_color_override("font_color", UI.INK)


func _on_card_pressed(index: int) -> void:
	if not _payload.get("my_turn", false) or Time.get_ticks_msec() < _locked_until_ms:
		return
	action_requested.emit({"card": index})


func _shake(control: Control) -> void:
	var tween := create_tween()
	for offset: float in [3.0, -3.0, 2.0, -2.0, 0.0]:
		tween.tween_property(control, "position:x", control.position.x + offset, 0.04)


func _maybe_bot_play() -> void:
	if not DevTools.has("bot-play") or _bot_pending or not _payload.get("my_turn", false):
		return
	_bot_pending = true
	await get_tree().create_timer(0.6).timeout
	_bot_pending = false
	var chain: Array = _payload["chain"]
	var hand: Array = _payload["hand"]
	for i: int in hand.size():
		if hand[i][0] == chain[-1]:
			DevTools.log_line("bot plays card %d" % i)
			_on_card_pressed(i)
			return
