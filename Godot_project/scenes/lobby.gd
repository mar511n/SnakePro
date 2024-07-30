extends Node

# Autoload named Lobby

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected
signal connecting_failed
signal all_players_loaded
signal player_info_updated(peer_id, pl_info)

const DEFAULT_PORT = 8080
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 20

# contains info of local player
# name
# snake_tile_idx
var player_info = {}

# set by server contains infos about the game (rules, mods, ...)
var game_settings = {}
# contains player_info of all players; key is peer_id
var players = {}

var players_loaded = 0

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func join_game(address = "", port:int = 0):
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	if port == 0:
		port = DEFAULT_PORT
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	return OK


func create_game(port:int = 0):
	var peer = ENetMultiplayerPeer.new()
	if port == 0:
		port = DEFAULT_PORT
	var error = peer.create_server(port, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	
	update_game_settings_on_server()
	players[1] = player_info
	player_connected.emit(1, player_info)
	return OK

func reset_network():
	multiplayer.multiplayer_peer = null
	players = {}
	players_loaded = 0

@rpc("any_peer", "call_local", "reliable")
func player_info_update(peer_id, pl_info):
	players[peer_id] = pl_info
	player_info_updated.emit(peer_id, pl_info)

@rpc("authority","call_local", "reliable")
func load_scene(scene_path):
	get_tree().change_scene_to_file(scene_path)

# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			players_loaded = 0
			all_players_loaded.emit()

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

func update_game_settings_on_server():
	game_settings = {}
	game_settings[Global.config_game_params_sec] = Global.config_get_section_dict(Global.config_game_params_sec)
	game_settings[Global.config_game_mods_sec] = Global.config_get_section_dict(Global.config_game_mods_sec)
	game_settings[Global.config_game_mod_props_sec] = Global.config_get_section_dict(Global.config_game_mod_props_sec)
	game_settings[Global.config_player_mods_sec] = Global.config_get_section_dict(Global.config_player_mods_sec)
	game_settings[Global.config_player_mod_props_sec] = Global.config_get_section_dict(Global.config_player_mod_props_sec)
	if players.size() > 1:
		_update_gamesettings.rpc(game_settings)

@rpc("authority", "reliable")
func _update_gamesettings(gs):
	game_settings = gs

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	if multiplayer.is_server() and id != 1:
		_update_gamesettings.rpc_id(id, game_settings)
	_register_player.rpc_id(id, player_info)

func _on_player_disconnected(id):
	#print("_on_player_disconnected")
	players.erase(id)
	player_disconnected.emit(id)

func _on_connected_ok():
	#print("_on_connected_ok")
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)

func _on_connected_fail():
	#print("_on_connected_fail")
	multiplayer.multiplayer_peer = null
	connecting_failed.emit()

func _on_server_disconnected():
	#print("_on_server_disconnected")
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
