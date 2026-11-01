class_name TaskLogic
extends RefCounted
## Host-side rules for one task minigame. Each task pairs a TaskLogic subclass
## (rules, on the host) with a Minigame scene (UI, on each player's client).
## Players are identified by seat: 0 .. seat_count - 1.

var seat_count: int = 1


## Everything the player in `seat` may know right now. Sent to that player's client.
func payload_for(_seat: int, _now: float) -> Dictionary:
	return {}


## Applies an action from a seat. Returns feedback for that seat only (may be
## empty). After every action the host resends payload_for() to all seats.
func handle_action(_seat: int, _action: Dictionary, _now: float) -> Dictionary:
	return {}


func is_complete() -> bool:
	return false
