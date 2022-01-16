extends KinematicBody2D

export(int) var speed=500

enum states{
	Idle,
	Run,
	Attack,
	Aim,
	Harpoon
}
var direction_vector=Vector2()
var current_state=states.Idle
var velocity=Vector2()

func _ready():
	pass


func _physics_process(delta):
	handle_input(delta)
	

func handle_input(delta):
	var direction={
		"Left":Input.is_action_pressed("ui_left"),
		"Right":Input.is_action_pressed("ui_right"),
		"Up":Input.is_action_pressed("ui_up"),
		"Down":Input.is_action_pressed("ui_down")
	}
	direction_vector.x=-int(direction["Left"])+int(direction["Right"])
	direction_vector.y=int(direction["Down"])-int(direction["Up"])
	
	
	if (direction_vector.y!=0 && direction_vector.x!=0):
		direction_vector=Vector2()
		velocity=Vector2()
	else:
		velocity=lerp(velocity,direction_vector*speed,1-pow(0.001,delta))
	if(direction_vector==Vector2()):
		velocity.move_toward(Vector2(),500*delta)
	velocity=move_and_slide(velocity)
	

func fsm():
	match current_state:
		states.Idle:
			if direction_vector!=Vector2():
				return states.Run
		states.Run:
			if direction_vector==Vector2():
				return states.Idle
		




func is_aiming():
	return (Input.is_action_pressed("Right_click"))

