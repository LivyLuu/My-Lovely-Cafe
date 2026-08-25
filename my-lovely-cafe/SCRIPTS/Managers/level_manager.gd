extends Node
class_name LevelManager
# update customer_location at the end of each task
# add point for
# add point for table and you can edit so its next available table later
# share time it took and score when you end level as well!
#region ----VARIABLES----
@export var customer_scene: PackedScene
@export var day_duration: float = 180.0
@export var customers_required: int = 2
@export var move_speed: float = 2.0
@export var arrival_threshold: float = 0.05
@export var possible_orders: Array[MenuItem] = []
@export var customer_path: Array[Node3D] = []
@export var spawn_interval_range: Vector2 = Vector2(8.0, 15.0)
#endregion --------------
#region ----RECIEVER----

#endregion --------------
#region --HIDDEN VARIABLES--
var day_timer: float
var spawn_timer: float
var day_active: bool = false
var current_customer: Node3D = null
var customer_location: int = 0
var customers_served: int = 0
var orders_correct: int = 0
var money_earned_this_level: int = 0
#endregion --------------
#region -----SIGNALS-----
#signal level_complete(won: bool)
#signal signal_customer_movement(customer_path: Array[Node3D] = []) 
#endregion --------------
func _ready() -> void:
	CoffeeMaker.brewing_started.connect(coffee_signal_recieved) 
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
	var spawn_tile := get_spawn_point()
	var customer := customer_scene.instantiate()
	add_child(customer)
	customer.global_position = spawn_tile.global_position
	customer.order_result.connect(_on_customer_order_result)
	customer.place_order(possible_orders)
	customer.state = customer.State.ENTERING
	customer.current_tile = spawn_tile
	var walk_path: Array[Node3D] = customer_path.filter(func(t): return t.tile_data.tile_type != CafeTile.TileType.SPAWN)
	customer.start_walking(walk_path)
	current_customer = customer
func get_spawn_point() -> Node3D:
	for tile in customer_path:
		if tile.tile_data.tile_type == CafeTile.TileType.SPAWN:
			return tile
	return null
#when customer reaches x point they change from entering to ordering
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

func coffee_signal_recieved() -> void:
	print("coffee signal recieved!")
	
func end_level() -> void:
	print("level ended!")
	#var did_win := orders_correct >= customers_required
	#GameManager.complete_level(money_earned_this_level, did_win)
	#level_complete.emit(did_win)
