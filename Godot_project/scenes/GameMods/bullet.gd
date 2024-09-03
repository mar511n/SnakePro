extends GameModBase

const bds = preload("res://scenes/ModResources/BulletDrawer.tscn")
const trace_length = 5

var update_period = 1.0
var maxRange : int
var owner_peer_id : int
var bullet_drawer : TileMap
var travelingDir : Vector2i
var headshot_survive_length : int

var active = true

var time_since_last_update = 0.0
var pos : Vector2i
var trace : Array
var traveled = 0
var players_hit = []

func on_game_ready(g:InGame, g_is_server:bool):
	super(g,g_is_server)
	bullet_drawer = null
	for child in game.get_children():
		if child.name == "BulletDrawer":
			bullet_drawer = child
	if not is_instance_valid(bullet_drawer):
		bullet_drawer = bds.instantiate()
		game.add_child(bullet_drawer)
	bullet_drawer.scale_to_tile_size(game.tile_size_px*Vector2.ONE)

func on_module_start(start:Vector2i,dir:Vector2i,speed:float,maxrange:int,owner_id:int,survive_length:int):
	Global.Print("spawning bullet at %s in dir %s"%[start,dir],40)
	pos = start
	travelingDir = dir
	maxRange = maxrange
	owner_peer_id = owner_id
	update_period = 1.0/speed
	trace = []
	headshot_survive_length = survive_length

func on_game_physics_process(delta):
	super(delta)
	if !active:
		return
	time_since_last_update += delta
	if time_since_last_update > update_period:
		time_since_last_update = fmod(time_since_last_update,update_period)
		traveled += 1
		bullet_drawer.clear_bullet(pos)
		bullet_drawer.clear_trace(trace)
		if is_server and traveled > maxRange:
			remove_bullet.rpc()
			return
		trace.append([pos, Vector2i(travelingDir)])
		if len(trace) > trace_length:
			trace.remove_at(0)
		pos += travelingDir
		bullet_drawer.draw_bullet(pos,travelingDir)
		bullet_drawer.draw_trace(trace)
		
		if is_server:
			check_collision()
		# handle collision only on server

func on_game_checked_collisions(colls)->Array:
	if is_server:
		check_collision()
	return super(colls)

func check_collision():
	if game.coll_map.collides_at(pos.x,pos.y) != 0:
		#remove_bullet()
		remove_bullet.rpc()
		return
	for peer_id in game.playerlist:
		var tile_idx = game.playerlist[peer_id].tiles.rfind(pos)
		if tile_idx >= 0:
			var survives = game.playerlist[peer_id].has_enough_tiles(tile_idx+1)
			if survives:
				game.playerlist[peer_id].remove_tiles_from_tail.rpc_id(peer_id,tile_idx+1)
			elif peer_id != owner_peer_id:
				var sn_len = len(game.playerlist[peer_id].tiles)
				if sn_len >= headshot_survive_length:
					game.playerlist[peer_id].remove_tiles_from_tail.rpc_id(peer_id,sn_len-2)
				elif not peer_id in players_hit:
					game.playerlist[peer_id].hit.rpc([Global.hit_causes.BULLET, {"caused_by_id":owner_peer_id}])
				players_hit.append(peer_id)

@rpc("authority", "call_local", "reliable")
func remove_bullet():
	active = false
	bullet_drawer.clear_bullet(pos)
	bullet_drawer.clear_trace(trace)
	remove_module()
