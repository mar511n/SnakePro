extends Panel
class_name GameSettingsPanel

signal on_settings_changed()

@onready var labeledHSlider:PackedScene = preload("res://scenes/labeled_h_slider.tscn")
@onready var labeledButton:PackedScene = preload("res://scenes/labeled_button.tscn")

const pl_set_g:StringName = "PlayerModuleSetting"
const pl_set_mbg:StringName = "PlayerModuleSettingCheckBtn"
const g_set_g:StringName = "GameModuleSetting"
const g_set_mbg:StringName = "GameModuleSettingCheckBtn"

@onready var scrollCont:ScrollContainer = $ScrollContainer
@onready var vflow:VFlowContainer = $ScrollContainer/VFlowContainer
@onready var startSnakeLength:LabeledHSlider = $ScrollContainer/VFlowContainer/startSnakeLength
@onready var snakeSpeed:LabeledHSlider = $ScrollContainer/VFlowContainer/snakeSpeed
@onready var snakeTraceLength:LabeledHSlider = $ScrollContainer/VFlowContainer/snakeTraceLength
@onready var mapPaths_b:OptionButton = $ScrollContainer/VFlowContainer/mapPaths_b
#@onready var mainMulScreen_b:CheckButton = $ScrollContainer/VFlowContainer/MainMultiplayerscreenBtn

var playerModuleProps:Dictionary = {}
var gameModuleProps:Dictionary = {}

func show_popup()->void:
	#print("show_popup 0: %s" % Time.get_time_string_from_system())
	var gs:Dictionary = Global.config_get_section_dict(Global.config_game_params_sec)
	startSnakeLength.set_prop_value(gs.get("startSnakeLength", 3))
	snakeSpeed.set_prop_value(gs.get("snakeSpeed", 4))
	snakeTraceLength.set_prop_value(gs.get("snakeTraceLength", 15))
	#mainMulScreen_b.set_pressed_no_signal(gs.get("isMainMulScreen", false))
	#print("show_popup 1: %s" % Time.get_time_string_from_system())
	update_map_list(gs)
	#print("show_popup 2: %s" % Time.get_time_string_from_system())
	make_game_module_settings()
	set_game_module_settings()
	#print("show_popup 3: %s" % Time.get_time_string_from_system())
	make_player_module_settings()
	set_player_module_settings()
	#print("show_popup 4: %s" % Time.get_time_string_from_system())
	visible = true

func make_game_module_settings()->void:
	clear_game_modules()

	var hsep:HSeparator = HSeparator.new()
	hsep.add_to_group(g_set_g)
	vflow.add_child(hsep)
	var gm_label:Label = Label.new()
	gm_label.add_to_group(g_set_g)
	vflow.add_child(gm_label)
	hsep = HSeparator.new()
	hsep.add_to_group(g_set_g)
	vflow.add_child(hsep)

	var dir:DirAccess = DirAccess.open(Global.game_modules_dir)

	for g_mod_f:String in dir.get_files():
		g_mod_f = g_mod_f.trim_suffix(".remap")
		if g_mod_f.ends_with(".gd"):
			var g_mod_s:Resource = load(Global.game_modules_dir+g_mod_f)
			if g_mod_s != null:
				var g_mod : Object = g_mod_s.new()
				var g_mod_name:String = ""
				var g_mod_description:String = ""
				var props:Dictionary = {}
				for prop:String in g_mod.get_meta_list():
					if prop == "name":
						g_mod_name = g_mod.get_meta(prop)
					elif prop == "description":
						g_mod_description = g_mod.get_meta(prop)
					else:
						props[prop] = g_mod.get_meta(prop)
				if g_mod_name != "":
					add_game_module(g_mod_f, g_mod_name, props, g_mod_description)

	gm_label.text = "Gamemodules ("+str(gameModuleProps.size())+")"
	gm_label.label_settings = LabelSettings.new()
	gm_label.label_settings.font_size = 32
	gm_label.label_settings.outline_size = 10
	gm_label.label_settings.outline_color = Color.RED

	var applyBtn:Button = Button.new()
	applyBtn.text = "Save gamemodule properties"
	applyBtn.pressed.connect(self.on_save_gamemodule_properties)
	applyBtn.add_to_group(g_set_g)
	vflow.add_child(applyBtn)
	#hsep = HSeparator.new()
	#hsep.add_to_group(g_set_g)
	#vflow.add_child(hsep)

func set_game_module_settings()->void:
	var mods:Dictionary = Global.config_get_section_dict(Global.config_game_mods_sec)
	var properties:Dictionary = Global.config_get_section_dict(Global.config_game_mod_props_sec)
	for mod:String in mods:
		if gameModuleProps.has(mod) and mods[mod] is Array and len(mods[mod]) > 1:
			gameModuleProps[mod]["btn"].button_pressed = mods[mod][1]
			for prop:String in gameModuleProps[mod]["props"]:
				if properties.has(prop):
					gameModuleProps[mod]["props"][prop].set_prop_value(properties[prop])

func on_save_gamemodule_properties()->void:
	var mods:Dictionary = {}
	var properties:Dictionary = {}
	for mod:String in gameModuleProps:
		mods[mod] = [gameModuleProps[mod]["path"], gameModuleProps[mod]["btn"].button_pressed]
		for prop:String in gameModuleProps[mod]["props"]:
			properties[prop] = gameModuleProps[mod]["props"][prop].get_prop_value()
	Global.config_set_section_dict(Global.config_game_mods_sec, mods)
	Global.config_set_section_dict(Global.config_game_mod_props_sec, properties)
	Global.Print("saving Gamemodifications and properties to config",6)
	Global.Print("saving config to %s" % Global.config_path)
	Global.config.save(Global.config_path)
	on_settings_changed.emit()

func clear_game_modules()->void:
	gameModuleProps = {}
	for child:Node in vflow.get_children():
		if child.is_in_group(g_set_g):
			vflow.remove_child(child)

func add_game_module(path:String, mname:String, properties:Dictionary,mdescription:String)->void:
	gameModuleProps[mname] = {}
	gameModuleProps[mname]["path"] = path
	gameModuleProps[mname]["name"] = mname
	gameModuleProps[mname]["props"] = {}
	var mod_btn:CheckButton = CheckButton.new()
	mod_btn.text = mname
	mod_btn.tooltip_text = mdescription
	#mod_btn.set_meta("path", path)
	mod_btn.add_to_group(g_set_g)
	#mod_btn.add_to_group(pl_set_mbg)
	vflow.add_child(mod_btn)
	gameModuleProps[mname]["btn"] = mod_btn
	for prop:String in properties:
		if properties[prop][0] is bool:
			var propB:LabeledCheckButton = labeledButton.instantiate()
			propB.add_theme_font_size_override("font_size", 24)
			propB.text = prop
			if properties[prop].size() == 2:
				propB.set_tooltip_text(properties[prop][1])
			propB.set_prop_value(properties[prop][0])
			propB.add_to_group(g_set_g)
			vflow.add_child(propB)
			gameModuleProps[mname]["props"][prop] = propB
		else:
			var propL:Label = Label.new()
			propL.text = prop
			propL.label_settings = LabelSettings.new()
			propL.label_settings.font_size = 24
			if properties[prop].size() == 5:
				propL.set_tooltip_text(properties[prop][4])
				propL.mouse_filter = Control.MOUSE_FILTER_PASS
			#propL.label_settings.outline_size = 6
			#propL.label_settings.outline_color = Color.BLUE
			propL.add_to_group(g_set_g)
			vflow.add_child(propL)
			if properties[prop][0] is float or properties[prop][0] is int:
				var propSl:LabeledHSlider = labeledHSlider.instantiate()
				propSl.min_value = properties[prop][1]
				propSl.max_value = properties[prop][2]
				propSl.step = properties[prop][3]
				propSl.set_prop_value(properties[prop][0])
				propSl.add_to_group(g_set_g)
				vflow.add_child(propSl)
				gameModuleProps[mname]["props"][prop] = propSl
	var hsep:HSeparator = HSeparator.new()
	hsep.add_to_group(g_set_g)
	vflow.add_child(hsep)

func make_player_module_settings()->void:
	clear_player_modules()
	
	var hsep:HSeparator = HSeparator.new()
	hsep.add_to_group(pl_set_g)
	vflow.add_child(hsep)
	var pm_label:Label = Label.new()
	pm_label.label_settings = LabelSettings.new()
	pm_label.label_settings.font_size = 32
	pm_label.label_settings.outline_size = 10
	pm_label.label_settings.outline_color = Color.RED
	pm_label.add_to_group(pl_set_g)
	vflow.add_child(pm_label)
	hsep = HSeparator.new()
	hsep.add_to_group(pl_set_g)
	vflow.add_child(hsep)
	
	var dir:DirAccess = DirAccess.open(Global.player_modules_dir)
	for pl_mod_f:String in dir.get_files():
		pl_mod_f = pl_mod_f.trim_suffix(".remap")
		if pl_mod_f.ends_with(".gd"):
			var pl_mod_s:Resource = load(Global.player_modules_dir+pl_mod_f)
			if pl_mod_s != null:
				var pl_mod : Object = pl_mod_s.new()
				var pl_mod_name:String = ""
				var pl_mod_description:String = ""
				var props:Dictionary = {}
				for prop:String in pl_mod.get_meta_list():
					if prop == "name":
						pl_mod_name = pl_mod.get_meta(prop)
					elif prop == "description":
						pl_mod_description = pl_mod.get_meta(prop)
					else:
						props[prop] = pl_mod.get_meta(prop)
				if pl_mod_name != "":
					add_player_module(pl_mod_f, pl_mod_name, props, pl_mod_description)
	pm_label.text = "Playermodules ("+str(playerModuleProps.size())+")"
	
	var applyBtn:Button = Button.new()
	applyBtn.text = "Save playermodule properties"
	applyBtn.pressed.connect(self.on_save_playermodule_properties)
	applyBtn.add_to_group(pl_set_g)
	vflow.add_child(applyBtn)
	
	hsep = HSeparator.new()
	hsep.add_to_group(pl_set_g)
	vflow.add_child(hsep)

func set_player_module_settings()->void:
	var mods:Dictionary = Global.config_get_section_dict(Global.config_player_mods_sec)
	var properties:Dictionary = Global.config_get_section_dict(Global.config_player_mod_props_sec)
	for mod:String in mods:
		if playerModuleProps.has(mod) and mods[mod] is Array and len(mods[mod]) > 1:
			playerModuleProps[mod]["btn"].button_pressed = mods[mod][1]
			for prop:String in playerModuleProps[mod]["props"]:
				if properties.has(prop):
					playerModuleProps[mod]["props"][prop].set_prop_value(properties[prop])

func on_save_playermodule_properties()->void:
	var mods:Dictionary = {}
	var properties:Dictionary = {}
	for mod:String in playerModuleProps:
		mods[mod] = [playerModuleProps[mod]["path"], playerModuleProps[mod]["btn"].button_pressed]
		for prop:String in playerModuleProps[mod]["props"]:
			properties[prop] = playerModuleProps[mod]["props"][prop].get_prop_value()
	Global.config_set_section_dict(Global.config_player_mods_sec, mods)
	Global.config_set_section_dict(Global.config_player_mod_props_sec, properties)
	Global.Print("saving Playermodifications and properties to config",6)
	Global.Print("saving config to %s" % Global.config_path)
	Global.config.save(Global.config_path)
	on_settings_changed.emit()

func clear_player_modules()->void:
	playerModuleProps = {}
	for child:Node in vflow.get_children():
		if child.is_in_group(pl_set_g):
			vflow.remove_child(child)

func add_player_module(path:String, mname:String, properties:Dictionary, mdescription:String)->void:
	playerModuleProps[mname] = {}
	playerModuleProps[mname]["path"] = path
	playerModuleProps[mname]["name"] = mname
	playerModuleProps[mname]["props"] = {}
	var mod_btn:CheckButton = CheckButton.new()
	mod_btn.text = mname
	mod_btn.tooltip_text = mdescription
	#mod_btn.set_meta("path", path)
	mod_btn.add_to_group(pl_set_g)
	#mod_btn.add_to_group(pl_set_mbg)
	vflow.add_child(mod_btn)
	playerModuleProps[mname]["btn"] = mod_btn
	for prop:String in properties:
		if properties[prop][0] is bool:
			var propB:LabeledCheckButton = labeledButton.instantiate()
			propB.add_theme_font_size_override("font_size", 24)
			propB.text = prop
			if properties[prop].size() == 2:
				propB.set_tooltip_text(properties[prop][1])
			propB.set_prop_value(properties[prop][0])
			propB.add_to_group(pl_set_g)
			vflow.add_child(propB)
			playerModuleProps[mname]["props"][prop] = propB
		else:
			var propL:Label = Label.new()
			propL.text = prop
			propL.label_settings = LabelSettings.new()
			propL.label_settings.font_size = 24
			if properties[prop].size() == 5:
				propL.set_tooltip_text(properties[prop][4])
				propL.mouse_filter = Control.MOUSE_FILTER_PASS
			#propL.label_settings.outline_size = 6
			#propL.label_settings.outline_color = Color.BLUE
			propL.add_to_group(pl_set_g)
			vflow.add_child(propL)
			if properties[prop][0] is float or properties[prop][0] is int:
				var propSl:LabeledHSlider = labeledHSlider.instantiate()
				propSl.min_value = properties[prop][1]
				propSl.max_value = properties[prop][2]
				propSl.step = properties[prop][3]
				propSl.set_prop_value(properties[prop][0])
				propSl.add_to_group(pl_set_g)
				vflow.add_child(propSl)
				playerModuleProps[mname]["props"][prop] = propSl
	var hsep:HSeparator = HSeparator.new()
	hsep.add_to_group(pl_set_g)
	vflow.add_child(hsep)

func update_map_list(gs:Dictionary)->void:
	var mapdir:DirAccess = DirAccess.open(Global.maps_dir)
	mapPaths_b.clear()
	var id:int = 0
	var files = []
	for map:String in mapdir.get_files():
		map = map.trim_suffix(".remap")
		if map.ends_with(".tscn") and not map in files:
			files.append(map)
			mapPaths_b.add_item(map, id)
			if map == gs.get("mapPath", Global.default_game_params["mapPath"]).split("/")[-1]:
				mapPaths_b.selected = id
			id += 1

func make_settings_dict() -> Dictionary:
	var gs:Dictionary = {}
	gs["startSnakeLength"] = startSnakeLength.value
	gs["snakeSpeed"] = snakeSpeed.value
	gs["snakeTraceLength"] = snakeTraceLength.value
	gs["mapPath"] = Global.maps_dir+mapPaths_b.get_item_text(mapPaths_b.get_selected_id())
	#gs["isMainMulScreen"] = mainMulScreen_b.button_pressed
	return gs

func _on_settings_changed()->void:
	var gs:Dictionary = make_settings_dict()
	Global.config_set_section_dict(Global.config_game_params_sec, gs)
	Global.config.save(Global.config_path)
	Global.Print("saving GameParams %s to config" % gs,6)
	Global.Print("saving config to %s" % Global.config_path)
	on_settings_changed.emit()

func _on_snake_speed_drag_ended(_value_changed:float)->void:
	_on_settings_changed()

func _on_start_snake_length_drag_ended(_value_changed:float)->void:
	_on_settings_changed()

func _on_map_paths_b_item_selected(_index:int)->void:
	_on_settings_changed()

func _on_file_dialog_file_selected(path:String)->void:
	var success:bool = ProjectSettings.load_resource_pack(path, true)
	if success:
		Global.Print("loading Mod successful",6)
		update_map_list(Global.config_get_section_dict(Global.config_game_params_sec))
		make_game_module_settings()
		set_game_module_settings()
		make_player_module_settings()
		set_player_module_settings()
	else:
		Global.Print("loading Mod unsuccessful",6)

func _on_button_pressed()->void:
	$FileDialog.show()


func _on_scroll_container_resized()->void:
	if scrollCont != null and vflow != null:
		vflow.custom_minimum_size = scrollCont.size


func _on_main_multiplayerscreen_btn_toggled(_toggled_on: bool) -> void:
	_on_settings_changed()


func _on_snake_trace_length_drag_ended(_value_changed: bool) -> void:
	_on_settings_changed()
