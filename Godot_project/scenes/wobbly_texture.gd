extends TextureRect


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var diff = get_global_mouse_position()-global_position-size/2.0
		material.set_shader_parameter("coff_angle", diff.angle())
		var x = diff.length()
		var a = size.x*size.x/2
		var mul = 0.5*x*exp(-x*x/a)/sqrt(a/(2*exp(1)))
		material.set_shader_parameter("coff_mul", mul)
