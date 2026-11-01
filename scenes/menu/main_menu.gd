extends Control
## Host or join a game. Online room codes arrive once the relay server is set up.

var _name_edit: LineEdit
var _ip_edit: LineEdit
var _port_edit: LineEdit
var _dev_check: CheckBox
var _status: Label
var _join_button: Button


func _ready() -> void:
	var bg := UI.color_swatch(UI.BACKDROP)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := UI.panel_with_vbox(UI.center_screen(self), 5)
	box.custom_minimum_size = Vector2(220, 0)
	box.add_child(UI.centered_label("Study Buddies", 16))

	var name_row := UI.hbox()
	name_row.add_child(UI.label("Name"))
	_name_edit = LineEdit.new()
	_name_edit.text = Session.profile_name
	_name_edit.max_length = Session.MAX_NAME_LENGTH
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(_name_edit)
	box.add_child(name_row)

	box.add_child(UI.button("Host game (LAN)", _on_host))

	var join_row := UI.hbox()
	_ip_edit = LineEdit.new()
	_ip_edit.placeholder_text = "Host IP, e.g. 192.168.1.20"
	_ip_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ip_edit.text_submitted.connect(func(_t: String) -> void: _on_join())
	join_row.add_child(_ip_edit)
	_port_edit = LineEdit.new()
	_port_edit.text = str(Session.balance.default_port)
	_port_edit.custom_minimum_size = Vector2(36, 0)
	join_row.add_child(_port_edit)
	_join_button = UI.button("Join", _on_join)
	join_row.add_child(_join_button)
	box.add_child(join_row)

	var code_button := UI.button("Join by room code (needs relay server)", func() -> void: pass)
	code_button.disabled = true
	box.add_child(code_button)

	_dev_check = CheckBox.new()
	_dev_check.text = "Dev mode (temporary): start with 2-4 players"
	_dev_check.focus_mode = Control.FOCUS_NONE
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		_dev_check.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_dev_check.button_pressed = Session.dev_mode
	_dev_check.toggled.connect(Session.set_dev_mode)
	box.add_child(_dev_check)

	_status = UI.centered_label(App.menu_message, 8, UI.ALERT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)
	App.menu_message = ""

	box.add_child(UI.button("Quit", get_tree().quit))

	NetworkService.connected_to_host.connect(_on_connected)
	NetworkService.connection_failed.connect(_on_failed)


func _save_name() -> void:
	Session.update_profile(_name_edit.text, Session.profile_color)
	_name_edit.text = Session.profile_name


func _port() -> int:
	var port := _port_edit.text.to_int()
	return port if port > 0 and port < 65536 else Session.balance.default_port


func _on_host() -> void:
	_save_name()
	var err := NetworkService.host_lan(_port(), Session.balance.max_players)
	if err != OK:
		_status.text = "Couldn't host on port %d (%s)." % [_port(), error_string(err)]
		return
	App.go_to_lobby()


func _on_join() -> void:
	var address := _ip_edit.text.strip_edges()
	if address.is_empty():
		_status.text = "Type the host's IP address."
		return
	_save_name()
	var err := NetworkService.join_lan(address, _port())
	if err != OK:
		_status.text = "Couldn't connect (%s)." % error_string(err)
		return
	_status.text = "Connecting..."
	_join_button.disabled = true


func _on_connected() -> void:
	App.go_to_lobby()


func _on_failed(reason: String) -> void:
	_status.text = reason
	_join_button.disabled = false
