extends Node

signal level_complete(won: bool)

#region ----VARIABLES----
@export var customers_required: int = 2
@export var spawn_interval_range: Vector2 = Vector2(8.0, 15.0)
@export var customer_spawn_point: Array[Node3D] = []
@export var customer_scene: PackedScene
@export var day_duration: float = 180.0
#endregion --------------

var day_timer: float
var spawn_timer: float
var day_active: bool = false
var current_customer: Node3D = null
var customers_served: int = 0
var orders_correct: int = 0
var money_earned_this_level: int = 0

func _ready() -> void:
	day_timer = day_duration
	spawn_timer = randf_range(spawn_interval_range.x, spawn_interval_range.y)
	day_active = true

func _process(delta: float) -> void:
	if not day_active:
		return
	day_timer -= delta
	if day_timer <= 0.0:
		_end_day()
		return
	if current_customer == null:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			_spawn_customer()

func _spawn_customer() -> void:
	var customer := customer_scene.instantiate()
	add_child(customer)
	customer.global_position = customer_spawn_point.pick_random().global_position
	customer.order_result.connect(_on_customer_order_result)
	customer.place_order()
	current_customer = customer

func _on_customer_order_result(correct: bool, payment: int) -> void:
	register_order_result(correct, payment)
	current_customer = null
	spawn_timer = randf_range(spawn_interval_range.x, spawn_interval_range.y)

func _end_day() -> void:
	day_active = false
	end_level()

func register_order_result(correct: bool, payment: int) -> void:
	customers_served += 1
	if correct:
		orders_correct += 1
		money_earned_this_level += payment

func end_level() -> void:
	var did_win := orders_correct >= customers_required
	GameManager.complete_level(money_earned_this_level, did_win)
	level_complete.emit(did_win)
