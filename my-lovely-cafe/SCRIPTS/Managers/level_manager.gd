extends Node
@export var customers_required: int = 2
@export var spawn_interval_range: Vector2 = Vector2(8.0, 15.0)
@export var customer_spawn_point: Array[Node3D] = []

signal level_complete(won: bool)

#region ----VARIABLES----
var day_duration: float = 180.0
var day_timer: float
var spawn_timer: float
var day_active: bool = false
var current_customer: Node3D = null
var customers_served: int = 0
var money_earned_this_level: int = 0
#endregion ---------------

func _ready() -> void:
	_day_timer = day_duration
	_spawn_timer = randf_range(spawn_interval_range.x, spawn_interval_range.y)
	_day_active = true
	
func _process(delta: float) -> void:
	if not _day_active:
		return

	_day_timer -= delta
	if _day_timer <= 0.0:
		_end_day()
		return

	if _current_customer == null:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:

func _spawn_customer() -> void:
	var customer := customer_scene.instantiate()
	add_child(customer)
	customer.global_position = spawn_points.pick_random().global_position
	customer.order_result.connect(_on_customer_order_result)
	customer.place_order()
	_current_customer = customer

func _on_customer_order_result(correct: bool, payment: int) -> void:
	level_manager.register_order_result(correct, payment)
	_current_customer = null
	_spawn_timer = randf_range(spawn_interval_range.x, spawn_interval_range.y)

func _end_day() -> void:
	_day_active = false
	level_manager.end_level()

func register_order_result(correct: bool, payment: int) -> void:
	if correct:
		money_earned_this_level += payment
		customers_served += 1
	if customers_served >= customers_required:
		end_level()

func end_level() -> void:
	var did_win := customers_served >= customers_required
	GameManager.complete_level(money_earned_this_level, did_win)
	level_complete.emit(did_win)
