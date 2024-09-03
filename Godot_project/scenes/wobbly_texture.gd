extends TextureRect


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		material.set_shader_parameter("coff_angle", (get_global_mouse_position()-global_position-size/2.0).angle())
