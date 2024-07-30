extends HSlider

func _on_value_changed(v):
	#if name == "startSnakeLength":
	#	print("_on_value_changed %s" % v)
	$Label.text = str(v)

func get_prop_value():
	return value

func set_prop_value(v):
	#if name == "startSnakeLength":
	#	print("set_prop_value %s" % v)
	set_value_no_signal(v)
	_on_value_changed(v)
