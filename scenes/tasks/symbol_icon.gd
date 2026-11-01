class_name SymbolIcon
extends Control
## Draws one of the 8 Proof Chain symbols. Shapes differ, so color is a bonus.

const COLORS: Array[Color] = [
	Color("#b8432f"), Color("#3f6f9a"), Color("#4f7a3f"), Color("#a8741a"),
	Color("#7a4f8f"), Color("#2f7f7a"), Color("#a34f6f"), Color("#5a5a5a"),
]

var symbol: int = -1:
	set(value):
		symbol = value
		queue_redraw()


func _init(p_symbol: int = -1, min_size: Vector2 = Vector2(12, 12)) -> void:
	symbol = p_symbol
	custom_minimum_size = min_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if symbol < 0:
		return
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 1.0
	var col := COLORS[symbol]
	match symbol:
		0:  # circle
			draw_circle(c, r, col)
		1:  # triangle
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, r), c + Vector2(-r, r)]), col)
		2:  # square
			draw_rect(Rect2(c - Vector2(r, r) * 0.85, Vector2(r, r) * 1.7), col)
		3:  # diamond
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)
		4:  # star
			var points := PackedVector2Array()
			for i: int in 10:
				var radius := r if i % 2 == 0 else r * 0.45
				var angle := -PI / 2.0 + i * PI / 5.0
				points.append(c + Vector2(cos(angle), sin(angle)) * radius)
			draw_colored_polygon(points, col)
		5:  # cross
			var w := r * 0.6
			draw_rect(Rect2(c.x - w / 2.0, c.y - r, w, r * 2.0), col)
			draw_rect(Rect2(c.x - r, c.y - w / 2.0, r * 2.0, w), col)
		6:  # moon
			draw_circle(c, r, col)
			draw_circle(c + Vector2(r * 0.5, -r * 0.3), r * 0.8, Color("#fffaf0"))
		7:  # ring
			draw_arc(c, r * 0.75, 0.0, TAU, 24, col, r * 0.5)
