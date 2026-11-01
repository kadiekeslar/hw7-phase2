class_name LineOfSight
extends RefCounted
## What the TA can see: inside a fixed radius, with walls blocking sight.
## Runs on the host only, never trusted from a client.


## Returns the ids in `targets` (id -> position) visible from `viewer`.
## `is_blocked` is called as is_blocked(from: Vector2, to: Vector2) -> bool.
static func visible_ids(viewer: Vector2, radius: float, targets: Dictionary, is_blocked: Callable) -> Array[int]:
	var seen: Array[int] = []
	for id: int in targets:
		var pos: Vector2 = targets[id]
		if viewer.distance_to(pos) <= radius and not is_blocked.call(viewer, pos):
			seen.append(id)
	seen.sort()
	return seen


## A blocker that raycasts against the given physics layers (the wall layer).
static func raycast_blocker(space: PhysicsDirectSpaceState2D, mask: int) -> Callable:
	return func(from: Vector2, to: Vector2) -> bool:
		var query := PhysicsRayQueryParameters2D.create(from, to, mask)
		return not space.intersect_ray(query).is_empty()
