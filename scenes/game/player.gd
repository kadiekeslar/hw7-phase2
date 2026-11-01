class_name Player
extends CharacterBody2D
## One student or TA in the room. The host moves every player from their
## inputs and syncs positions at ~20 Hz. The owning client predicts its own
## movement and replays unconfirmed inputs when the host's position arrives;
## everyone else's character is drawn slightly in the past and interpolated.

const WALL_LAYER := 2
const FURNITURE_LAYER := 4
## Inputs resent in every packet, so one lost packet doesn't lose movement.
const INPUT_REDUNDANCY := 3
## Cap on queued inputs on the host, so a lagging client can't bank movement.
const MAX_QUEUED_INPUTS := 8

enum Facing { DOWN, UP, LEFT, RIGHT }

var peer_id: int = 0
var display_name: String = ""
var color: Color = Color.WHITE
var speed: float = 64.0
var interpolation_delay_ms: int = 100

## Synced from the host.
var sync_position: Vector2 = Vector2.ZERO
var last_input_seq: int = 0
var sync_facing: int = Facing.DOWN

## Set locally when UI (a puzzle, a popup) should stop this player's movement.
var input_blocked: bool = false
## Host only: the host ignores this player's movement while true.
var frozen: bool = false
var facing: int = Facing.DOWN

var _sync: MultiplayerSynchronizer
var _name_tag: Label
# Owning client: inputs not yet confirmed by the host, as [seq, Vector2].
var _input_seq: int = 0
var _unconfirmed: Array[Array] = []
# Host: queued inputs from the owning client, as [seq, Vector2].
var _queued: Array[Array] = []
# Other clients: [ticks_msec, position] snapshots for interpolation.
var _snapshots: Array[Array] = []


func setup(p_peer_id: int, p_name: String, p_color: Color, balance: GameBalance) -> void:
	peer_id = p_peer_id
	display_name = p_name
	color = p_color
	speed = balance.move_speed_px
	interpolation_delay_ms = balance.interpolation_delay_ms
	name = "P%d" % peer_id
	collision_layer = 1
	collision_mask = WALL_LAYER | FURNITURE_LAYER
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	var feet := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 5)
	feet.shape = shape
	add_child(feet)

	# Name tags are always shown: a small dark backing keeps them readable.
	_name_tag = UI.centered_label(display_name, 8, Color.WHITE)
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(0.16, 0.12, 0.2, 0.7)
	backing.set_corner_radius_all(2)
	backing.content_margin_left = 2
	backing.content_margin_right = 2
	_name_tag.add_theme_stylebox_override("normal", backing)
	_name_tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_name_tag)
	_name_tag.reset_size()
	_name_tag.position = Vector2(-_name_tag.size.x / 2.0, -31)

	_sync = MultiplayerSynchronizer.new()
	_sync.name = "Sync"
	_sync.root_path = NodePath("..")
	_sync.replication_interval = 1.0 / balance.position_sync_hz
	_sync.public_visibility = false
	var config := SceneReplicationConfig.new()
	for prop: String in ["sync_position", "last_input_seq", "sync_facing"]:
		var path := NodePath(".:" + prop)
		config.add_property(path)
		config.property_set_spawn(path, false)
		config.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	_sync.replication_config = config
	_sync.synchronized.connect(_on_synchronized)
	add_child(_sync)


func _ready() -> void:
	# The host only syncs to peers that have loaded the room (see show_to_peer).
	# Visibility also gates RPCs, so clients keep it open to send their inputs.
	_sync.public_visibility = not multiplayer.is_server()


func place_at(pos: Vector2) -> void:
	position = pos
	sync_position = pos


## Host: starts sending this player's position to a peer once it has loaded.
func show_to_peer(peer: int) -> void:
	_sync.set_visibility_for(peer, true)


func is_local() -> bool:
	return peer_id == multiplayer.get_unique_id()


func _physics_process(_delta: float) -> void:
	if multiplayer.is_server():
		if is_local():
			_step(Vector2.ZERO if frozen else _read_input())
		else:
			_apply_queued_inputs()
		sync_position = position
		sync_facing = facing
	elif is_local():
		_predict_and_send()


func _process(_delta: float) -> void:
	if not multiplayer.is_server() and not is_local():
		_interpolate()
	queue_redraw()


func _read_input() -> Vector2:
	if input_blocked:
		return Vector2.ZERO
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO and DevTools.enabled:
		dir = DevTools.bot_move_dir(position)
	return dir


func _step(dir: Vector2) -> void:
	dir = dir.limit_length(1.0)
	velocity = dir * speed
	move_and_slide()
	if dir != Vector2.ZERO:
		if absf(dir.x) > absf(dir.y):
			facing = Facing.RIGHT if dir.x > 0 else Facing.LEFT
		else:
			facing = Facing.DOWN if dir.y > 0 else Facing.UP


# --- Owning client ---------------------------------------------------------

func _predict_and_send() -> void:
	var dir := _read_input()
	_input_seq += 1
	_unconfirmed.append([_input_seq, dir])
	_step(dir)
	var dirs := PackedVector2Array()
	for entry: Array in _unconfirmed.slice(-INPUT_REDUNDANCY):
		dirs.append(entry[1])
	_rq_input.rpc_id(NetworkService.HOST_ID, _input_seq, dirs)


func _reconcile() -> void:
	while not _unconfirmed.is_empty() and _unconfirmed[0][0] <= last_input_seq:
		_unconfirmed.pop_front()
	var predicted_facing := facing
	position = sync_position
	for entry: Array in _unconfirmed:
		_step(entry[1])
	facing = predicted_facing


# --- Host ------------------------------------------------------------------

## `dirs` are the inputs for seqs (newest_seq - dirs.size() + 1) .. newest_seq.
@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rq_input(newest_seq: int, dirs: PackedVector2Array) -> void:
	# Packets can still arrive while the scene is being torn down.
	if not is_inside_tree() or not multiplayer.is_server() or multiplayer.get_remote_sender_id() != peer_id:
		return
	var last_known: int = _queued[-1][0] if not _queued.is_empty() else last_input_seq
	for i: int in dirs.size():
		var seq := newest_seq - dirs.size() + 1 + i
		if seq > last_known:
			_queued.append([seq, dirs[i]])
	while _queued.size() > MAX_QUEUED_INPUTS:
		var dropped: Array = _queued.pop_front()
		last_input_seq = dropped[0]


func _apply_queued_inputs() -> void:
	# Normally one input per tick; two lets the host catch up after jitter.
	var budget := 2 if _queued.size() > 2 else 1
	while budget > 0 and not _queued.is_empty():
		var entry: Array = _queued.pop_front()
		_step(Vector2.ZERO if frozen else entry[1])
		last_input_seq = entry[0]
		budget -= 1


# --- Other clients ---------------------------------------------------------

func _on_synchronized() -> void:
	if is_local():
		_reconcile()
		return
	facing = sync_facing
	_snapshots.append([Time.get_ticks_msec(), sync_position])
	if _snapshots.size() > 20:
		_snapshots.pop_front()


func _interpolate() -> void:
	if _snapshots.is_empty():
		position = sync_position
		return
	var render_time := Time.get_ticks_msec() - interpolation_delay_ms
	while _snapshots.size() >= 2 and _snapshots[1][0] <= render_time:
		_snapshots.pop_front()
	if _snapshots.size() < 2 or render_time <= _snapshots[0][0]:
		position = _snapshots[0][1]
		return
	var a: Array = _snapshots[0]
	var b: Array = _snapshots[1]
	var t := float(render_time - a[0]) / float(b[0] - a[0])
	position = (a[1] as Vector2).lerp(b[1], clampf(t, 0.0, 1.0))


# --- Placeholder drawing ---------------------------------------------------

func _draw() -> void:
	var outline := color.darkened(0.45)
	# Soft violet shadow at the feet.
	draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 7.0, Color(0.36, 0.28, 0.45, 0.35))
	draw_set_transform(Vector2.ZERO)
	# Body: a rounded bean, about 12x18 px.
	var body := Rect2(-6, -18, 12, 18)
	draw_rect(body.grow(1), outline)
	draw_rect(body, color)
	draw_rect(Rect2(-6, -18, 12, 1), color.lightened(0.25))
	# Face patch shows which way the player faces.
	var face := color.lightened(0.55)
	match facing:
		Facing.DOWN:
			draw_rect(Rect2(-4, -15, 8, 5), face)
		Facing.LEFT:
			draw_rect(Rect2(-6, -15, 5, 5), face)
		Facing.RIGHT:
			draw_rect(Rect2(1, -15, 5, 5), face)
		Facing.UP:
			draw_rect(Rect2(-5, -6, 10, 3), color.darkened(0.2))
