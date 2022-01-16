extends KinematicBody

const MAX_ROTATION_VALUE := 1.2

export var character_speed := 10.0

onready var camera_pivot: Spatial = $CameraPivot

func _ready():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * Settings.mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * Settings.mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -MAX_ROTATION_VALUE, MAX_ROTATION_VALUE)


func _physics_process(_delta: float) -> void:
	var forward_axis = Input.get_axis("move_forward", "move_backwards")
	var horizontal_axis = Input.get_axis("move_left", "move_right")

	var velocity = (Vector3(horizontal_axis, 0, forward_axis).rotated(Vector3.UP, rotation.y)) * character_speed

	move_and_slide(velocity)
