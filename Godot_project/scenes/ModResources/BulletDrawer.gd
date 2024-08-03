extends TileMap

func scale_to_tile_size(ts:Vector2)->void:
	scale = ts/Vector2(tile_set.tile_size)

func draw_bullet(pos:Vector2i, dir:Vector2i)->void:
	if dir == Vector2i.LEFT:
		set_cell(0,pos,0,Vector2i.ZERO,2)
	elif dir == Vector2i.RIGHT:
		set_cell(0,pos,0,Vector2i.ZERO,3)
	elif dir == Vector2i.UP:
		set_cell(0,pos,0,Vector2i.ZERO,0)
	elif dir == Vector2i.DOWN:
		set_cell(0,pos,0,Vector2i.ZERO,1)

func clear_bullet(pos:Vector2i)->void:
	erase_cell(0,pos)

func draw_trace(trace:Array)->void:
	for tc in trace:
		if tc[1] == Vector2i.LEFT:
			set_cell(0,tc[0],1,Vector2i.ZERO,2)
		elif tc[1] == Vector2i.RIGHT:
			set_cell(0,tc[0],1,Vector2i.ZERO,3)
		elif tc[1] == Vector2i.UP:
			set_cell(0,tc[0],1,Vector2i.ZERO,0)
		elif tc[1] == Vector2i.DOWN:
			set_cell(0,tc[0],1,Vector2i.ZERO,1)

func clear_trace(trace:Array)->void:
	for tc in trace:
		erase_cell(0,tc[0])

func clear_bullets()->void:
	clear()
