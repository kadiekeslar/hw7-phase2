class_name Minigame
extends Control
## The interface every task minigame scene implements, so new tasks plug in
## without touching core code. The minigame only draws and sends actions;
## the host's TaskLogic decides what happens.

## The player did something; the game forwards it to the host.
signal action_requested(action: Dictionary)
## The player pressed Esc to leave the task.
signal cancel_requested

var task_id: StringName
var partner_names: Array[String] = []


## Called once with the host's first payload for this player.
func start(_payload: Dictionary) -> void:
	pass


## Called whenever the host sends a new payload, plus any feedback for this player.
func apply_update(_payload: Dictionary, _feedback: Dictionary) -> void:
	pass


## 0.0 .. 1.0.
func progress() -> float:
	return 0.0


## The host says the task is done.
func complete() -> void:
	pass


## The task ended without finishing (a partner left, a capture, and so on).
func cancel() -> void:
	pass


func collaborator_count() -> int:
	return TaskRegistry.player_count(task_id)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		cancel_requested.emit()
