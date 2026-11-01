class_name ReportTracker
extends RefCounted
## The TA's limits on removing students: one pending report at a time, pending
## reports expire, and reports and captures share one cooldown.
## All times are in-game seconds from SemesterClock.elapsed_sec.

var expiry_sec: float
var cooldown_sec: float
var pending_ids: Array[int] = []
var pending_created_sec: float = 0.0
var cooldown_until_sec: float = 0.0


func _init(p_expiry_sec: float, p_cooldown_sec: float) -> void:
	expiry_sec = p_expiry_sec
	cooldown_sec = p_cooldown_sec


func has_pending() -> bool:
	return not pending_ids.is_empty()


func on_cooldown(now: float) -> bool:
	return now < cooldown_until_sec


func cooldown_remaining(now: float) -> float:
	return maxf(0.0, cooldown_until_sec - now)


func expires_in(now: float) -> float:
	return maxf(0.0, pending_created_sec + expiry_sec - now)


func can_create_report(now: float) -> bool:
	return not has_pending() and not on_cooldown(now)


func create_report(now: float, ids: Array[int]) -> bool:
	if not can_create_report(now) or ids.is_empty():
		return false
	pending_ids = ids.duplicate()
	pending_created_sec = now
	return true


## Drops the pending report if it has expired. Returns true if it just expired.
func expire_if_due(now: float) -> bool:
	if has_pending() and expires_in(now) <= 0.0:
		pending_ids.clear()
		return true
	return false


func file_report(now: float, target: int) -> bool:
	if not has_pending() or target not in pending_ids or expires_in(now) <= 0.0:
		return false
	pending_ids.clear()
	cooldown_until_sec = now + cooldown_sec
	return true


func can_capture(now: float) -> bool:
	return not on_cooldown(now)


## A capture uses the TA's one removal, so it also discards any pending report.
func record_capture(now: float) -> void:
	pending_ids.clear()
	cooldown_until_sec = now + cooldown_sec


## Removes a student who left the game from the pending report.
func forget_student(id: int) -> void:
	pending_ids.erase(id)
