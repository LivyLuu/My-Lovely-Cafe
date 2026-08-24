extends Node3D
class_name Customer

@onready var vision_area: Area3D = $VisionArea
@onready var look_at_modifier_3d: LookAtModifier3D = $Customer/Skeleton3D/LookAtModifier3D
enum State { ENTERING, WAITING_TO_ORDER, ORDERING, WAITING_FOR_ORDER, VERIFYING, LEAVING_HAPPY, LEAVING_UPSET }

signal order_placed(item: MenuItem)
signal order_result(correct: bool, payment: int)
signal customer_starts_walking
signal customer_stops_walking
signal waypoint_reached(marker: Node3D)
signal path_completed

# on ready/spawn get the "path" from the level manager in scene and walk it
var state: State = State.ENTERING
var desired_item: MenuItem
var customer_plans_to_walk: Array[Node3D] = []
var current_index: int = 0
var current_tile

@export var face_marker: Node3D
@export var move_speed: float = 2.0  # meters per second

func place_order(possible_orders: Array[MenuItem]) -> void:
	desired_item = possible_orders.pick_random()
	state = State.WAITING_TO_ORDER
	order_placed.emit(desired_item)

#func receive_item(served_item: MenuItem) -> void:
	#state = State.VERIFYING
	#var correct := served_item != null and served_item.id == desired_item.id
	#state = State.LEAVING_HAPPY if correct else State.LEAVING_UPSET
	#order_result.emit(correct, desired_item.price)

func start_walking(waypoints: Array[Node3D]) -> void:
	customer_plans_to_walk = waypoints
	current_index = 0
	customer_starts_walking.emit()
	_advance()
 
func _face_toward(target: Vector3) -> void:
	# Uses the Face marker as the source of truth for "which way is
	# forward" instead of assuming Godot's default -Z convention — so
	# it works correctly no matter how the character mesh is modeled.
	var current_dir := face_marker.global_position - global_position
	current_dir.y = 0.0
	current_dir = current_dir.normalized()
 
	var desired_dir := target - global_position
	desired_dir.y = 0.0
	desired_dir = desired_dir.normalized()
 
	if current_dir.length() > 0.001 and desired_dir.length() > 0.001:
		var angle := current_dir.signed_angle_to(desired_dir, Vector3.UP)
		rotate_y(angle)
 
func _advance() -> void:
	if current_index >= customer_plans_to_walk.size():
		customer_stops_walking.emit()
		path_completed.emit()
		return
 
	var next_tile = customer_plans_to_walk[current_index]
	var distance := global_position.distance_to(next_tile.global_position)
	var duration := distance / move_speed
 
	_face_toward(next_tile.global_position)
 
	var tween := create_tween()
	tween.tween_property(self, "global_position", next_tile.global_position, duration)
	await tween.finished
 
	current_tile = next_tile
	current_index += 1
	waypoint_reached.emit(next_tile)
 
	if next_tile.tile_data.tile_type == CafeTile.TileType.ORDER:
		state = State.ORDERING
		customer_stops_walking.emit()
		return  # paused here — level manager / order system resumes it later
 
	_advance()


func _on_check_player_timer_timeout() -> void:
	var player = get_tree().get_first_node_in_group("player_body")
	var bodies = vision_area.get_overlapping_bodies()
	if player in bodies:
		look_at_modifier_3d.target_node = player.get_path()
		look_at_modifier_3d.active = true
	else:
		look_at_modifier_3d.active = false
