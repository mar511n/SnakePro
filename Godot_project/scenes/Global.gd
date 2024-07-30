extends Node

const debug_toast_bg = Color(0, 0, 0, 0.7)
const debug_toast_text = Color(1, 1, 1, 1)
const coll_map_size_standard = 40
const max_snake_path_length = 200
const debugging_on = true

const config_game_params_sec = "GameParams"
const config_player_mods_sec = "PlayerModules"
const config_player_mod_props_sec = "PlayerModuleProperties"
const config_game_mods_sec = "GameModules"
const config_game_mod_props_sec = "GameModuleProperties"
const config_inputmap_sec = "InputMap"

const main_menu_path = "res://scenes/main_menu.tscn"
const maps_dir = "res://scenes/Maps/"
const player_modules_dir = "res://scenes/PlayerMods/"
const game_modules_dir = "res://scenes/GameMods/"
const config_path = "user://config.txt"
const default_game_params = {
	"startSnakeLength"=7.0,
	"snakeSpeed"=8.5,
	"mapPath"=maps_dir+"basic_map1.tscn"
}

var min_prio_debug_print = 2
var min_prio_toast = 5
var first_game_reset = false
var config = ConfigFile.new()

enum hit_causes {
	COLLISION,
	APPLE_DMG
}

enum collision {
	NO,
	WALL,
	PLAYERBODY,
	PLAYERHEAD
}

enum scl {
	alive,
	dead,
	wall
}

func _ready():
	if debugging_on:
		min_prio_toast = 5
	else:
		min_prio_toast = 7

func convert_tilemap_coords(pos1:Vector2i, t1:TileMap, t2:TileMap) -> Vector2i:
	var gp = t1.to_global(t1.map_to_local(pos1))
	return t2.local_to_map(t2.to_local(gp))

func config_set_section_dict(section:String, dict:Dictionary):
	for key in dict:
		config.set_value(section, key, dict[key])

func config_get_section_dict(section, indic = {}) -> Dictionary:
	var dict = indic
	if config.has_section(section):
		for key in config.get_section_keys(section):
			dict[key] = config.get_value(section,key)
	return dict

func get_enabled_mod_paths(sec:String)->Array:
	var en_ms = []
	var mods = Lobby.game_settings.get(sec, {})
	for mod in mods:
		if mods[mod] is Array and len(mods[mod]) > 0 and mods[mod][1]:
			en_ms.append(mods[mod][0])
	return en_ms

func get_property(sec:String, prop:String, default):
	return Lobby.game_settings.get(sec, {}).get(prop, default)

func get_enabled_mods(sec:String)->Array:
	var en_ms = []
	var mods = Lobby.game_settings.get(sec, {})
	for mod in mods:
		if mods[mod] is Array and len(mods[mod]) > 0 and mods[mod][1]:
			en_ms.append(mod)
	return en_ms

func set_inputmap_dict(dic:Dictionary):
	for action in InputMap.get_actions():
		InputMap.erase_action(action)
	for action in dic:
		InputMap.add_action(action)
		for event in dic[action]:
			InputMap.action_add_event(action,event)

func get_inputmap_dict()->Dictionary:
	var dic = {}
	for action in InputMap.get_actions():
		dic[action] = InputMap.action_get_events(action)
	return dic

func Print(v, prio=4):
	if prio >= min_prio_debug_print:
		print(Time.get_time_string_from_system()+": "+str(v))
	if prio >= min_prio_toast:
		ToastParty.show({
			"text": str(v),                     # Text (emojis can be used)
			"bgcolor": debug_toast_bg,          # Background Color
			"color": debug_toast_text,          # Text Color
			"gravity": "bottom",                   # top or bottom
			"direction": "left"               # left or center or right
		})
