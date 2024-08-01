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
# Dict with  "inputmethod":"rel"/"abs", "smoothCam": bool, "vsyncMode": 0/1/2/3 (enabled/disabled/adaptive/mailbox)
const config_user_settings_sec:StringName = "UserSettings"

const vsync_modes_map:Dictionary = {0:DisplayServer.VSYNC_ENABLED,1:DisplayServer.VSYNC_DISABLED,2:DisplayServer.VSYNC_ADAPTIVE,3:DisplayServer.VSYNC_MAILBOX}

const splitscreen_modes:Array = [null, Rect2(0,0,0.5,0.5), Rect2(0.5,0,0.5,0.5), Rect2(0,0.5,0.5,0.5), Rect2(0.5,0.5,0.5,0.5)]

const main_menu_path:String = "res://scenes/main_menu.tscn"
const maps_dir:String = "res://scenes/Maps/"
const player_modules_dir:String = "res://scenes/PlayerMods/"
const game_modules_dir:String = "res://scenes/GameMods/"
const config_path:String = "user://config.txt"
const inputconfig_path:String = "user://inputconfig.txt"
const default_game_params:Dictionary = {
	"startSnakeLength"=7.0,
	"snakeSpeed"=8.5,
	"mapPath"=maps_dir+"basic_map2.tscn"
}

var min_prio_debug_print:int = 2
var min_prio_toast:int = 5
var first_game_reset:bool = false
var config:ConfigFile = ConfigFile.new()
var inputconfig:ConfigFile = ConfigFile.new()

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

func _ready()->void:
	if debugging_on:
		min_prio_toast = 5
	else:
		min_prio_toast = 7

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

func Print(v:Variant, prio:int=4)->void:
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
