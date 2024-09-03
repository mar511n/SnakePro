extends Node

# Autoload named Lobby

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id:int, player_info:Dictionary)
signal player_disconnected(peer_id:int)
signal server_disconnected
signal connecting_failed
signal all_players_loaded
signal player_info_updated(peer_id:int, pl_info:Dictionary)
signal on_priv_granted()
#signal on_spawn_scene(scene)

const DEFAULT_PORT:int = 8080
const DEFAULT_SERVER_IP:String = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS:int = 20

var game_stats = {}
@rpc("any_peer", "call_local", "reliable")
func reset_game_stats():
	game_stats = {}
	Global.player_stats_on_game_start()
@rpc("any_peer", "call_local", "reliable")
func set_game_stats(key:Variant, value:Variant):
	game_stats[key] = value
	if key == "Winner":
		var pl_id = value
		if pl_id == multiplayer.get_unique_id():
			pl_id = -1
		if not Global.player_stats[-1].has(pl_id):
			Global.player_stats[-1][pl_id] = {"kills":[],"deaths":[],"wins":0}
		Global.player_stats[-1][pl_id]["wins"] += 1

# contains info of local player
# name
# snake_tile_idx
# priv
# mainMultiplayerScreen
var player_info:Dictionary = {}

# set by server contains infos about the game
var game_settings:Dictionary = {}
# contains player_info of all players; key is peer_id
var players:Dictionary = {}

var players_loaded:int = 0

var privileges_granted_to = -1
var enetpacketpeer:ENetPacketPeer

func _ready()->void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _physics_process(delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		TopGui.set_rtt(enetpacketpeer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)/1000.0)
	else:
		TopGui.unset_rtt()

func join_game(address:String = "", port:int = 0)->Error:
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	if port == 0:
		port = DEFAULT_PORT
	var peer:ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error:Error = peer.create_client(address, port)
	if error:
		return error
	enetpacketpeer = peer.get_peer(1)
	multiplayer.multiplayer_peer = peer
	Global.player_stats = [{}]
	return OK


func create_game(port:int = 0)->Error:
	var peer:ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	if port == 0:
		port = DEFAULT_PORT
	var error:Error = peer.create_server(port, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	
	update_game_settings_on_server()
	if not OS.has_feature("dedicated_server"):
		players[1] = player_info
		player_connected.emit(1, player_info)
	Global.player_stats = [{}]
	return OK

func reset_network()->void:
	multiplayer.multiplayer_peer = null
	players = {}
	players_loaded = 0

@rpc("any_peer", "call_local", "reliable")
func player_info_update(peer_id:int, pl_info:Dictionary)->void:
	players[peer_id] = pl_info
	player_info_updated.emit(peer_id, pl_info)

@rpc("authority","call_local", "reliable")
func load_scene(scene_path:String,game_finished=false)->void:
	#on_spawn_scene.emit(scene_path)
	if game_finished:
		Global.player_stats_on_game_finished()
	get_tree().change_scene_to_file(scene_path)

# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded()->void:
	#if multiplayer.is_server():
	players_loaded += 1
	if players_loaded == players.size():
		players_loaded = 0
		all_players_loaded.emit()

@rpc("any_peer", "reliable")
func _register_player(new_player_info:Dictionary)->void:
	var new_player_id:int = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)
	if OS.has_feature("dedicated_server"):
		if new_player_info.get("priv",0) == 1 and privileges_granted_to == -1:
			privileges_granted_to = new_player_id
			on_privileges_granted.rpc_id(new_player_id)
			Global.Print("privileges are granted to player %s"%new_player_id, 45)

@rpc("authority", "reliable")
func on_privileges_granted():
	Global.Print("privileges have been granted", 55)
	on_priv_granted.emit()

func update_game_settings_on_server()->void:
	game_settings = {}
	game_settings[Global.config_game_params_sec] = Global.config_get_section_dict(Global.config_game_params_sec)
	game_settings[Global.config_game_mods_sec] = Global.config_get_section_dict(Global.config_game_mods_sec)
	game_settings[Global.config_game_mod_props_sec] = Global.config_get_section_dict(Global.config_game_mod_props_sec)
	game_settings[Global.config_player_mods_sec] = Global.config_get_section_dict(Global.config_player_mods_sec)
	game_settings[Global.config_player_mod_props_sec] = Global.config_get_section_dict(Global.config_player_mod_props_sec)
	if players.size() > 1 or (OS.has_feature("dedicated_server") and players.size() > 0):
		_update_gamesettings.rpc(game_settings)

@rpc("any_peer", "reliable")
func _update_gamesettings(gs:Dictionary)->void:
	game_settings = gs

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id:int)->void:
	if multiplayer.is_server() and id != 1:
		_update_gamesettings.rpc_id(id, game_settings)
	if not OS.has_feature("dedicated_server"):
		_register_player.rpc_id(id, player_info)

func _on_player_disconnected(id:int)->void:
	#print("_on_player_disconnected")
	players.erase(id)
	player_disconnected.emit(id)
	if OS.has_feature("dedicated_server") and id == privileges_granted_to:
		privileges_granted_to = -1

func _on_connected_ok()->void:
	#print("_on_connected_ok")
	var peer_id:int = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)

func _on_connected_fail()->void:
	#print("_on_connected_fail")
	multiplayer.multiplayer_peer = null
	connecting_failed.emit()

func _on_server_disconnected()->void:
	#print("_on_server_disconnected")
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
