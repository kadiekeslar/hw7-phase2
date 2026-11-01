class_name GradingTask
extends TaskLogic
## Timed work; a client's early submit cannot bypass the host's timer.

var _duration: float
var _started_at: float = -1.0
var _complete: bool = false


func _init(duration: float) -> void:
	_duration = maxf(0.1, duration)


func payload_for(_seat: int, now: float) -> Dictionary:
	if _started_at < 0:
		_started_at = now
	return {"kind": "grading", "seconds_left": maxf(0.0, _duration - (now - _started_at)),
		"duration": _duration, "complete": _complete}


func handle_action(seat: int, action: Dictionary, now: float) -> Dictionary:
	if seat != 0 or _started_at < 0 or not action.get("submit", false) == true:
		return {}
	if now - _started_at < _duration:
		return {"message": "Keep grading until the timer finishes."}
	_complete = true
	return {}


func is_complete() -> bool:
	return _complete
