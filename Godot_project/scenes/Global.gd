extends Node

const debug_toast_bg = Color(0, 0, 0, 0.7)
const debug_toast_text = Color(1, 1, 1, 1)
const coll_map_size_standard = 40
const max_snake_path_length = 200
const debugging_on = true

# Dict with  "name":string, "snake_tile_idx":int
const config_player_info_sec = "PlayerInfo"
# Dict with  "startSnakeLength":int, "snakeSpeed":float, "mapPath":string
const config_game_params_sec = "GameParams"
# Dict with  modname : [modpath, enabled]
const config_player_mods_sec = "PlayerModules"
# Dict with  modproperty : modpropertyvalue
const config_player_mod_props_sec = "PlayerModuleProperties"
# Dict with  modname : [modpath, enabled]
const config_game_mods_sec = "GameModules"
# Dict with  modproperty : modpropertyvalue
const config_game_mod_props_sec = "GameModuleProperties"
# Dict with  action : [InputEvents]
const config_inputmap_sec = "InputMap"
# Dict with  "inputmethod":"rel"/"abs", "smoothCam": bool, "vsyncMode": 0/1/2/3 (enabled/disabled/adaptive/mailbox)
const config_user_settings_sec = "UserSettings"

const vsync_modes_map = {0:DisplayServer.VSYNC_ENABLED,1:DisplayServer.VSYNC_DISABLED,2:DisplayServer.VSYNC_ADAPTIVE,3:DisplayServer.VSYNC_MAILBOX}

const splitscreen_modes = [null, Rect2(0,0,0.5,0.5), Rect2(0.5,0,0.5,0.5), Rect2(0,0.5,0.5,0.5), Rect2(0.5,0.5,0.5,0.5)]

const main_menu_path = "res://scenes/main_menu.tscn"
const maps_dir = "res://scenes/Maps/"
const player_modules_dir = "res://scenes/PlayerMods/"
const game_modules_dir = "res://scenes/GameMods/"
const config_path = "user://config.txt"
const inputconfig_path = "user://inputconfig.txt"
const default_game_params = {
	"startSnakeLength"=7.0,
	"snakeSpeed"=8.5,
	"mapPath"=maps_dir+"basic_map2.tscn"
}

var min_prio_debug_print = 2
var min_prio_toast = 5
var first_game_reset = false
var config = ConfigFile.new()
var inputconfig = ConfigFile.new()

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
	set_section_dict(config, section, dict)

func config_get_section_dict(section, indic = {}) -> Dictionary:
	return get_section_dict(config, section, indic)

func set_section_dict(cfg:ConfigFile,section:String, dict:Dictionary):
	for key in dict:
		cfg.set_value(section, key, dict[key])

func get_section_dict(cfg:ConfigFile,section, indic = {}) -> Dictionary:
	var dict = indic
	if cfg.has_section(section):
		for key in cfg.get_section_keys(section):
			dict[key] = cfg.get_value(section,key)
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
