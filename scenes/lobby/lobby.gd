extends Control
## Player list, name and color picker, and (for the host) the Start button.

var _players_box: VBoxContainer
var _name_edit: LineEdit
var _colors_box: HBoxContainer
var _start_button: Button
var _count_label: Label
var _dev_box: HBoxContainer
var _ta_picker: OptionButton


func _ready() -> void:
	var bg := UI.color_swatch(UI.BACKDROP)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := UI.panel_with_vbox(UI.center_screen(self), 5)
	box.custom_minimum_size = Vector2(260, 0)
	box.add_child(UI.centered_label("Lobby", 16))

	if NetworkService.is_host():
		var addresses := ", ".join(NetworkService.local_addresses())
		var where := UI.centered_label("Others join with IP: %s  (port %d)" % [addresses, Session.balance.default_port])
		where.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(where)

	_players_box = UI.vbox(2)
	box.add_child(_players_box)

	var name_row := UI.hbox()
	name_row.add_child(UI.label("Your name"))
	_name_edit = LineEdit.new()
	_name_edit.max_length = Session.MAX_NAME_LENGTH
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.text_submitted.connect(func(_t: String) -> void: _apply_name())
	_name_edit.focus_exited.connect(_apply_name)
	name_row.add_child(_name_edit)
	box.add_child(name_row)

	var color_row := UI.hbox()
	color_row.add_child(UI.label("Color"))
	_colors_box = UI.hbox(2)
	color_row.add_child(_colors_box)
	box.add_child(color_row)

	_dev_box = UI.hbox()
	_dev_box.add_child(UI.label("Dev mode: TA is", 8, UI.ALERT))
	_ta_picker = OptionButton.new()
	_ta_picker.focus_mode = Control.FOCUS_NONE
	_ta_picker.item_selected.connect(_on_ta_picked)
	_dev_box.add_child(_ta_picker)
	box.add_child(_dev_box)

	_count_label = UI.centered_label("")
	box.add_child(_count_label)

	var buttons := UI.hbox()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_start_button = UI.button("Start game", Session.start_game)
	_start_button.visible = NetworkService.is_host()
	buttons.add_child(_start_button)
	buttons.add_child(UI.button("Leave", Session.leave))
	box.add_child(buttons)

	Session.roster_changed.connect(_refresh)
	Session.settings_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var me := multiplayer.get_unique_id()
	for child: Node in _players_box.get_children():
		child.queue_free()
	for id: int in Session.sorted_peer_ids():
		var row := UI.hbox()
		row.add_child(UI.color_swatch(PlayerColors.get_color(Session.player_color(id))))
		var suffix := ""
		if id == NetworkService.HOST_ID:
			suffix += "  (host)"
		if id == me:
			suffix += "  (you)"
		row.add_child(UI.label(Session.player_name(id) + suffix))
		_players_box.add_child(row)

	if not _name_edit.has_focus() and Session.roster.has(me):
		_name_edit.text = Session.player_name(me)

	for child: Node in _colors_box.get_children():
		child.queue_free()
	for c: int in PlayerColors.COLORS.size():
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(12, 12)
		swatch.focus_mode = Control.FOCUS_NONE
		swatch.tooltip_text = PlayerColors.NAMES[c]
		var style := StyleBoxFlat.new()
		style.bg_color = PlayerColors.get_color(c)
		style.border_color = UI.INK if Session.player_color(me) == c else Color(0, 0, 0, 0)
		style.set_border_width_all(2)
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			swatch.add_theme_stylebox_override(state, style)
		swatch.disabled = Session.color_taken(c, me)
		if swatch.disabled:
			swatch.modulate = Color(1, 1, 1, 0.25)
		swatch.pressed.connect(func() -> void: Session.update_profile(_name_edit.text, c))
		_colors_box.add_child(swatch)

	_dev_box.visible = Session.dev_mode and NetworkService.is_host()
	_ta_picker.clear()
	_ta_picker.add_item("Random", 0)
	for id: int in Session.sorted_peer_ids():
		_ta_picker.add_item(Session.player_name(id), id)
	_ta_picker.select(maxi(0, _ta_picker.get_item_index(Session.forced_ta)))

	var needed := Session.min_players()
	var count_text := "%d / %d players" % [Session.roster.size(), Session.balance.max_players]
	if Session.roster.size() < needed:
		count_text += "  -  need %d to start" % needed
	if Session.dev_mode:
		count_text += "  (dev mode)"
	_count_label.text = count_text
	_start_button.disabled = not Session.can_start()


func _apply_name() -> void:
	var me := multiplayer.get_unique_id()
	if Session.clean_name(_name_edit.text) != Session.player_name(me):
		Session.update_profile(_name_edit.text, Session.player_color(me))


func _on_ta_picked(index: int) -> void:
	Session.forced_ta = _ta_picker.get_item_id(index)
