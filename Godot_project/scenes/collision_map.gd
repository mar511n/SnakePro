extends Node
class_name CollisionMap

#var map_str : String = ""
var map_arr : Array
var size_x : int = 0
var size_y : int = 0

func reconstruct_path(cameFrom:Dictionary, current:Vector2i)->Array:
	var total_path = [current]
	while current in cameFrom.keys():
		current = cameFrom[current]
		total_path.append(current)
	total_path.reverse()
	return total_path

func Astar(start:Vector2i,goal:Vector2i)->Array:
	var openSet = [start]
	var cameFrom = {}
	var gScore = {}
	for x in range(size_x):
		for y in range(size_y):
			gScore[Vector2i(x,y)] = INF
	gScore[start] = 0
	var fScore = {}
	for x in range(size_x):
		for y in range(size_y):
			fScore[Vector2i(x,y)] = INF
	fScore[start] = (start-goal).length_squared()
	
	#Global.Print("starting Astar with start=%s, goal=%s and map: %s"%[start,goal,_to_string()])
	
	var current:Vector2i = start
	while len(openSet) > 0:
		#Global.Print("searching from current=%s"%current)
		if current == goal:
			return reconstruct_path(cameFrom,current)
		openSet.erase(current)
		for dr in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var neighbor:Vector2i = current+dr
			if collides_at(neighbor.x,neighbor.y) == 0:
				var tentative_gScore = gScore[current] + 1
				if tentative_gScore < gScore[neighbor]:
					cameFrom[neighbor] = current
					gScore[neighbor] = tentative_gScore
					fScore[neighbor] = tentative_gScore + (neighbor-goal).length_squared()
					if not neighbor in openSet:
						openSet.append(neighbor)
		var minF = INF
		for n in openSet:
			if fScore[n] < minF:
				minF = fScore[n]
				current = n
	return []

func duplicate_map()->CollisionMap:
	var cmapn = CollisionMap.new()
	cmapn.size_x = size_x
	cmapn.size_y = size_y
	cmapn.map_arr = map_arr.duplicate()
	return cmapn

func collides_at(x : int,y : int) -> Variant:
	if x < 0 or x >= size_x or y < 0 or y >= size_y:
		return -1
	#return int(map_str.substr(x + y*size_x,1))
	return map_arr[x + y*size_x]

func make_map(width:int,height:int,v0:Variant)->void:
	size_x = width
	size_y = height
	fill(v0)

func load_from_Tilemap(tmap:TileMap, sn_drawer:TileMap)->TileMap:
	var scaleF:int = int(tmap.to_global(tmap.map_to_local(Vector2i(1,0))).x/sn_drawer.to_global(sn_drawer.map_to_local(Vector2i(1,0))).x)
	#print("scaleF %s" % scaleF)
	var tmap_size : Vector2i = tmap.get_used_rect().end
	#print("tmap_size %s" % tmap_size)
	make_map(int(float(tmap_size.x*scaleF)+1), int(float(tmap_size.y*scaleF)+1), 1)
	var ground_cells:Array = tmap.get_used_cells(0)
	#print(_to_string()+"\n")
	for gc:Vector2i in ground_cells:
		#print("filling ground from x=%s, y=%s" % [gc.x*scaleF,gc.y*scaleF])
		fill_value(gc.x*scaleF, gc.y*scaleF, scaleF, scaleF, 0)
		for dx:int in range(scaleF):
			for dy:int in range(scaleF):
				var query:PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
				query.collision_mask = CollisionMap.get_coll_layer_mask([1])
				query.collide_with_areas = true
				query.position = sn_drawer.to_global(sn_drawer.map_to_local(gc*scaleF+Vector2i(dx,dy)))
				var colls:Array = tmap.get_world_2d().direct_space_state.intersect_point(query,1)
				if len(colls) > 0:
					#print("%s collisions at %s" % [len(colls), query.position])
					set_at(gc.x*scaleF+dx, gc.y*scaleF+dy,1)
	Global.Print("Collision map:")
	Global.Print(_to_string()+"\n")
	#var prop_cells = tmap.get_used_cells(1)
	#print(_to_string()+"\n")
	#for pc in prop_cells:
	#	#print("filling prop from x=%s, y=%s" % [pc.x*scaleF,pc.y*scaleF])
	#	fill_value(pc.x*scaleF, pc.y*scaleF, scaleF, scaleF, 1)
	#print(_to_string()+"\n")
	return tmap

func _to_string()->String:
	var s:String = ""
	for y:int in range(size_y):
		s += "\n"
		#s += map_str.substr(size_x*y,size_x)
		for x:int in range(size_x):
			s += str(map_arr[x+y*size_x])+" "
	return s

func fill_value(x:int,y:int,w:int,h:int, v:Variant)->void:
	for dx:int in range(w):
		for dy:int in range(h):
			set_at(x+dx,y+dy,v)

func set_at_multiple(poss:Array,v:Variant)->void:
	for pos in poss:
		set_at(pos.x,pos.y,v)

func set_atv(pos:Vector2i,v:Variant)->void:
	var idx:int = pos.x + pos.y*size_x
	if idx >= 0 and idx < len(map_arr):
		map_arr[idx] = v

func set_at(x:int,y:int,v:Variant)->void:
	var idx:int = x + y*size_x
	if idx >= 0 and idx < len(map_arr):
		map_arr[idx] = v
	#if idx >= 0 and idx < len(map_str):
	#	map_str = map_str.erase(idx, 1)
	#	map_str = map_str.insert(idx, str(v))

func is_in_bounds(pos:Vector2i)->bool:
	return pos.x >= 0 and pos.x < size_x and pos.y >= 0 and pos.y < size_y

func fill(v:Variant)->void:
	#if v > 9 or v < 0:
	#	return
	#map_str = str(v).repeat(size_x*size_y)
	map_arr.resize(size_x*size_y)
	map_arr.fill(v)

static func get_coll_layer_mask(layers:Array)->int:
	var mask:int = 0
	for layer:int in layers:
		mask += int(2**(layer-1))
	return mask
