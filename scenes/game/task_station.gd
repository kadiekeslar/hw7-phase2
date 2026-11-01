class_name TaskStation
extends Node2D
## Where a task can be done. Glows with a slow pulse so players can find it.

var task_id: StringName
var radius: float = 24.0


func _init(p_task_id: StringName, p_radius: float) -> void:
	task_id = p_task_id
	radius = p_radius
	z_index = -1
	var label := UI.centered_label("Grade papers" if TaskRegistry.is_grading(task_id) else ("Problem Set (2)" if task_id == TaskRegistry.PROBLEM_SET else "Programming (1)"), 8)
	label.position = Vector2(-44, 12)
	label.custom_minimum_size.x = 88
	add_child(label)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var tint := Color("#dd8474") if TaskRegistry.is_grading(task_id) else Color("#ffe080")
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 400.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, radius, Color(tint, 0.10 + 0.12 * pulse))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(tint, 0.35 + 0.35 * pulse), 1.0)
	draw_set_transform(Vector2.ZERO)
