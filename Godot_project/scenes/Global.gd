extends Node

const debug_toast_bg:Color = Color(0, 0, 0, 0.7)
const debug_toast_text:Color = Color(1, 1, 1, 1)
const max_snake_path_length:int = 200
const debugging_on:bool = false

const group_name_player_item:StringName = "PlayerItem"

# Dict with  "name":string, "snake_tile_idx":int
const config_player_info_sec:StringName = "PlayerInfo"
# Dict with  "startSnakeLength":int, "snakeSpeed":float, "mapPath":string
const config_game_params_sec:StringName = "GameParams"
# Dict with  modname:[modpath, enabled]
const config_player_mods_sec:StringName = "PlayerModules"
# Dict with  modproperty:modpropertyvalue
const config_player_mod_props_sec:StringName = "PlayerModuleProperties"
# Dict with  modname:[modpath, enabled]
const config_game_mods_sec:StringName = "GameModules"
# Dict with  modproperty:modpropertyvalue
const config_game_mod_props_sec:StringName = "GameModuleProperties"
# Dict with  action:[InputEvents]
const config_inputmap_sec:StringName = "InputMap"
# Dict with stats of local player
const stats_sec:StringName = "Stats"
# Dict with  "inputmethod":"rel"/"abs", "smoothCam": bool, "vsyncMode": 0/1/2/3 (enabled/disabled/adaptive/mailbox)
const config_user_settings_sec:StringName = "UserSettings"

const vsync_modes_map:Dictionary = {0:DisplayServer.VSYNC_ENABLED,1:DisplayServer.VSYNC_DISABLED,2:DisplayServer.VSYNC_ADAPTIVE,3:DisplayServer.VSYNC_MAILBOX}

const splitscreen_modes:Array = [null, Rect2(0,0,0.5,0.5), Rect2(0.5,0,0.5,0.5), Rect2(0,0.5,0.5,0.5), Rect2(0.5,0.5,0.5,0.5)]

const main_menu_path:String = "res://scenes/main_menu.tscn"
const ingame_path:String = "res://scenes/in_game.tscn"
const gameviewer_path:String = "res://scenes/game_viewer.tscn"
const maps_dir:String = "res://scenes/Maps/"
const player_modules_dir:String = "res://scenes/PlayerMods/"
const game_modules_dir:String = "res://scenes/GameMods/"

var config_path:String = "user://config.txt"
var inputconfig_path:String = "user://inputconfig.txt"
var stats_path:String = "user://stats.txt"
var replay_dir_path:String = "user://replays/"

const default_game_params:Dictionary = {
	"startSnakeLength"=7.0,
	"snakeSpeed"=8.5,
	"mapPath"=maps_dir+"basic_map2.tscn"
}

const snake_imgs_path:String = "res://assets/Images/Snakes/"
# source id -> file_path
const snake_tile_files:Dictionary = {
	1:"test.png",
	2:"blue.png",
	3:"red.png",
	4:"yellow.png",
	5:"pink.png",
	6:"bot_black.png"
}
const snake_colors:Array = [Color.BLUE_VIOLET, Color.BLUE, Color.RED, Color("ffff00"), Color.DEEP_PINK,Color.BLACK]

# 0-10 useless print
# 10-30 lots of info, not relevant for player
# 30-50 relevant for developer, but not player
# 50-70 interesting for player
# 70-80 important for player
# 80-90 errors & warnings (game can still work)
# 90-100 critical errors
var min_prio_debug_print:int = 10
var min_prio_toast:int = 50
var first_game_reset:bool = false
var config:ConfigFile = ConfigFile.new()
var inputconfig:ConfigFile = ConfigFile.new()
var stats:ConfigFile = ConfigFile.new()

var has_server_privileges = false

enum hit_causes {
	COLLISION, # infos: {"type":collision, "caused_by_id":int / "wall_v":int}
	APPLE_DMG, # infos: {"caused_by_id":int}
	BULLET,    # infos: {"caused_by_id":int}
	BOT,       # infos: {"caused_by_id":int}
	FART,      # infos: {"caused_by_id":int}
}
const hit_cause_list = [hit_causes.COLLISION, hit_causes.APPLE_DMG, hit_causes.BULLET, hit_causes.BOT, hit_causes.FART]
const hit_cause_names = ["collision", "apple damage", "bullet", "bot", "fart"]

enum collision {
	NO,
	WALL, 
	PLAYERBODY,
	PLAYERHEAD
}
const collision_list = [collision.NO, collision.WALL, collision.PLAYERBODY, collision.PLAYERHEAD]
const collision_names = ["", "wall", "playerbody", "playerhead"]

enum scl {
	alive,
	dead,
	wall
}

func _ready()->void:
	if debugging_on:
		min_prio_toast = 40
	else:
		min_prio_toast = 50

func convert_tilemap_coords(pos1:Vector2i, t1:TileMap, t2:TileMap) -> Vector2i:
	var gp:Vector2 = t1.to_global(t1.map_to_local(pos1))
	return t2.local_to_map(t2.to_local(gp))

func config_set_section_dict(section:String, dict:Dictionary)->void:
	set_section_dict(config, section, dict)

func config_get_section_dict(section:StringName, indic:Dictionary = {}) -> Dictionary:
	return get_section_dict(config, section, indic)

func set_section_dict(cfg:ConfigFile,section:String, dict:Dictionary)->void:
	for key:String in dict:
		cfg.set_value(section, key, dict[key])

func get_section_dict(cfg:ConfigFile,section:StringName, indic:Dictionary = {}) -> Dictionary:
	if cfg.has_section(section):
		for key:String in cfg.get_section_keys(section):
			indic[key] = cfg.get_value(section,key)
	return indic

func get_enabled_mod_paths(sec:String)->Array:
	var en_ms:Array = []
	var mods:Dictionary = Lobby.game_settings.get(sec, {})
	for mod:String in mods:
		if mods[mod] is Array and len(mods[mod]) > 0 and mods[mod][1]:
			en_ms.append(mods[mod][0])
	return en_ms

func get_property(sec:String, prop:String, default:Variant)->Variant:
	return Lobby.game_settings.get(sec, {}).get(prop, default)

func get_enabled_mods(sec:String)->Array:
	var en_ms:Array = []
	var mods:Dictionary = Lobby.game_settings.get(sec, {})
	for mod:String in mods:
		if mods[mod] is Array and len(mods[mod]) > 0 and mods[mod][1]:
			en_ms.append(mod)
	return en_ms

func set_inputmap_dict(dic:Dictionary)->void:
	for action:StringName in InputMap.get_actions():
		InputMap.erase_action(action)
	for action:StringName in dic:
		InputMap.add_action(action)
		for event:InputEvent in dic[action]:
			InputMap.action_add_event(action,event)

func get_inputmap_dict()->Dictionary:
	var dic:Dictionary = {}
	for action:StringName in InputMap.get_actions():
		dic[action] = InputMap.action_get_events(action)
	return dic

func rotate_direction(dir:Vector2i, clockwise:bool)->Vector2i:
	if clockwise:
		return Vector2i(dir.y,-dir.x)
	return Vector2i(-dir.y,dir.x)

func Print(v:Variant, prio:int=25)->void:
	if prio >= min_prio_debug_print:
		var ticks = Time.get_ticks_msec()
		print("%s.%3d, %s: %s" % [Time.get_time_string_from_unix_time(ticks/1000), ticks%1000, prio, str(v)])
	if prio >= min_prio_toast:
		ToastParty.show({
			"text": str(v),                     # Text (emojis can be used)
			"bgcolor": debug_toast_bg,          # Background Color
			"color": debug_toast_text,          # Text Color
			"gravity": "top",                   # top or bottom
			"direction": "left"               # left or center or right
		})

const variable_graphic_group:StringName = "VariableGraphical"
const static_graphic_group:StringName = "StaticGraphical"
const res_path_func_name:StringName = "get_res_path"
const get_data_func_name:StringName = "get_data"
const set_data_func_name:StringName = "set_data"

# stats for the current session (are reset on new connection)
# game_idx -> {peer_id -> {} (except for local player, which has id -1)}
var player_stats = []
# accumulated playerstats over multiple sessions
var own_player_stats = {}

func player_stats_on_game_finished():
	Print("updating/merging player stats on game finish", 40)
	#player_stats[-1] = player_stats.get(multiplayer.get_unique_id(), {})
	own_player_stats = merge_player_stats(own_player_stats,player_stats[-1].get(-1,{}))
	save_own_player_stats()

func player_stats_on_game_start():
	Print("initializing player stats on game start", 40)
	player_stats.append({})

func merge_player_stats(pls1:Dictionary,pls2:Dictionary) -> Dictionary:
	var pls = {"kills":[],"deaths":[],"wins":pls1.get("wins",0)+pls2.get("wins",0)}
	pls["kills"].append_array(pls1.get("kills",[]))
	pls["kills"].append_array(pls2.get("kills",[]))
	pls["deaths"].append_array(pls1.get("deaths",[]))
	pls["deaths"].append_array(pls2.get("deaths",[]))
	return pls

func save_own_player_stats():
	set_section_dict(stats,stats_sec,own_player_stats)#player_stats.get(-1,{}))
	stats.save(stats_path)

func load_own_player_stats():
	#player_stats[-1] = Global.get_section_dict(stats,stats_sec,player_stats.get(-1,{}))
	own_player_stats = Global.get_section_dict(stats,stats_sec,own_player_stats)

func save_resource(from:String, to:String) -> void:
	var file = FileAccess.open(from,FileAccess.READ)
	var txt = file.get_as_text()
	file.close()
	file = FileAccess.open(to,FileAccess.WRITE)
	file.store_string(txt)
	file.close()

# the static gamestate at the start
var static_gamestate:Array
# capture start time
#var capture_start_time:float
# [time in seconds since start, gamestate]
var variable_gamestates:Array

func start_game_state_capture():
	static_gamestate = save_game_state(static_graphic_group)
	variable_gamestates = []
	#capture_start_time = Time.get_unix_time_from_system()
	save_variable_gamestate_if_needed(0.0)

func save_variable_gamestate_if_needed(ingame_time:float):
	var vgs = save_game_state(variable_graphic_group)
	if len(variable_gamestates) == 0 or not compare_gamestates(vgs, variable_gamestates[-1][1]):
		#variable_gamestates.append([Time.get_unix_time_from_system()-capture_start_time, vgs])
		variable_gamestates.append([ingame_time, vgs])

func compare_gamestates(gs1:Array,gs2:Array)->bool:
	if len(gs1) != len(gs2):
		return false
	var eq = true
	for i in range(gs1.size()):
		if (gs1[i][0] != gs2[i][0]) or not gs1[i][1].recursive_equal(gs2[i][1],20):
			eq = false
			break
	return eq

func save_game_state(groupName:StringName)->Array:
	var nodes = get_tree().get_nodes_in_group(groupName)
	var gs = []
	for node in nodes:
		if node.has_method(res_path_func_name) and node.has_method(get_data_func_name):
			var resPath = node.call(res_path_func_name)
			var data = node.call(get_data_func_name)
			gs.append([resPath,data])
		else:
			Print("ERROR in save_game_state: node %s misses function %s or %s" % [node.name, res_path_func_name, get_data_func_name], 85)
	return gs

func load_game_state(parentNode:Node, gs:Array):
	for vis in gs:
		var node:Node = load(vis[0]).instantiate()
		if node.has_method(set_data_func_name):
			node.call(set_data_func_name, vis[1])
			parentNode.add_child(node)
		else:
			Print("ERROR in load_game_state: node %s misses function %s" % [node.name, set_data_func_name], 85)
