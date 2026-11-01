class_name WinConditions
extends RefCounted
## Coursework takes priority when both goals are complete in the same check.

static func work_winner(coursework: float, grading: float) -> String:
	if coursework >= 1.0:
		return "students"
	if grading >= 1.0:
		return "ta"
	return ""
