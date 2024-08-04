extends TileMap

const source_idx = 6
enum tile_type {
	HEAD,
	TAIL,
	BODY
}
const tile_atlas_coords:Array = [Vector2(12,8),Vector2i(0,0),Vector2i(6,0),Vector2i(12,0)]
var layers_used = [false]

func scale_to_tile_size(ts:Vector2)->void:
	scale = ts/Vector2(tile_set.tile_size)

func add_bot()->int:
	var li = layers_used.find(false)
	if li >= 0:
		layers_used[li] = true
		clear_layer(li)
		return li
	add_layer(-1)
	layers_used.append(true)
	return get_layers_count()-1

func remove_bot(li:int):
	layers_used[li] = false
	clear_layer(li)
	while len(layers_used) > 1 and layers_used[-1] == false:
		layers_used.pop_back()
		remove_layer(get_layers_count()-1)

# draws a snake, pos has tail at idx=0 and head at last idx
func draw_bot(layer:int, poss:Array)->void:
	clear_layer(layer)
	var lpi:int = -1
	var npi:int = 1
	for cpi:int in range(len(poss)):
		lpi = cpi - 1
		npi = cpi + 1
		if lpi == -1:
			place_tile(tile_type.TAIL, poss[cpi], Vector2i.ZERO, poss[npi],layer)
		elif npi >= len(poss):
			place_tile(tile_type.HEAD, poss[cpi], poss[lpi], Vector2i.ZERO,layer)
		else:
			place_tile(tile_type.BODY, poss[cpi], poss[lpi], poss[npi],layer)

func place_tile(tile:tile_type, pos:Vector2i, lpos:Vector2i, npos:Vector2i, layer:int)->void:
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
	set_cell(layer,pos,source_idx,tile_atlas_coords[tac],tacai)
