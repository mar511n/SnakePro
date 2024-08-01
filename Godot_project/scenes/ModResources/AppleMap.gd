extends TileMap

func scale_to_tile_size(ts:Vector2)->void:
	scale = ts/Vector2(tile_set.tile_size)

func draw_apples(poss:Array, ghost_apple:bool=false)->void:
	for pos:Vector2i in poss:
		if ghost_apple:
			set_cell(0,pos,1,Vector2i(0,0))
		else:
			set_cell(0,pos,0,Vector2i(0,0))

func clear_apples()->void:
	clear()
