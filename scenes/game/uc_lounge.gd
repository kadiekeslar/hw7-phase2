class_name UcLounge
extends Node2D
## Rough placeholder of the UC 3rd floor study lounge: a window wall along the
## top, study tables to the west, and a tall bookshelf divider running down from
## the windows that blocks sight. The Problem Set whiteboard sits just east of
## the divider, so someone on the west side can be close without seeing it.

const TILE := 16
const SIZE := Vector2(36 * TILE, 22 * TILE)
const TOP_WALL := 3 * TILE
const SIDE_WALL := TILE

const FLOOR := Color("#cdb994")
const FLOOR_LINE := Color("#c2ad87")
const CARPET := Color("#a9b593")
const BRICK := Color("#b8704f")
const BRICK_DARK := Color("#9c5b40")
const CREAM := Color("#eadbb8")
const GLASS := Color("#a9c7c6")
const SHADOW := Color(0.36, 0.28, 0.45, 0.25)

## task_id -> station position.
var stations: Dictionary[StringName, Vector2] = {
	TaskRegistry.PROBLEM_SET: Vector2(350, 108),
}
var spawn_points: Array[Vector2] = []


## Adds walls and furniture to `world` (which Y-sorts), and draws the floor itself.
func build(world: Node2D, balance: GameBalance) -> void:
	z_index = -10
	for i: int in 8:
		spawn_points.append(Vector2(232 + (i % 4) * 24, 296 + floori(i / 4.0) * 20))

	# Outer walls block movement and sight.
	_wall(world, Rect2(0, 0, SIZE.x, TOP_WALL))
	_wall(world, Rect2(0, 0, SIDE_WALL, SIZE.y))
	_wall(world, Rect2(SIZE.x - SIDE_WALL, 0, SIDE_WALL, SIZE.y))
	_wall(world, Rect2(0, SIZE.y - TILE, SIZE.x, TILE))

	# The divider: a tall bookshelf from the windows down, blocking sight between
	# the two halves. The only way around is the gap at the bottom.
	_prop(world, &"shelf", Vector2(288, 208), Vector2(28, 160), 182, Player.WALL_LAYER)

	# West: study tables and chairs.
	for x: float in [88.0, 184.0]:
		_prop(world, &"table", Vector2(x, 132), Vector2(48, 14), 6, Player.FURNITURE_LAYER)
		for dx: float in [-14.0, 0.0, 14.0]:
			_prop(world, &"chair", Vector2(x + dx, 118), Vector2(8, 4), 6, 0)
			_prop(world, &"chair", Vector2(x + dx, 144), Vector2(8, 4), 6, 0)
	_prop(world, &"round_table", Vector2(96, 228), Vector2(24, 10), 8, Player.FURNITURE_LAYER)
	_prop(world, &"round_table", Vector2(184, 228), Vector2(24, 10), 8, Player.FURNITURE_LAYER)
	_prop(world, &"couch", Vector2(80, 324), Vector2(56, 10), 14, Player.FURNITURE_LAYER)

	# East: Problem Set table under the whiteboard, lounge seating.
	_prop(world, &"table", Vector2(350, 86), Vector2(56, 14), 6, Player.FURNITURE_LAYER)
	_prop(world, &"couch", Vector2(440, 324), Vector2(64, 10), 14, Player.FURNITURE_LAYER)
	_prop(world, &"round_table", Vector2(510, 236), Vector2(22, 10), 8, Player.FURNITURE_LAYER)

	# Plants stay at the edges so they never hide players in the open.
	for pos: Vector2 in [Vector2(28, 64), Vector2(548, 64), Vector2(28, 334), Vector2(548, 334)]:
		_prop(world, &"plant", pos, Vector2(10, 6), 14, Player.FURNITURE_LAYER)

	for task_id: StringName in stations:
		var station := TaskStation.new(task_id, balance.interact_radius_px)
		station.position = stations[task_id]
		world.add_child(station)


func _wall(world: Node2D, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Player.WALL_LAYER
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	body.add_child(shape)
	world.add_child(body)


func _prop(world: Node2D, kind: StringName, pos: Vector2, footprint: Vector2, height: float, layer: int) -> void:
	var prop := Prop.new(kind, footprint, height, layer)
	prop.position = pos
	world.add_child(prop)


func _draw() -> void:
	# Floor with a faint tile grid, and a soft carpet in the west study area.
	draw_rect(Rect2(Vector2.ZERO, SIZE), FLOOR)
	for x: int in range(0, int(SIZE.x), TILE):
		draw_line(Vector2(x, TOP_WALL), Vector2(x, SIZE.y), FLOOR_LINE)
	for y: int in range(TOP_WALL, int(SIZE.y), TILE):
		draw_line(Vector2(0, y), Vector2(SIZE.x, y), FLOOR_LINE)
	draw_rect(Rect2(40, 96, 200, 160), CARPET)
	draw_rect(Rect2(40, 96, 200, 160), CARPET.darkened(0.1), false)

	# Top wall: terracotta brick with a band of tall windows.
	draw_rect(Rect2(0, 0, SIZE.x, TOP_WALL), BRICK)
	for y: int in range(0, TOP_WALL, 6):
		draw_line(Vector2(0, y), Vector2(SIZE.x, y), BRICK_DARK)
	for x: int in range(40, int(SIZE.x) - 40, 64):
		if x >= 296 and x < 400:
			continue
		draw_rect(Rect2(x - 1, 5, 42, 36), CREAM)
		draw_rect(Rect2(x + 1, 7, 38, 32), GLASS)
		draw_rect(Rect2(x + 19, 7, 2, 32), CREAM)
		draw_rect(Rect2(x + 4, 10, 10, 2), GLASS.lightened(0.35))
	# Whiteboard over the Problem Set table.
	draw_rect(Rect2(317, 9, 66, 34), Color("#8c8c8c"))
	draw_rect(Rect2(319, 11, 62, 30), Color("#f4f1e8"))
	draw_line(Vector2(324, 18), Vector2(348, 18), Color("#6f8fa6"))
	draw_line(Vector2(324, 24), Vector2(364, 24), Color("#b86b4b"))
	draw_line(Vector2(324, 30), Vector2(342, 30), Color("#6f8fa6"))
	# Cream cap and a violet-tinted shadow where the wall meets the floor.
	draw_rect(Rect2(0, TOP_WALL - 3, SIZE.x, 3), CREAM)
	draw_rect(Rect2(0, TOP_WALL, SIZE.x, 6), SHADOW)

	# Side and bottom walls.
	draw_rect(Rect2(0, 0, SIDE_WALL, SIZE.y), BRICK_DARK)
	draw_rect(Rect2(SIZE.x - SIDE_WALL, 0, SIDE_WALL, SIZE.y), BRICK_DARK)
	draw_rect(Rect2(0, SIZE.y - TILE, SIZE.x, TILE), BRICK_DARK)
	draw_rect(Rect2(SIDE_WALL, SIZE.y - TILE, SIZE.x - 2 * SIDE_WALL, 2), CREAM)
