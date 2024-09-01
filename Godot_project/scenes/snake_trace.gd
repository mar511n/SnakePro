extends Line2D

func get_res_path()->String:
	return "res://scenes/snake_trace.tscn"

func get_data()->Dictionary:
	var dic = {}
	dic["name"] = "snake_trace_"+get_parent().name
	dic["pnts"] = points
	return dic

func set_data(dic:Dictionary):
	name = dic.get("name", "snake_trace")
	points = dic.get("pnts",[])
