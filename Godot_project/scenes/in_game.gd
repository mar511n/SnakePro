extends Node2D
class_name InGame

@export var PlayerScene : PackedScene

@onready var pl_spawner:MultiplayerSpawner = $PlayerSpawner
@onready var sn_drawer:TileMap = $SnakeDrawer
@onready var module_list:RichTextLabel = $GUI/Panel2/RichTextLabel
@onready var module_node:Node = $Modules

var tile_size_px:float = 96.0

var coll_map : CollisionMap
var playerlist:Dictionary = {} # peer_id -> player node
var tmap : TileMap

var module_scripts : Dictionary
@export var module_vars:Dictionary = {}
@export var module_vars_rapid:Dictionary = {}

# helper variables
var check_collisions:bool = false
var ready_phase:int = 0
var waitframes:int = 0
var finished_loading_players:bool = false

# on server:
# -> start post_ready()
# -> check for collisions
func _physics_process(delta:float)->void:
	if finished_loading_players and waitframes > 0:
		waitframes -= 1
		if waitframes == 0:
			Global.Print("starting game")
			pause_game(false,false)
	if ready_phase == 2 and finished_loading_players and waitframes <= 0:
		post_ready()
	if ready_phase == 3:
		if check_collisions:
			if multiplayer.is_server():
				check_snake_collisions()
			#else:
			#	for mod in module_node.get_children():
			#		mod.on_game_checked_collisions({})
			check_collisions = false
		for mod:Node in module_node.get_children():
			mod.on_game_physics_process(delta)

# on server:
# -> note movement of player (to check collision on next physics frame)
func _on_player_movement(_peer_id:int, _pl_idx:int)->void:
	check_collisions = true

# on server:
# -> check collisions of snakes
# -> call player.hit for affected players
func check_snake_collisions()->void:
	var colls:Dictionary = {}
	for peer_id:int in playerlist:
		colls[peer_id] = head_collides_with_smth(peer_id,playerlist[peer_id].tiles[-1])
	
	for mod:Node in module_node.get_children():
		var handled_colls:Array = mod.on_game_checked_collisions(colls)
		for hc:int in handled_colls:
			colls.erase(hc)
	for peer_id:int in colls:
		var colld:Array = colls[peer_id]
		if colld[0] != Global.collision.NO:
			if colld[0] == Global.collision.PLAYERHEAD:
				#playerlist[colld[1]].hit.rpc([Global.hit_causes.COLLISION, {"type":Global.collision.PLAYERHEAD,"peer_id":peer_id}])
				playerlist[peer_id].hit.rpc([Global.hit_causes.COLLISION, {"type":Global.collision.PLAYERHEAD,"peer_id":colld[1]}])
			elif colld[0] == Global.collision.WALL:
				playerlist[peer_id].hit.rpc([Global.hit_causes.COLLISION, {"type":Global.collision.WALL,"wall_v":colld[1]}])
			elif colld[0] == Global.collision.PLAYERBODY:
				playerlist[peer_id].hit.rpc([Global.hit_causes.COLLISION, {"type":Global.collision.PLAYERBODY,"peer_id":colld[1]}])

# on server:
# -> check collisions of tile with:
# --> Map
# --> Self/other players
func head_collides_with_smth(peer_id:int, pos:Vector2i) -> Array:
	var colls:Array = tile_check_collisions(pos,playerlist[peer_id].CollMasks,2)
	for coll:Array in colls:
		if not (coll[0] == Global.collision.PLAYERHEAD and coll[1] == peer_id):
			return coll
	return [Global.collision.NO, null]

func tile_check_collisions(pos:Vector2i,CollLayer:Array,max_colls:int=1)->Array:
	var colls:Array = []
	var wc:int = coll_map.collides_at(pos.x,pos.y)
	if wc != 0 and Global.scl.wall in CollLayer:
		colls.append([Global.collision.WALL, wc])
		if len(colls) >= max_colls:
			return colls
	
	for peer2_id:int in playerlist:
		if CollLayer.any(func(cl:int)->bool: return cl in playerlist[peer2_id].CollLayers):
			#print("%s cmasks %s" % [peer_id, playerlist[peer_id].CollMasks])
			#print("%s clayers %s" % [peer2_id, playerlist[peer2_id].CollLayers])
			for tile_i:int in range(len(playerlist[peer2_id].tiles)):
				if playerlist[peer2_id].tiles[tile_i] == pos:
					var ct:Global.collision = Global.collision.PLAYERBODY
					if tile_i == len(playerlist[peer2_id].tiles)-1:
						ct = Global.collision.PLAYERHEAD
					colls.append([ct, peer2_id])
					if len(colls) >= max_colls:
						return colls
	return colls

# on server/client:
# -> process input
func _input(event:InputEvent)->void:
	if event.is_action_pressed("ui_cancel"):
		Global.Print(get_tree().root.get_tree_string_pretty())
		pause_game.rpc(!$GUI.visible)
	elif event is InputEventKey:
		if event.keycode == KEY_0 and event.pressed:
			print("capturing gamestate")
			var save_file:FileAccess = FileAccess.open("user://savegame.save", FileAccess.WRITE)
			var sns:Array = get_tree().get_nodes_in_group("VariableGraphical")
			if len(sns) == 0:
				print("error: no objects")
				return
			var node : Node = sns[0]
			if node.scene_file_path.is_empty():
				print("error: no scene")
				return
			save_file.store_var(node,true)
		elif event.keycode == KEY_9 and event.pressed:
			print("loading gamestate")
			var save_file:FileAccess = FileAccess.open("user://savegame.save", FileAccess.READ)
			var node:Node = save_file.get_var(true)
			print(node)
			add_child(node)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit() # default behavior
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		pause_game.rpc(!$GUI.visible)

# on server/client:
# reset the game, load TileMap, spawn players
func _ready()->void:
	format_module_list()
	
	module_scripts = {}
	var dir:DirAccess = DirAccess.open(Global.game_modules_dir)
	for mod_path:String in dir.get_files():
		mod_path = mod_path.trim_suffix(".remap")
		var mod_r:Resource = load(Global.game_modules_dir+mod_path)
		if mod_r != null:
			module_scripts[mod_path] = mod_r
	
	var en_mod_paths:Array = Global.get_enabled_mod_paths(Global.config_game_mods_sec)
	for mod_path:String in en_mod_paths:
		var mod:Resource = module_scripts.get(mod_path, null)
		if mod != null:
			module_node.add_child(mod.new())
			Global.Print("loading game module %s: success" % mod_path)
		else:
			Global.Print("loading game module %s: ERROR" % mod_path, 7)
	
	ready_phase = 1
	pl_spawner.spawn_function = self.spawn_player
	Lobby.connecting_failed.connect(self.connection_failed)
	Lobby.server_disconnected.connect(self.connection_failed)
	Lobby.player_disconnected.connect(self.player_disconnected)
	Lobby.all_players_loaded.connect(self.all_players_loaded)
	$GUI/Panel/VBoxContainer/Return.disabled = !multiplayer.is_server()
	
	pause_game(true, false)
	
	playerlist = {}
	var pl_list:Array = Lobby.players.keys()
	pl_list.sort()
	sn_drawer.reset(len(pl_list))
	tile_size_px = (sn_drawer.to_global(sn_drawer.map_to_local(Vector2i(1,0)))-sn_drawer.to_global(sn_drawer.map_to_local(Vector2i(0,0)))).x
	if multiplayer.is_server():
		var game_params:Dictionary = Lobby.game_settings.get(Global.config_game_params_sec,{})
		load_map.rpc(game_params.get("mapPath", Global.default_game_params["mapPath"]))
		
		var index:int = 0
		for peer_id:int in pl_list:
			pl_spawner.spawn([index, peer_id])
			index += 1
	
	for mod:Node in module_node.get_children():
		mod.on_game_ready(self, multiplayer.is_server())
	ready_phase = 2

func post_ready()->void:
	Global.Print("post_ready")
	coll_map.load_from_Tilemap(tmap, sn_drawer)
	for mod:Node in module_node.get_children():
		mod.on_game_post_ready()
	ready_phase = 3

func format_module_list()->void:
	#print(str(Lobby.game_settings))
	
	module_list.clear()
	module_list.append_text("[b]"+Global.config_game_params_sec+"[/b]\n")
	var gparams:Dictionary = Lobby.game_settings.get(Global.config_game_params_sec,{})
	for gparam:String in gparams:
		module_list.append_text(gparam + " : " + str(gparams[gparam]) +"\n")
	
	for sec:Array in [[Global.config_player_mods_sec, Global.config_player_mod_props_sec], [Global.config_game_mods_sec,Global.config_game_mod_props_sec]]:
		module_list.append_text("[b]"+ sec[0]+"[/b]\n")
		var en_ms:Array = Global.get_enabled_mods(sec[0])
		for mod:String in en_ms:
			module_list.append_text(mod+"\n")
		module_list.append_text("[b]"+ sec[1]+"[/b]\n")
		var setts:Dictionary = Lobby.game_settings.get(sec[1], {})
		for sett:String in setts:
			module_list.append_text(sett+" : "+str(setts[sett]) +"\n")

# on server&client:
# load the specified tilemap (path must be valid on all clients)
# if path is invalid, disconnects and returns to main menu
@rpc("authority","call_local", "reliable")
func load_map(path:String):
	coll_map = CollisionMap.new()
	Global.Print("loading map %s" % path, 6)
	var tmap_packed = load(path)
	if tmap_packed == null:
		Global.Print("ERROR while loading tilemap as collision map from path %s" % path, 7)
		return_to_main_menu(true,false)
		return
	tmap = tmap_packed.instantiate()
	for child in $Map.get_children():
		$Map.remove_child(child)
	$Map.add_child(tmap)

# on server: (is only called here)
# unpause all gameobj and start the game
func all_players_loaded():
	Global.Print("all players loaded")
	if ready_phase >= 2:
		Global.Print("starting game")
		waitframes = 0
		pause_game(false, false) # set game to play since all players loaded
	else:
		waitframes = 2
		call_deferred("set_physics_process", true)
		call_deferred("set_process", true)
	finished_loading_players = true

# on server/client:
# spawn a player node
func spawn_player(data) -> Node:
	var index = data[0]
	var peer_id = data[1]
	#var gparams = data[2]
	var pl = PlayerScene.instantiate()
	pl.sn_drawer_path = sn_drawer.get_path()
	pl.name = str(peer_id)
	pl.peer_id = peer_id
	pl.pl_idx = index
	pl.IG = self
	Global.Print("spawning player %s with id %s" % [index, peer_id])

	pl.on_movement.connect(self._on_player_movement)
	
	# call pre_read() with spawnpoint
	var spawn_found = false
	for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
		if spawn.name == str(index):
			#Global.Print("sn_drawer_path %s, spawn %s" % [currentPlayer.sn_drawer_path, spawn])
			pl.pre_ready(spawn,Global.get_enabled_mod_paths(Global.config_player_mods_sec))
			spawn_found = true
			break
	if !spawn_found:
		Global.Print("ERROR: no spawnpoint found for player %s with id %s" % [index, peer_id], 7)
	
	# set camera bounds
	for node in tmap.get_children():
		if node.name == "LT":
			pl.camLT_lim = node.global_position
		elif node.name == "RB":
			pl.camRB_lim = node.global_position
	
	for mod in module_node.get_children():
		pl = mod.on_game_spawns_player(pl)
	
	# add to playerlist
	playerlist[peer_id] = pl
	return pl

func get_alive_players()->int:
	var al_pl = 0
	for pl in playerlist:
		if playerlist[pl].module_vars["PlayerIsAlive"]:
			al_pl += 1
	return al_pl

# on server&client:
# can be called remotely to pause the game for all gameobj
@rpc("any_peer","call_local", "reliable")
func pause_game(pause, set_gui=true):
	Global.Print("pause_game %s" % pause)
	for node in get_tree().get_nodes_in_group("gameobj"):
		node.call_deferred("set_physics_process", !pause)
		node.call_deferred("set_process", !pause)
	#if is_instance_valid(get_tree().current_scene):
	#	Global.Print(get_tree().current_scene.name)
	#for child in module_node.get_children():
	#	Global.Print(child)
	if set_gui:
		$GUI.visible = pause

# on server/client:
# -> loads the main menu (locally or for all peers) and resets networking if requested
func return_to_main_menu(reset_net=false, all_peers=false):
	#Global.Print("loading main_menu: %s" % Global.main_menu_path)
	if all_peers:
		#get_tree().call_group("Synchronizer", "free")
		#Lobby.scene_spawner.spawn(Global.main_menu_path)
		Lobby.load_scene.rpc(Global.main_menu_path)
	else:
		if reset_net:
			Lobby.reset_network()
		Lobby.load_scene(Global.main_menu_path)

# on server/client:
# -> remove player from SceneTree and playerlist
func player_disconnected(peer_id):
	Global.Print("Player disconnected: %s" % peer_id, 6)
	playerlist[peer_id].queue_free()
	playerlist.erase(peer_id)

# on server/client:
# -> connection failed: return to main menu
func connection_failed():
	Global.Print("ERROR: connection failed", 7)
	return_to_main_menu(true,false)

@rpc("any_peer","call_local", "reliable")
func start_module(mod_path:String, args:Array, nodename:String):
	#Global.Print("trying to start %s with arguments %s"%[mod_path,args])
	#Global.Print(module_scripts)
	if module_scripts.has(mod_path):
		var mod:GameModBase = module_scripts[mod_path].new()
		mod.name = nodename
		module_node.add_child(mod)
		mod.on_game_ready(self,multiplayer.is_server())
		mod.on_game_post_ready()
		mod.callv("on_module_start", args)
		Global.Print("started Gamemodule %s" % mod_path)

func _on_tree_entered():
	$MultiplayerSynchronizer.set_multiplayer_authority(1)

# on server/client:
# unpause game
func _on_continue_pressed():
	pause_game.rpc(false)

# on server:
# return everyone to main menu
func _on_return_pressed():
	if multiplayer.is_server():
		return_to_main_menu(false,true)
