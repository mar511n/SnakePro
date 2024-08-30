extends GameModBase

const bds = preload("res://scenes/ModResources/bot_drawer.tscn")

var bot_drawer : TileMap

var owner_peer_id : int
var is_ghost : bool
var update_period = 1.0
var max_length : int
var use_astar : bool
var bot_id : int
var alive_time = 10.0
var max_alive_time = 10.0
var gui_id = 0

var active = true
var next_dir = Vector2i.UP

var last_drawn_tiles = [Vector2i.ZERO,Vector2i.ZERO]
var time_since_last_update = 0.0

func _init() -> void:
	pass
	#name = "Bot"

func on_game_ready(g:InGame, g_is_server:bool):
	super(g,g_is_server)
	bot_drawer = null
	for child in game.get_children():
		if child.name == "BotDrawer":
			bot_drawer = child
			#Global.Print("found BotDrawer")
	if not is_instance_valid(bot_drawer):
		bot_drawer = bds.instantiate()
		game.add_child(bot_drawer)
		#Global.Print("instantiated BotDrawer")
	bot_drawer.scale_to_tile_size(game.tile_size_px*Vector2.ONE)

func on_module_start(owner_id:int, ghost:bool, speed:float, length:int, astar:bool, time:float, local_player_gui_id:int):
	Global.Print("spawning bot of player %s"%owner_id)
	owner_peer_id = owner_id
	is_ghost = ghost
	update_period = 1.0/speed
	max_length = length
	use_astar = astar
	bot_id = bot_drawer.add_bot()
	alive_time = time
	max_alive_time = time
	gui_id = local_player_gui_id
	
	var start = game.playerlist[owner_peer_id].get_head_tile()
	var dir = game.playerlist[owner_peer_id].get_direction_facing()
	game.module_vars_rapid["BotSnake"+str(bot_id)] = [start+2*dir,start+3*dir]

func on_game_physics_process(delta):
	super(delta)
	if !active:
		return
	if is_server:
		alive_time -= delta
		if alive_time < 0:
			remove_bot.rpc()
			return
		time_since_last_update += delta
		if time_since_last_update > update_period:
			time_since_last_update = fmod(time_since_last_update,update_period)
			
			var tiles = get_tiles()
			if len(tiles) > 1:
				var cmap_snakes = get_coll_map()
				var target:Vector2i
				if is_ghost:
					target = get_next_apple_pos(tiles[-1])
					if target == tiles[-1]:
						for child in game.module_node.get_children():
							if child.name == "AppleMod":
								child.remove_apple(target)
				else:
					target = get_next_target_pos(tiles[-1])
				if use_astar:
					var cmap = cmap_snakes.duplicate_map()
					cmap.set_at_multiple(tiles, 1)
					#cmap.set_at_multiple(game.playerlist[owner_peer_id].tiles, 1)
					cmap.set_atv(tiles[-1], 0)
					cmap.set_atv(target,0)
					var path = cmap.Astar(tiles[-1], target)
					if len(path) > 1:
						next_dir = path[1]-path[0]
					else:
						next_dir = dir_from_to(tiles[-1],target)
				else:
					next_dir = dir_from_to(tiles[-1],target)
				if next_dir != Vector2i.ZERO:
					game.module_vars_rapid["BotSnake"+str(bot_id)].append(tiles[-1]+next_dir)
					while len(game.module_vars_rapid["BotSnake"+str(bot_id)]) > max_length:
						game.module_vars_rapid["BotSnake"+str(bot_id)].pop_front()
					check_collision(cmap_snakes, get_tiles())
			
	check_redraw()

func dir_from_to(start:Vector2i, end:Vector2i)->Vector2i:
	var dir = end-start
	if abs(dir.x) > abs(dir.y):
		dir.y = 0
		dir.x = sign(dir.x)
	else:
		dir.x = 0
		dir.y = sign(dir.y)
	return dir

func get_next_apple_pos(bot_head:Vector2i)->Vector2i:
	var target = Vector2i(int(game.coll_map.size_x/2)-1,int(game.coll_map.size_y/2)-1)
	var distance2 = INF
	for apos in game.module_vars["ApplePositions"]:
		var nd2 = (apos-bot_head).length_squared()
		if nd2 < distance2:
			distance2 = nd2
			target = apos
	return target

func get_next_target_pos(bot_head:Vector2i)->Vector2i:
	var target = Vector2i(int(game.coll_map.size_x/2)-1,int(game.coll_map.size_y/2)-1)
	var distance2 = INF
	for peer_id in game.playerlist:
		if peer_id != owner_peer_id and game.playerlist[peer_id].module_vars["PlayerIsAlive"]:
			var nd2 = (game.playerlist[peer_id].get_head_tile()-bot_head).length_squared()
			if nd2 < distance2:
				distance2 = nd2
				target = game.playerlist[peer_id].get_head_tile()
	return target

func get_coll_map()->CollisionMap:
	var cmap = game.coll_map.duplicate_map()
	for peer_id in game.playerlist:
		if game.playerlist[peer_id].module_vars["PlayerIsAlive"]:
			cmap.set_at_multiple(game.playerlist[peer_id].tiles, peer_id+1)
	return cmap

@rpc("authority", "call_local", "reliable")
func remove_bot():
	#Global.Print("1 removing bot of player %s with name %s"%[owner_peer_id,name])
	active = false
	if owner_peer_id == multiplayer.get_unique_id():
		var local_player_gui = game.playerlist[owner_peer_id].gui_node.get_node("ItemGUI")
		if local_player_gui != null:
			local_player_gui.remove_item(gui_id)
		else:
			Global.Print("ERROR: ItemGUI node not found in player", 7)
	if is_server:
		game.module_vars_rapid.erase("BotSnake"+str(bot_id))
	bot_drawer.remove_bot(bot_id)
	#Global.Print("2 removing bot of player %s with name %s"%[owner_peer_id,name])
	remove_module()

func check_collision(cmap:CollisionMap, tiles:Array):
	if len(tiles) < 2:
		return
	var bot_head = tiles[-1]
	for btile in tiles:
		var ci = cmap.collides_at(btile.x,btile.y)
		if ci == 1 or ci < 0:
			if btile == bot_head:
				#remove_bot()
				remove_bot.rpc()
				return
		elif ci > 1:
			var pl_head = game.playerlist[ci-1].get_head_tile()
			if btile == pl_head:
				if ci-1 != owner_peer_id or alive_time < max_alive_time-max_length*update_period:
					game.playerlist[ci-1].hit.rpc([Global.hit_causes.BOT, {"caused_by_id":owner_peer_id}])
			if btile == bot_head:
				#remove_bot()
				remove_bot.rpc()
				return

func check_redraw():
	var tiles = get_tiles()
	if len(tiles) > 1:
		if last_drawn_tiles[0] != tiles[0] or last_drawn_tiles[-1] != tiles[-1]:
			bot_drawer.draw_bot(bot_id, tiles)
			last_drawn_tiles[0] = tiles[0]
			last_drawn_tiles[-1] = tiles[-1]

func get_tiles()->Array:
	return game.module_vars_rapid.get("BotSnake"+str(bot_id), [])
