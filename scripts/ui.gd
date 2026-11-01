class_name UI
extends RefCounted
## Small helpers for building placeholder UI in code.

const INK := Color("#3b2f2a")
const CREAM := Color("#f3e8d2")
const MUTED := Color("#7a6a5c")
const ALERT := Color("#b8432f")
const BACKDROP := Color("#e9dcc0")


static func label(text: String, size: int = 8, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func centered_label(text: String, size: int = 8, color: Color = INK) -> Label:
	var l := label(text, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func button(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(on_pressed)
	return b


static func vbox(separation: int = 4) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


static func hbox(separation: int = 4) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


## A panel that sizes to its content, holding a VBox. Returns the VBox.
static func panel_with_vbox(parent: Control, separation: int = 4) -> VBoxContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	var box := vbox(separation)
	panel.add_child(box)
	return box


## A full-screen container that centers its child.
static func center_screen(parent: Node) -> CenterContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center)
	return center


static func color_swatch(color: Color, size: Vector2 = Vector2(8, 8)) -> ColorRect:
	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = size
	return swatch
