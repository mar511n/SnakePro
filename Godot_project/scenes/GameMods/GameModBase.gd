extends Node
class_name GameModBase

var game : InGame
var is_server : bool

# called before map and players load
func on_game_ready(g:InGame, g_is_server:bool):
	game = g
	is_server = g_is_server

# called after map and players have loaded
func on_game_post_ready():
	pass

#func on_game_process(_delta):
#	pass

func on_game_physics_process(_delta):
	pass

# gets all collisions that happened and returns which ones are handled
# colls is dictionary peer_id -> [[Global.collision, infos],...]
# returns array with peer_ids of handled collisions
func on_game_checked_collisions(_colls)->Array:
	return []

# gets the player to be spawned and returns it
func on_game_spawns_player(pl:SnakePlayer)->SnakePlayer:
	return pl
