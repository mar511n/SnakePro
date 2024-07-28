extends TileMap

const base_snake_path = "res://assets/Images/Snakes/"
const snake_paths = ["test.png","blue.png","red.png","yellow.png","pink.png","bot_black.png"]
const source_idx = [1, 2, 3, 4, 5, 6]
enum tile_type {
	HEAD,
	TAIL,
	BODY
}
const tile_atlas_coords = [Vector2(12,8),Vector2i(0,0),Vector2i(6,0),Vector2i(12,0)]

func _ready():
	pass
	#reset(1)
	#draw_snake(0,0,[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2)])
	#make_tileset()

# draws a snake, pos has tail at idx=0 and head at last idx
func draw_snake(snake_idx:int, layer:int, pos):
	var lpi = -1
	var npi = 1
	for cpi in range(len(pos)):
		lpi = cpi - 1
		npi = cpi + 1
		if lpi == -1:
			place_tile(tile_type.TAIL, pos[cpi], Vector2i.ZERO, pos[npi],snake_idx,layer)
		elif npi >= len(pos):
			place_tile(tile_type.HEAD, pos[cpi], pos[lpi], Vector2i.ZERO,snake_idx,layer)
		else:
			place_tile(tile_type.BODY, pos[cpi], pos[lpi], pos[npi],snake_idx,layer)

func place_tile(tile:tile_type, pos:Vector2i, lpos:Vector2i, npos:Vector2i, sn_idx:int, layer:int):
	var sid = source_idx[sn_idx]
	var tac = 0
	var tacai = 0
	var diri = pos-lpos
	var diro = npos-pos
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

func reset(layers=1,layer_prop=[]):
	for li in range(get_layers_count()):
		remove_layer(0)
	for layer_idx in range(layers):
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

const expected_image_width = 800
const expected_image_height = 640
# creates snake_tileset.tres from snake_paths
func make_tileset():
	var s_ids = []
	tile_set = load(base_snake_path+"snake_tileset_base.tres")
	for snakep in snake_paths:
		var tss = tile_set.get_source(0).duplicate()
		var tex : Texture2D = load(base_snake_path+snakep)
		if tex.get_width() != expected_image_width or tex.get_height() != expected_image_height:
			var tex_img : Image = tex.get_image()
			tex_img.resize(expected_image_width,expected_image_height,Image.INTERPOLATE_LANCZOS)
			tex = ImageTexture.create_from_image(tex_img)
		tss.texture = tex
		var sid = tile_set.add_source(tss)
		s_ids.append(sid)
	tile_set.remove_source(0)
	ResourceSaver.save(tile_set, base_snake_path+"snake_tileset.tres")
	print(s_ids)
	#set_cell(0, Vector2i(0,0), sid, Vector2i(0,0), 0)
