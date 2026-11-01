extends GutTest

## A fake wall along x = 50 between y = 0 and y = 100.
func _wall(from: Vector2, to: Vector2) -> bool:
	if (from.x - 50.0) * (to.x - 50.0) >= 0.0:
		return false
	var t := (50.0 - from.x) / (to.x - from.x)
	var y := from.y + t * (to.y - from.y)
	return y >= 0.0 and y <= 100.0


func test_sees_targets_inside_radius() -> void:
	var targets := {2: Vector2(10, 10), 3: Vector2(20, 0)}
	var seen := LineOfSight.visible_ids(Vector2.ZERO, 30.0, targets, _wall)
	assert_eq(seen, [2, 3] as Array[int])


func test_ignores_targets_outside_radius() -> void:
	var targets := {2: Vector2(10, 0), 3: Vector2(40, 0)}
	var seen := LineOfSight.visible_ids(Vector2.ZERO, 30.0, targets, _wall)
	assert_eq(seen, [2] as Array[int])


func test_walls_block_sight() -> void:
	var targets := {2: Vector2(40, 50), 3: Vector2(60, 50)}
	var seen := LineOfSight.visible_ids(Vector2(30, 50), 100.0, targets, _wall)
	assert_eq(seen, [2] as Array[int])


func test_can_see_around_the_end_of_a_wall() -> void:
	var targets := {2: Vector2(60, 150)}
	var seen := LineOfSight.visible_ids(Vector2(30, 150), 100.0, targets, _wall)
	assert_eq(seen, [2] as Array[int])
