extends TileMap
class_name SaveableTileMap

func get_res_path()->String:
	return "res://scenes/Maps/empty_map.tscn"

func get_data()->Dictionary:
	var dic = {}
	dic["layerProps"] = []
	for layer in range(get_layers_count()):
		var cells = {}
		for cell in get_used_cells(layer):
			cells[cell] = [get_cell_source_id(layer,cell),get_cell_atlas_coords(layer,cell),get_cell_alternative_tile(layer,cell)]
		dic[layer] = cells
		dic["layerProps"].append([get_layer_name(layer),is_layer_enabled(layer),get_layer_modulate(layer),get_layer_z_index(layer)])
	return dic

func set_data(dic:Dictionary):
	for li:int in range(get_layers_count()):
		remove_layer(0)
	for layer in range(len(dic["layerProps"])):
		add_layer(layer)
		set_layer_name(layer,dic["layerProps"][layer][0])
		set_layer_enabled(layer,dic["layerProps"][layer][1])
		set_layer_modulate(layer,dic["layerProps"][layer][2])
		set_layer_z_index(layer,dic["layerProps"][layer][3])
		var cells = dic[layer]
		for cell in cells:
			set_cell(layer, cell, cells[cell][0], cells[cell][1], cells[cell][2])
