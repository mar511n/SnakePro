extends Node
class_name CollisionMap

var map_str : String = ""
var size_x : int = 0
var size_y : int = 0

func collides_at(x : int,y : int) -> int:
	if x < 0 or x >= size_x or y < 0 or y > size_y:
		return -1
	return int(map_str.substr(x + y*size_x,1))

func make_map(width:int,height:int,v0:int):
	size_x = width
	size_y = height
	fill(v0)

func load_from_Tilemap(tmap:TileMap, sn_drawer):
	var scaleF = int(tmap.to_global(tmap.map_to_local(Vector2i(1,0))).x/sn_drawer.to_global(sn_drawer.map_to_local(Vector2i(1,0))).x)
	#print("scaleF %s" % scaleF)
	var tmap_size : Vector2i = tmap.get_used_rect().end
	#print("tmap_size %s" % tmap_size)
	make_map(int(float(tmap_size.x*scaleF)+1), int(float(tmap_size.y*scaleF)+1), 1)
	var ground_cells = tmap.get_used_cells(0)
	#print(_to_string()+"\n")
	for gc in ground_cells:
		#print("filling ground from x=%s, y=%s" % [gc.x*scaleF,gc.y*scaleF])
		fill_value(gc.x*scaleF, gc.y*scaleF, scaleF, scaleF, 0)
		for dx in range(scaleF):
			for dy in range(scaleF):
				var query = PhysicsPointQueryParameters2D.new()
				query.collision_mask = CollisionMap.get_coll_layer_mask([1])
				query.collide_with_areas = true
				query.position = sn_drawer.to_global(sn_drawer.map_to_local(gc*scaleF+Vector2i(dx,dy)))
				var colls = tmap.get_world_2d().direct_space_state.intersect_point(query,1)
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

func load_from_image(path:String):
	var img = Image.load_from_file(path)
	if img == null:
		Global.Print("ERROR while loading image as collision map from path %s" % path, 7)
		return
	make_map(img.get_width(),img.get_height(),0)
	var idx = 0
	for y in range(size_y):
		for x in range(size_x):
			map_str.erase(idx, 1)
			map_str.insert(idx, str(int(img.get_pixel(x,y).get_luminance()*9.99999)))
			idx += 1

func _to_string()->String:
	var s = ""
	for y in range(size_y):
		s += "\n"
		s += map_str.substr(size_x*y,size_x)
	return s

func fill_value(x:int,y:int,w:int,h:int, v:int):
	for dx in range(w):
		for dy in range(h):
			set_at(x+dx,y+dy,v)

func set_at(x:int,y:int,v:int):
	var idx = x + y*size_x
	if idx >= 0 and idx < len(map_str):
		map_str = map_str.erase(idx, 1)
		map_str = map_str.insert(idx, str(v))

func fill(v:int):
	if v > 9 or v < 0:
		return
	map_str = str(v).repeat(size_x*size_y)

static func get_coll_layer_mask(layers)->int:
	var mask = 0
	for layer in layers:
		mask += pow(2, layer-1)
	return mask
