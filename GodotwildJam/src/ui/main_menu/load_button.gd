extends Button

export(PackedScene) var level_to_load
export(NodePath) var scene_to_free_after_load


func _on_Button_pressed() -> void:
	var scene_tree: Node = get_tree().get_root()
	scene_tree.add_child(level_to_load.instance())
	get_node(scene_to_free_after_load).queue_free()
