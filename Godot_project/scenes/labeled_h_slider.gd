extends HSlider
class_name LabeledHSlider

func _on_value_changed(v:Variant)->void:
	#if name == "startSnakeLength":
	#	print("_on_value_changed %s" % v)
	$Label.text = str(v)

func get_prop_value()->Variant:
	return value

func set_prop_value(v:Variant)->void:
	#if name == "startSnakeLength":
	#	print("set_prop_value %s" % v)
	set_value_no_signal(v)
	_on_value_changed(v)
