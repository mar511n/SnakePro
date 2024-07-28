extends GameModBase

func _init():
	set_meta("name", "Apples")
	set_meta("AppleCount", [int(10),0,100,1])

# spawn apples here
func on_game_post_ready():
	if is_server:
		Global.Print("spawning apples")
		game.module_vars["AppleCount"] = int(Global.get_property(Global.config_game_mod_props_sec, "AppleCount", 10))
		game.module_vars["ApplePositions"] = []
		for ai in range(game.module_vars["AppleCount"]):
			spawn_apple()

func spawn_apple():
	var pos = Vector2i.ZERO
	for i in range(100):
		pos = Vector2i(randi_range(0,game.coll_map.size_x),randi_range(0,game.coll_map.size_y))
		if not pos in game.module_vars["ApplePositions"]:
			if len(game.tile_check_collisions(pos, [Global.scl.alive,Global.scl.dead,Global.scl.wall],1))==0:
				break
	game.module_vars["ApplePositions"].append(pos)

# gets all collisions that happened and returns which ones are handled
# colls is dictionary peer_id -> [Global.collision, infos]
# returns array with peer_ids of handled collisions
# check if apple is eaten
func on_game_checked_collisions(_colls)->Array:
	return []

# gets the player to be spawned and returns it
# set apple stats counter of player to 0
func on_game_spawns_player(pl:SnakePlayer)->SnakePlayer:
	return pl
