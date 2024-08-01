extends CheckButton
class_name LabeledCheckButton

func get_prop_value()->bool:
	return button_pressed

func set_prop_value(v:bool)->void:
	button_pressed = v
