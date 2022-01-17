extends KinematicBody

const MAX_ROTATION_VALUE := 1.2
const HARPOON_ARRIVED_DELTA := 1.5
const GRAVITY := 9.7

export var character_speed := 10.0
export var grappling_speed_percentage_per_frame := 0.1
export var jump_length := 30.0
export var jump_height := 15.0
export var jump_accel := 1.0
export var jump_decay := 0.01

enum States {Idle, Run, Attack, Harpoon, Climbing, Jumping}

var current_state = States.Idle

var forward_axis_input
var horizontal_axis_input
var jump_direction: Vector3 = Vector3()


var is_attacking := false
var is_harpooning := false
var is_climbing := false

var current_jump_strength := 0.0

var harpooned_point := Vector3()

onready var camera_pivot: Spatial = $CameraPivot
onready var harpoon_raycast: RayCast = $CameraPivot/HarpoonRaycast

onready var floor_cast: RayCast = $FloorCast

func _ready():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * Settings.mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * Settings.mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -MAX_ROTATION_VALUE, MAX_ROTATION_VALUE)
	if current_state in [States.Idle, States.Run, States.Jumping]:
		if Input.is_action_just_pressed("attack")&&!is_attacking&&!is_harpooning:
			is_attacking=true
			#animation_player play a attack animation and connect a signal
			#animation finshed and is_attacking to false
			is_attacking=false
		elif Input.is_action_just_pressed("harpoon"):
			_harpoon()
	if current_state in [States.Harpoon, States.Climbing]:
		if Input.is_action_just_pressed("jump"):
			_jump()


func _physics_process(_delta: float) -> void:
	handle_input()
	var state=fsm()
	if state!=null:
		current_state=state
	
	print(current_state)
	
	var velocity = Vector3()
	
	match (current_state):
		States.Run:
			velocity = Vector3(horizontal_axis_input, -GRAVITY, forward_axis_input).rotated(Vector3.UP, rotation.y) * character_speed
		States.Harpoon:
			transform.origin = lerp(transform.origin, harpooned_point, grappling_speed_percentage_per_frame)
			if (transform.origin.distance_to(harpooned_point) < HARPOON_ARRIVED_DELTA):
				is_harpooning = false
				# TODO: check for wall!
				is_climbing = true
		States.Jumping:
			velocity = jump_direction * jump_length * current_jump_strength
			velocity.y = -GRAVITY + jump_height * current_jump_strength
			current_jump_strength -= jump_decay
			if current_jump_strength <= 0.0:
				current_jump_strength = 0.0
			
	move_and_slide(velocity)


func handle_input():
	# TODO: is this needed?
	if current_state != States.Harpoon:
		forward_axis_input = Input.get_axis("move_forward", "move_backwards")
		horizontal_axis_input = Input.get_axis("move_left", "move_right")


func fsm():
	match current_state:
		States.Idle:
			return compute_movement_state()
		States.Run:
			return compute_movement_state()
		States.Attack:
			if !is_attacking:
				return States.Idle
		States.Harpoon:
			if !is_harpooning:
				if is_climbing:
					return States.Climbing
				else:
					return States.Idle
		States.Climbing:
			if current_jump_strength > 0.0:
				return States.Jumping
			else:
				return States.Climbing
		States.Jumping:
			if _is_touching_floor():
				return States.Idle
			else:
				return States.Jumping
	return null


func compute_movement_state():
	if current_jump_strength > 0.0:
		return States.Jumping
	if forward_axis_input == 0.0 and horizontal_axis_input == 0.0:
		return States.Idle
	elif forward_axis_input != 0.0 and horizontal_axis_input != 0.0:
		return States.Run
	if is_attacking:
		return States.Attack
	if is_harpooning:
		return States.Harpoon
	if is_climbing:
		return States.Climbing
	


func _harpoon() -> void:
	var collision_point := harpoon_raycast.get_collision_point()
	if collision_point != Vector3.ZERO:
		is_harpooning = true
		is_climbing = false
		current_jump_strength = 0.0
		current_state = States.Harpoon
		harpooned_point = collision_point
		print(transform.origin)
		print(harpooned_point)


func _jump() -> void:
	is_climbing = false
	is_harpooning = false
	current_jump_strength = 1.0
	# TODO: jump direction dependant on Input
	jump_direction = Vector3(0, 1, -1).normalized().rotated(Vector3.UP, rotation.y)


func _is_touching_floor() -> bool:
	return floor_cast.is_colliding()
