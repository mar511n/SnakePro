extends SaveableTileMap

const item_code_to_atlas_id = {
	"bot":2,
	"bot_g":3,
	"fart":4,
	"fart_g":5,
	"shot":6,
	"shot_g":7,
	"speed":8,
	"speed_g":9,
	"revive":10,
	"revive_g":11
	}
const unknown_item_source_id = 12

func scale_to_tile_size(ts:Vector2):
	scale = ts/Vector2(tile_set.tile_size)

func draw_items(poss:Array, codes:Array):
	for i in range(len(poss)):
		if item_code_to_atlas_id.has(codes[i]):
			set_cell(0,poss[i],item_code_to_atlas_id[codes[i]],Vector2i.ZERO,0)
		else:
			Global.Print("ERROR: trying to draw item with code %s"%codes[i])
			set_cell(0,poss[i],unknown_item_source_id,Vector2i.ZERO,0)

func clear_items():
	clear()

func get_res_path()->String:
	return "res://scenes/ModResources/item_map.tscn"

func get_data()->Dictionary:
	var dic = super()
	dic["scale"] = scale
	return dic

func set_data(dic:Dictionary):
	super(dic)
	scale = dic.get("scale", 1)
