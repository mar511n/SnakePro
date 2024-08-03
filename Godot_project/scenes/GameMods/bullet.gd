extends GameModBase

const bds = preload("res://scenes/ModResources/BulletDrawer.tscn")
const trace_length = 5

var update_period = 1.0
var maxRange : int
var owner_peer_id : int
var bullet_drawer : TileMap
var travelingDir : Vector2i

var time_since_last_update = 0.0
var pos : Vector2i
var trace : Array
var traveled = 0

func _init() -> void:
	name = "Bullet"

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

func on_module_start(start:Vector2i,dir:Vector2i,speed:float,maxrange:int,owner_id:int):
	Global.Print("spawning bullet at %s"%start)
	pos = start
	travelingDir = dir
	maxRange = maxrange
	owner_peer_id = owner_id
	update_period = 1.0/speed
	trace = []

func on_game_physics_process(delta):
	time_since_last_update += delta
	if time_since_last_update > update_period:
		time_since_last_update = fmod(time_since_last_update,update_period)
		traveled += 1
		bullet_drawer.clear_bullet(pos)
		bullet_drawer.clear_trace(trace)
		if traveled > maxRange:
			remove_module()
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

func check_collision():
	for peer_id in game.playerlist:
		var tile_idx = game.playerlist[peer_id].tiles.rfind(pos)
		if tile_idx >= 0:
			var survives = game.playerlist[peer_id].has_enough_tiles(tile_idx+1)
			if survives:
				game.playerlist[peer_id].remove_tiles_from_tail.rpc_id(peer_id,tile_idx+1)
			else:
				game.playerlist[peer_id].hit.rpc([Global.hit_causes.BULLET, {"owner":owner_peer_id}])
