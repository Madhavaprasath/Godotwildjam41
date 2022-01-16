extends Node

var mouse_sensitivity := 0.001 # rads / pixel

func set_mouse_sentivity(percentage: float) -> void:
	mouse_sensitivity = 0.0005 * (1 + (percentage / 25.0))
