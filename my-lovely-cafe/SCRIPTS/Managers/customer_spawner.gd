extends Node

@export var customer_scene: PackedScene
@export var customer_spawn_point: Array[Node3D] = []
@export var spawn_interval_range: Vector2 = Vector2(8.0, 15.0)
@export var day_duration: float = 180.0
@export var level_manager: %level_manager

var day_timer: float
var spawn_timer: float
var day_active: bool = false
var current_customer: Node3D = null

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
	customer.order_result.connect(_on_customer_order_result)
	customer.start_walking(customer_spawn_point)
	customer.place_order()
	current_customer = customer

func _on_customer_order_result(correct: bool, payment: int) -> void:
	level_manager.register_order_result(correct, payment)
	current_customer = null
	spawn_timer = randf_range(spawn_interval_range.x, spawn_interval_range.y)

func _end_day() -> void:
	day_active = false
	level_manager.end_level()
