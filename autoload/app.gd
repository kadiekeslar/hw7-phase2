extends Node
## Scene switching, window controls and messages shown on the main menu.

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const LOBBY_SCENE := "res://scenes/lobby/lobby.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"

## Shown once by the main menu, e.g. "Host left".
var menu_message: String = ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func go_to_menu(message: String = "") -> void:
	menu_message = message
	get_tree().change_scene_to_file.call_deferred(MENU_SCENE)


func go_to_lobby() -> void:
	get_tree().change_scene_to_file.call_deferred(LOBBY_SCENE)


func go_to_game() -> void:
	get_tree().change_scene_to_file.call_deferred(GAME_SCENE)
