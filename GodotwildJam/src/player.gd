extends KinematicBody

const MAX_ROTATION_VALUE := 1.2

export var character_speed := 10.0

onready var camera_pivot: Spatial = $CameraPivot


enum States{Idle,Run,Aim,Attack,Harpoon}
var current_state=States.Idle
var velocity=Vector3()

var is_attacking=false
var is_harpooning=false
var is_aiming=false

func _ready():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * Settings.mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * Settings.mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -MAX_ROTATION_VALUE, MAX_ROTATION_VALUE)
	if current_state in [States.Idle,States.Run]:
		if event.is_action_pressed("Left_Click")&&!is_attacking&&!is_harpooning:
			is_attacking=true
			print(is_attacking,is_harpooning)
			#animation_player play a attack animation and connect a signal
			#animation finshed and is_attacking to false
			is_attacking=false
	if current_state in [States.Aim] && event.is_action_pressed("Left_Click"):
		
		is_harpooning=true
		print(is_harpooning)
		is_harpooning=false
func _physics_process(_delta: float) -> void:
	handle_input()
	is_aiming()
	var state=fsm()
	if state!=null:
		current_state=state
		print(current_state)

func handle_input():
	var forward_axis = Input.get_axis("move_forward", "move_backwards")
	var horizontal_axis = Input.get_axis("move_left", "move_right")
	velocity = (Vector3(horizontal_axis, 0, forward_axis).rotated(Vector3.UP, rotation.y)) * character_speed
	move_and_slide(velocity)


func fsm():
	match current_state:
		States.Idle:
			if velocity!=Vector3():
				return States.Run
			if is_attacking:
				return States.Attack
			if is_harpooning:
				return States.Harpoon
			if is_aiming:
				return States.Aim
		States.Run:
			if velocity==Vector3():
				return States.Idle
			if is_attacking:
				return States.Attack
			if is_harpooning:
				return States.Harpoon
			if is_aiming:
				return States.Aim
		States.Attack:
			if !is_attacking:
				return States.Idle
		States.Aim:
			if !is_aiming:
				return States.Idle
		States.Harpoon:
			if !is_harpooning:
				return States.Idle
	return null

func is_aiming():
	if current_state in [States.Idle,States.Run]:
		if(Input.is_action_pressed("Right_Click")):
			is_aiming=true
	if Input.is_action_just_released("Right_Click"):
		is_aiming=false
