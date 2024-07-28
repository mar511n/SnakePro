extends HSlider

func _on_value_changed(v):
	$Label.text = str(v)

func get_prop_value():
	return value

func set_prop_value(v):
	value = v
