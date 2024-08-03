extends GameModBase

var apple_drawer : TileMap
var AppleRedrawCounter = 0
var RottenApples = {}

const AppleSpawnTries = 1000
var AppleNutrition = 3
var AppleRottTime = 10.0
var GhostAppleDamage = 3

func _init():
	name = "AppleMod"
	set_meta("name", "Apples")
	set_meta("AppleCount", [int(10),0,100,1])
	set_meta("AppleNutrition", [int(3),0,31,1])
	set_meta("AppleRottTime", [10,0,120,0.5])
	set_meta("GhostAppleDamage", [int(3),0,31,1])

func on_game_ready(g:InGame, g_is_server:bool):
	super(g,g_is_server)
	AppleNutrition = int(Global.get_property(Global.config_game_mod_props_sec, "AppleNutrition", 3))
	AppleRottTime = float(Global.get_property(Global.config_game_mod_props_sec, "AppleRottTime", 10.0))
	GhostAppleDamage = int(Global.get_property(Global.config_game_mod_props_sec, "GhostAppleDamage", 3))
	
	var apple_drawer_r = preload("res://scenes/ModResources/AppleMap.tscn")
	if apple_drawer_r != null:
		apple_drawer = apple_drawer_r.instantiate()
		game.add_child(apple_drawer)
		apple_drawer.scale_to_tile_size(Vector2.ONE*g.tile_size_px)
	AppleRedrawCounter = 0
	if is_server:
		game.module_vars["AppleCount"] = int(Global.get_property(Global.config_game_mod_props_sec, "AppleCount", 10))
		game.module_vars["ApplePositions"] = []
		game.module_vars["GhostApplePositions"] = []
		game.module_vars["AppleRedrawCounter"] = 0

# spawn apples here
func on_game_post_ready():
	if is_server:
		Global.Print("spawning apples")
		for ai in range(game.module_vars["AppleCount"]):
			spawn_apple()

@rpc("any_peer", "call_local", "reliable")
func spawn_apple():
	var pos = Vector2i.ZERO
	for i in range(AppleSpawnTries):
		pos = Vector2i(randi_range(0,game.coll_map.size_x),randi_range(0,game.coll_map.size_y))
		if not pos in game.module_vars["ApplePositions"] and not pos in game.module_vars["GhostApplePositions"] and not pos in game.module_vars["IngameItems"].keys():
			if len(game.tile_check_collisions(pos, [Global.scl.alive,Global.scl.dead,Global.scl.wall],1))==0:
				break
	game.module_vars["ApplePositions"].append(pos)
	game.module_vars["AppleRedrawCounter"] += 1

@rpc("any_peer", "call_local", "reliable")
func ghostify_apple(pos:Vector2i):
	var idx = game.module_vars["ApplePositions"].find(pos)
	if idx >= 0:
		game.module_vars["ApplePositions"].remove_at(idx)
		game.module_vars["GhostApplePositions"].append(pos)
		game.module_vars["AppleRedrawCounter"] += 1
		RottenApples[pos] = AppleRottTime

@rpc("any_peer", "call_local","reliable")
func remove_apple(pos:Vector2i):
	var idx = game.module_vars["ApplePositions"].find(pos)
	if idx >= 0:
		game.module_vars["ApplePositions"].remove_at(idx)
		game.module_vars["AppleRedrawCounter"] += 1
		spawn_apple()
	else:
		idx = game.module_vars["GhostApplePositions"].find(pos)
		if idx >= 0:
			game.module_vars["GhostApplePositions"].remove_at(idx)
			game.module_vars["AppleRedrawCounter"] += 1
			spawn_apple()

func redraw_apples():
	apple_drawer.clear_apples()
	apple_drawer.draw_apples(game.module_vars["ApplePositions"], false)
	apple_drawer.draw_apples(game.module_vars["GhostApplePositions"], true)

# gets all collisions that happened and returns which ones are handled
# colls is dictionary peer_id -> [[Global.collision, infos],...]
# returns array with peer_ids of handled collisions
# check if apple is eaten
func on_game_checked_collisions(_colls)->Array:
	for peer_id in game.playerlist:
		check_apple_collision_for_local_player.rpc_id(peer_id)
	return []

@rpc("any_peer", "call_local","reliable")
func check_apple_collision_for_local_player():
	var player = game.playerlist.get(multiplayer.get_unique_id(), null)
	if player != null:
		var head = player.get_head_tile()
		if head in game.module_vars["ApplePositions"]:
			if player.module_vars["PlayerIsAlive"]:
				player.EatingSound.play()
				#Global.Print("fett += %s" % AppleNutrition, 7)
				player.fett += AppleNutrition
				remove_apple.rpc_id(1,head)
			else:
				ghostify_apple.rpc_id(1,head)
		elif head in game.module_vars["GhostApplePositions"]:
			if player.module_vars["PlayerIsAlive"]:
				player.EatingRottenSound.play()
				#Global.Print("fett -= %s" % GhostAppleDamage, 7)
				#Global.Print("tiles = %s" % len(player.tiles), 7)
				var survives = player.has_enough_tiles(GhostAppleDamage)
				if survives:
					player.remove_tiles_from_tail(GhostAppleDamage)
				else:
					Global.Print("dead", 7)
					player.hit.rpc([Global.hit_causes.APPLE_DMG, {}])
				remove_apple.rpc_id(1,head)

func on_game_physics_process(delta):
	if is_server:
		for ra in RottenApples:
			RottenApples[ra] -= delta
			if RottenApples[ra] < 0:
				remove_apple(ra)
	
	if game.module_vars.get("AppleRedrawCounter",0) != AppleRedrawCounter:
		redraw_apples()
		AppleRedrawCounter = game.module_vars.get("AppleRedrawCounter",0)

# gets the player to be spawned and returns it
# set apple stats counter of player to 0
func on_game_spawns_player(pl:SnakePlayer)->SnakePlayer:
	return pl
