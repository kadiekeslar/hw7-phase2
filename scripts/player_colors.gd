class_name PlayerColors
extends RefCounted
## The 8 player outfit colors (Okabe-Ito colorblind-safe palette). These are the
## most saturated colors in the game; keep the environment softer than these.

const COLORS: Array[Color] = [
	Color("#e69f00"),  # Orange
	Color("#56b4e9"),  # Sky blue
	Color("#009e73"),  # Green
	Color("#f0e442"),  # Yellow
	Color("#0072b2"),  # Blue
	Color("#d55e00"),  # Vermillion
	Color("#cc79a7"),  # Pink
	Color("#1e1e24"),  # Black
]

const NAMES: Array[String] = ["Orange", "Sky", "Green", "Yellow", "Blue", "Red", "Pink", "Black"]


static func get_color(index: int) -> Color:
	return COLORS[clampi(index, 0, COLORS.size() - 1)]
