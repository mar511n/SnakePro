extends SaveableTileMap
class_name SnakeDrawerTileMap

#const base_snake_path:String = "res://assets/Images/Snakes/"
#const snake_paths:Array = ["test.png","blue.png","red.png","yellow.png","pink.png","bot_black.png"]
#const source_idx:Array = [1, 2, 3, 4, 5, 6]
enum tile_type {
	HEAD,
	TAIL,
	BODY
}
const tile_atlas_coords:Array = [Vector2(12,8),Vector2i(0,0),Vector2i(6,0),Vector2i(12,0)]

# draws a snake, pos has tail at idx=0 and head at last idx
func draw_snake(snake_idx:int, layer:int, pos:Array)->void:
	var lpi:int = -1
	var npi:int = 1
	for cpi:int in range(len(pos)):
		lpi = cpi - 1
		npi = cpi + 1
		if lpi == -1:
			place_tile(tile_type.TAIL, pos[cpi], Vector2i.ZERO, pos[npi],snake_idx,layer)
		elif npi >= len(pos):
			place_tile(tile_type.HEAD, pos[cpi], pos[lpi], Vector2i.ZERO,snake_idx,layer)
		else:
			place_tile(tile_type.BODY, pos[cpi], pos[lpi], pos[npi],snake_idx,layer)

func place_tile(tile:tile_type, pos:Vector2i, lpos:Vector2i, npos:Vector2i, sn_idx:int, layer:int)->void:
	var sid:int = Global.snake_tile_files.keys()[sn_idx]#source_idx[sn_idx]
	var tac:int = 0
	var tacai:int = 0
	var diri:Vector2i = pos-lpos
	var diro:Vector2i = npos-pos
	if tile == tile_type.HEAD:
		tac = 0
		if diri.x > 0:
			tacai = 2
		elif diri.x < 0:
			tacai = 3
		elif diri.y < 0:
			tacai = 1
	elif tile == tile_type.TAIL:
		tac = 1
		if diro.x < 0:
			tacai = 2
		elif diro.y < 0:
			tacai = 3
		elif diro.y > 0:
			tacai = 1
	elif tile == tile_type.BODY:
		if diri == diro:
			tac = 2
			if diro.x < 0:
				tacai = 1
			elif diro.y < 0:
				tacai = 3
			elif diro.y > 0:
				tacai = 2
		else:
			tac = 3
			if diri.x < 0 and diro.y > 0:
				tacai = 1
			elif diri.x > 0 and diro.y < 0:
				tacai = 2
			elif diri.y > 0 and diro.x > 0:
				tacai = 3
			elif diri.y < 0 and diro.x < 0:
				tacai = 4
			elif diri.y > 0 and diro.x < 0:
				tacai = 5
			elif diri.x < 0 and diro.y < 0:
				tacai = 6
			elif diri.y < 0 and diro.x > 0:
				tacai = 7
	set_cell(layer,pos,sid,tile_atlas_coords[tac],tacai)

func reset(layers:int=1,layer_prop:Array=[])->void:
	for li:int in range(get_layers_count()):
		remove_layer(0)
	for layer_idx:int in range(layers):
		add_layer(-1)
		#set_layer_y_sort_enabled(layer_idx, true)
		if len(layer_prop) > layer_idx:
			if layer_prop[layer_idx].has("name"):
				set_layer_name(layer_idx,layer_prop[layer_idx]["name"])
			if layer_prop[layer_idx].has("modulate"):
				set_layer_modulate(layer_idx,layer_prop[layer_idx]["modulate"])
			if layer_prop[layer_idx].has("zindex"):
				set_layer_z_index(layer_idx,layer_prop[layer_idx]["zindex"])
			if layer_prop[layer_idx].has("enabled"):
				set_layer_enabled(layer_idx,layer_prop[layer_idx]["enabled"])

const expected_image_width:int = 800
const expected_image_height:int = 640
# creates snake_tileset.tres from snake_paths
func make_tileset()->void:
	var s_ids:Array = []
	tile_set = load(Global.snake_imgs_path+"snake_tileset_base.tres")
	for source_id in Global.snake_tile_files:
		var tss = tile_set.get_source(0).duplicate()
		var tex : Texture2D = load(Global.snake_imgs_path+Global.snake_tile_files[source_id])
		if tex.get_width() != expected_image_width or tex.get_height() != expected_image_height:
			var tex_img : Image = tex.get_image()
			tex_img.resize(expected_image_width,expected_image_height,Image.INTERPOLATE_LANCZOS)
			tex = ImageTexture.create_from_image(tex_img)
		tss.texture = tex
		var sid = tile_set.add_source(tss)
		s_ids.append(sid)
	tile_set.remove_source(0)
	ResourceSaver.save(tile_set, Global.snake_imgs_path+"snake_tileset.tres")
	print(s_ids)
	#set_cell(0, Vector2i(0,0), sid, Vector2i(0,0), 0)

func get_res_path()->String:
	return "res://scenes/snake_drawer.tscn"

func get_data()->Dictionary:
	var dic = super()
	return dic

func set_data(dic:Dictionary):
	super(dic)
