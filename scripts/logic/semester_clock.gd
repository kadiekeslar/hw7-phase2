class_name SemesterClock
extends RefCounted
## In-game time. The host advances it; clients mirror it from clock syncs.

var week_length_sec: float
var semester_weeks: int
var elapsed_sec: float = 0.0


func _init(p_week_length_sec: float, p_semester_weeks: int) -> void:
	week_length_sec = p_week_length_sec
	semester_weeks = p_semester_weeks


func advance(delta: float) -> void:
	elapsed_sec = minf(elapsed_sec + delta, total_sec())


func total_sec() -> float:
	return week_length_sec * semester_weeks


## Current week, 1-based. Stays on the last week once the semester is over.
func week() -> int:
	return mini(int(elapsed_sec / week_length_sec) + 1, semester_weeks)


func seconds_left_in_week() -> float:
	if is_over():
		return 0.0
	return week_length_sec * week() - elapsed_sec


func is_over() -> bool:
	return elapsed_sec >= total_sec()


func weeks_to_sec(weeks: float) -> float:
	return weeks * week_length_sec
