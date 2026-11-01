class_name CourseworkTracker
extends RefCounted
## Each assigned task counts once for each real student. TA cover never counts.

var task_ids: Array[StringName] = []
var _done: Dictionary[int, Dictionary] = {}


func _init(students: Array[int], tasks: Array[StringName]) -> void:
	task_ids.assign(tasks)
	for peer: int in students:
		_done[peer] = {}


func credit(peer: int, task_id: StringName) -> bool:
	if not _done.has(peer) or task_id not in task_ids or _done[peer].has(task_id):
		return false
	_done[peer][task_id] = true
	return true


func completed_for(peer: int) -> Array:
	return _done[peer].keys() if _done.has(peer) else []


func fraction() -> float:
	var total := _done.size() * task_ids.size()
	if total == 0:
		return 0.0
	var completed := 0
	for tasks: Dictionary in _done.values():
		completed += tasks.size()
	return float(completed) / total


func is_complete() -> bool:
	return fraction() >= 1.0
