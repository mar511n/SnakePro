extends SaveableTileMap

const item_code_to_atlas_pos = {
	"bomb":Vector2i(0,0),
	"bomb_g":Vector2i(1,0),
	"bot":Vector2i(0,1),
	"bot_g":Vector2i(1,1),
	"fart":Vector2i(0,2),
	"fart_g":Vector2i(1,2),
	"shot":Vector2i(0,3),
	"shot_g":Vector2i(1,3),
	"speed":Vector2i(0,4),
	"speed_g":Vector2i(1,4),
	"revive":Vector2i(0,5),
	"revive_g":Vector2i(1,5)
	}
const unknown_item_source_id = 1

func scale_to_tile_size(ts:Vector2):
	scale = ts/Vector2(tile_set.tile_size)

func draw_items(poss:Array, codes:Array):
	for i in range(len(poss)):
		if item_code_to_atlas_pos.has(codes[i]):
			set_cell(0,poss[i],0,item_code_to_atlas_pos[codes[i]],0)
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
