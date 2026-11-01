class_name Prop
extends Node2D
## A placeholder piece of furniture drawn with shapes. Its position is the
## bottom-center of its footprint, so Y-sorting puts players behind or in front.

const WOOD := Color("#a07856")
const WOOD_DARK := Color("#7a5a44")
const OUTLINE := Color("#5e4636")

var kind: StringName
var footprint: Vector2
var height: float


func _init(p_kind: StringName, p_footprint: Vector2, p_height: float, layer: int) -> void:
	kind = p_kind
	footprint = p_footprint
	height = p_height
	if layer == 0:
		return
	var body := StaticBody2D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = footprint
	shape.shape = rect
	shape.position = Vector2(0, -footprint.y / 2.0)
	body.add_child(shape)
	add_child(body)


func _draw() -> void:
	var base := Rect2(-footprint.x / 2.0, -footprint.y, footprint.x, footprint.y)
	match kind:
		&"table":
			var top := Rect2(base.position - Vector2(0, height), Vector2(base.size.x, base.size.y))
			draw_rect(Rect2(base.position.x + 1, base.end.y - height, 2, height), WOOD_DARK)
			draw_rect(Rect2(base.end.x - 3, base.end.y - height, 2, height), WOOD_DARK)
			draw_rect(top.grow(1), OUTLINE)
			draw_rect(top, WOOD)
			draw_rect(Rect2(top.position, Vector2(top.size.x, 2)), WOOD.lightened(0.15))
		&"chair":
			draw_rect(Rect2(base.position.x, base.position.y - height, base.size.x, height), WOOD_DARK)
			draw_rect(base, WOOD)
		&"shelf":
			var face := Rect2(base.position.x, base.end.y - height, base.size.x, height)
			draw_rect(face.grow(1), OUTLINE)
			draw_rect(face, WOOD_DARK)
			var books := [Color("#b86b4b"), Color("#7f9a6a"), Color("#c9a76a"), Color("#8f7aa8"), Color("#6f8fa6")]
			var y := face.position.y + 6.0
			var row := 0
			while y < face.end.y - 6.0:
				var x := face.position.x + 2.0
				var i := row
				while x < face.end.x - 3.0:
					draw_rect(Rect2(x, y, 3, 7), books[i % books.size()])
					x += 4.0
					i += 3
				draw_rect(Rect2(face.position.x + 1, y + 7, face.size.x - 2, 1), OUTLINE)
				y += 10.0
				row += 1
			draw_rect(Rect2(face.position.x, face.position.y, face.size.x, 3), WOOD)
		&"couch":
			var color := Color("#9a86ae")
			var seat := Rect2(base.position.x, base.end.y - height, base.size.x, height)
			draw_rect(seat.grow(1), color.darkened(0.4))
			draw_rect(seat, color)
			draw_rect(Rect2(seat.position, Vector2(seat.size.x, 5)), color.darkened(0.15))
			draw_rect(Rect2(seat.position.x, seat.position.y, 3, seat.size.y), color.darkened(0.1))
			draw_rect(Rect2(seat.end.x - 3, seat.position.y, 3, seat.size.y), color.darkened(0.1))
		&"round_table":
			var r := footprint.x / 2.0
			var center := Vector2(0, -footprint.y / 2.0 - height)
			draw_rect(Rect2(-1, center.y, 2, height), WOOD_DARK)
			draw_set_transform(center, 0.0, Vector2(1.0, 0.6))
			draw_circle(Vector2.ZERO, r + 1, OUTLINE)
			draw_circle(Vector2.ZERO, r, WOOD)
			draw_set_transform(Vector2.ZERO)
		&"plant":
			draw_rect(Rect2(-5, -8, 10, 8), Color("#b86b4b"))
			draw_rect(Rect2(-5, -8, 10, 2), Color("#cf8a6a"))
			draw_circle(Vector2(0, -height), 7, Color("#6f8a5e"))
			draw_circle(Vector2(-4, -height + 4), 5, Color("#7f9a6a"))
			draw_circle(Vector2(4, -height + 3), 5, Color("#8aa676"))
		_:
			draw_rect(base, Color.MAGENTA)
