extends Control


@export_file var game_scene_path : String

# 2d menu nodes
@onready var ConPopup:ConnectionPopupPanel = $ConnectionPopup
@onready var PlList:RichTextLabel = $TabContainer/Main/Background/PlayerList
@onready var StartG_b:TextureButton = $Buttons/VBoxContainer/StartGame
@onready var ConnSet_b:TextureButton = $Buttons/VBoxContainer/ConnectionSettings
@onready var GameSet_b:TextureButton = $Buttons/VBoxContainer/GameSettings
@onready var Disconn_b:TextureButton = $Buttons/VBoxContainer/Disconnect
@onready var UserSettings:UserSettingsPanel = $"TabContainer/User Settings/UserSettings"
@onready var GameSettings:GameSettingsPanel = $"TabContainer/Game Settings/GameSettings"
@onready var InputSettings:ControllSettingsPanel = $"TabContainer/Control Settings/ActionRemapper"
@onready var Statistics:Panel = $TabContainer/Statistics/Statistics
@onready var TabCont:TabContainer = $TabContainer
@onready var ConnStat:ConnectionStatusTexture = $ConnectionStatus

var call_next_process_frame:Array = []

# reset completely at the first time, but keep network otherwise
func _ready()->void:
	if !Global.first_game_reset:
		reset()
		Global.first_game_reset = true
	else:
		initialize()
		show_hide_buttons_and_popups(multiplayer.is_server(), !multiplayer.has_multiplayer_peer())
		update_playernames_list()

func initialize()->void:
	Lobby.player_connected.connect(self.a_player_connected)
	Lobby.connecting_failed.connect(self.connection_failed)
	Lobby.server_disconnected.connect(self.server_disconnected)
	Lobby.player_disconnected.connect(self.player_disconnected)
	Lobby.player_info_updated.connect(self.player_info_updated)
	#load_con_settings()
	load_playerinfo()
	ConPopup.visible = false
	TabCont.current_tab = 0
	#UserSetPopup.visible = false
	#GameSetPopup.visible = false

func reset()->void:
	var arguments = {}
	for argument in OS.get_cmdline_user_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0]] = key_value[1]
	if arguments.has("config"):
		Global.config_path = arguments["config"]
	if arguments.has("inputconfig"):
		Global.inputconfig_path = arguments["inputconfig"]
	if arguments.has("stats"):
		Global.stats_path = arguments["stats"]
	Global.Print("loading config from %s" % Global.config_path, 6)
	if Global.config.load(Global.config_path) != OK:
		Global.Print("WARNING: no config found at %s" % Global.config_path, 7)
	Global.Print("loading inputconfig from %s" % Global.inputconfig_path, 6)
	if Global.inputconfig.load(Global.inputconfig_path) != OK:
		Global.Print("WARNING: no inputconfig found at %s" % Global.inputconfig_path, 7)
	if Global.inputconfig.has_section(Global.config_inputmap_sec):
		Global.set_inputmap_dict(Global.get_section_dict(Global.inputconfig,Global.config_inputmap_sec))
	Global.Print("loading stats from %s" % Global.stats_path, 6)
	if Global.stats.load(Global.stats_path) != OK:
		Global.Print("WARNING: no stats found at %s" % Global.stats_path, 7)
	if Global.stats.has_section(Global.stats_sec):
		Global.load_own_player_stats()
	
	call_next_process_frame.append([update_stuff_from_usetts , [Global.config_get_section_dict(Global.config_user_settings_sec),true]])
	randomize()
	initialize()
	network_reset()
	update_playernames_list()

func network_reset()->void:
	Lobby.reset_network()
	show_hide_buttons_and_popups(false,true)

func show_hide_buttons_and_popups(is_hosting:bool, disconnected:bool=false)->void:
	#Global.Print("show_hide_buttons_and_popups is_hosting %s, disconnected %s")
	if disconnected:
		StartG_b.disabled = false
		ConnSet_b.disabled = false
		Disconn_b.disabled = true
		GameSet_b.disabled = false
		
		#ConPopup.visible = false
		TabCont.set_tab_disabled(2, false)
		ConnStat.set_disconnected()
	elif is_hosting:
		StartG_b.disabled = false
		ConnSet_b.disabled = true
		Disconn_b.disabled = false
		GameSet_b.disabled = false
		
		TabCont.current_tab = 0
		TabCont.set_tab_disabled(2, false)
		ConnStat.set_hosting()
	else:
		StartG_b.disabled = true
		ConnSet_b.disabled = true
		Disconn_b.disabled = false
		GameSet_b.disabled = true
		
		TabCont.current_tab = 0
		TabCont.set_tab_disabled(2, true)
		#GameSetPopup.visible = false
		ConnStat.set_connected_to_server()

func _on_disconnect_pressed()->void:
	network_reset()
	update_playernames_list()

func player_info_updated(_peer_id:int, _pl_info:Dictionary)->void:
	update_playernames_list()

func connection_failed()->void:
	Global.Print("ERROR: connection failed", 7)
	network_reset()

func player_disconnected(peer_id:int)->void:
	Global.Print("Player with id %s disconnected" % peer_id, 6)
	update_playernames_list()

func server_disconnected()->void:
	Global.Print("ERROR: Server disconnected", 7)
	network_reset()

func a_player_connected(peer_id:int, _player_info:Dictionary)->void:
	Global.Print("player joined with id %s and info %s" % [peer_id, _player_info],6)
	update_playernames_list()
	if multiplayer.is_server():
		ConnStat.set_hosting()
	else:
		ConnStat.set_connected_to_server()

func _on_start_game_pressed()->void:
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		#Global.Print("loading game_scene: %s" % game_scene_path)
		Lobby.reset_game_stats.rpc()
		Lobby.load_scene.rpc(game_scene_path)
		#Lobby.scene_spawner.spawn(game_scene_path)

func _on_quit_game_pressed()->void:
	get_tree().quit()

func _on_connection_popup_host(port:int)->void:
	Global.Print("hosting on %s:%s" % [IP.get_local_addresses()[0],port], 6)
	var err:Error = Lobby.create_game()
	if err != OK:
		Global.Print("ERROR while hosting server: %s" % err, 7)
		return
	save_con_settings(false)
	show_hide_buttons_and_popups(true)

func _on_connection_popup_join(ip:String, port:int)->void:
	Global.Print("joining on %s:%s" % [ip,port],6)
	var err:Error = Lobby.join_game(ip,port)
	if err != OK:
		Global.Print("ERROR while connection to server: %s" % err, 7)
		return
	save_con_settings()
	show_hide_buttons_and_popups(false)

func update_playernames_list()->void:
	PlList.clear()
	for peer_id:int in Lobby.players:
		var pl_name = Lobby.players[peer_id]["name"]
		var pl_col = Color.BLACK.to_html()#Global.snake_colors[]
		if Lobby.players[peer_id]["snake_tile_idx"] < len(Global.snake_colors):
			pl_col = Global.snake_colors[Lobby.players[peer_id]["snake_tile_idx"]].to_html()
		if peer_id == multiplayer.get_unique_id():
			PlList.append_text("[center][b][color=%s]%s[/color][/b][/center]" % [pl_col,pl_name])
		else:
			PlList.append_text("[center][color=%s]%s[/color][/center]" % [pl_col,pl_name])
		if Lobby.game_stats.has("Winner") and Lobby.game_stats["Winner"] == peer_id:
			PlList.append_text("    [img=50]res://assets/Images/UI/HallPokal1.png[/img]")
		PlList.append_text("\n")
func _on_connection_settings_pressed()->void:
	if !ConPopup.visible:
		ConPopup.show_popup(Global.config.get_value("conn","ip","127.0.0.1"),Global.config.get_value("conn","port",8080))
	else:
		ConPopup.visible = false

func save_playerinfo()->void:
	Global.config_set_section_dict(Global.config_player_info_sec, Lobby.player_info)
	Global.config.save(Global.config_path)
	Global.Print("saving PlayerInfo %s to config" % Lobby.player_info,6)
	Global.Print("saving config to %s" % Global.config_path)
func load_playerinfo()->void:
	if Global.config.has_section(Global.config_player_info_sec):
		Lobby.player_info = Global.config_get_section_dict(Global.config_player_info_sec)
func save_con_settings(save_ip=true)->void:
	if save_ip:
		Global.config.set_value("conn", "ip", ConPopup.ip_addr)
	Global.config.set_value("conn", "port", ConPopup.port)
	Global.config.save(Global.config_path)
	if save_ip:
		Global.Print("saving IP %s:%s to config" % [ConPopup.ip_addr,ConPopup.port],6)
	Global.Print("saving config to %s" % Global.config_path)
#func load_con_settings()->void:
#	if Global.config.has_section_key("conn", "ip"):
#		ConPopup.ip_addr = Global.config.get_value("conn","ip")
#	if Global.config.has_section_key("conn", "port"):
#		ConPopup.port = Global.config.get_value("conn","port")
func save_usersettings(us:Dictionary)->void:
	Global.config_set_section_dict(Global.config_user_settings_sec, us)
	Global.config.save(Global.config_path)
	Global.Print("saving UserSettings %s to config" % us,6)
	Global.Print("saving config to %s" % Global.config_path)

func _on_user_settings_on_settings_changed(plinfo:Dictionary, usetts:Dictionary)->void:
	Lobby.player_info = plinfo
	if ConnStat.network_connected():
		Lobby.player_info_update.rpc(multiplayer.get_unique_id(),plinfo)
	update_stuff_from_usetts(usetts)
	save_playerinfo()
	save_usersettings(usetts)

func update_stuff_from_usetts(usetts:Dictionary,force_screen_update=false)->void:
	if usetts.has("splitscreenMode") and (force_screen_update or usetts["splitscreenMode"] != Global.config.get_value(Global.config_user_settings_sec, "splitscreenMode", 0)):
		set_splitscreen_mode(usetts["splitscreenMode"])
	if usetts.has("vsyncMode"):
		DisplayServer.window_set_vsync_mode(Global.vsync_modes_map[usetts.get("vsyncMode")])
	if usetts.has("musicvolume"):
		if usetts["musicvolume"] == 0:
			MainThemePlayer.volume_db = -100
		else:
			MainThemePlayer.volume_db = (usetts["musicvolume"]-100.0)*0.4

func dummy_func():
	pass

func set_splitscreen_mode(spm:int)->void:
	var wcs:int = get_tree().root.current_screen
	var wci:int = get_tree().root.get_window_id()
	if spm == 0:
		#if not DisplayServer.window_get_mode(wci) == DisplayServer.WINDOW_MODE_FULLSCREEN:
		call_next_process_frame.append([window_set_mode,[DisplayServer.WINDOW_MODE_FULLSCREEN,wci]])
		call_next_process_frame.append(0.1)
		call_next_process_frame.append([window_set_borderless_ontop,[false,wci]])
	elif spm == 5:
		#if not DisplayServer.window_get_mode(wci) == DisplayServer.WINDOW_MODE_WINDOWED:
		call_next_process_frame.append([window_set_mode,[DisplayServer.WINDOW_MODE_WINDOWED,wci]])
		call_next_process_frame.append(0.1)
		call_next_process_frame.append([window_set_borderless_ontop,[false,wci]])
		
		#call_next_process_frame.append([window_set_size,[DisplayServer.screen_get_size(wcs)/2,wci]])
		#call_next_process_frame.append([window_set_position,[DisplayServer.screen_get_position(wcs),wci]])
	else:
		#if not DisplayServer.window_get_mode(wci) == DisplayServer.WINDOW_MODE_WINDOWED:
		call_next_process_frame.append([window_set_mode,[DisplayServer.WINDOW_MODE_WINDOWED,wci]])
		call_next_process_frame.append(0.1)
		
		call_next_process_frame.append([window_set_borderless_ontop,[true,wci]])
		call_next_process_frame.append(0.1)
		
		call_next_process_frame.append([window_set_mode,[DisplayServer.WINDOW_MODE_WINDOWED,wci]])
		call_next_process_frame.append(0.1)
		
		var wrect : Rect2 = Global.splitscreen_modes[spm]
		var screen_size:Vector2i = DisplayServer.screen_get_size(wcs)
		
		
		#call_next_process_frame.append([window_set_position,[Vector2i(wrect.position*Vector2(screen_size))+DisplayServer.screen_get_position(wcs),wci]])
		#call_next_process_frame.append(1.0)
		#call_next_process_frame.append([window_set_mode,[DisplayServer.WINDOW_MODE_WINDOWED,wci]])
		#call_next_process_frame.append(1.0)
		call_next_process_frame.append([window_set_size,[Vector2i(wrect.size*Vector2(screen_size)),wci]])
		call_next_process_frame.append(0.1)
		call_next_process_frame.append([window_set_mode,[DisplayServer.WINDOW_MODE_WINDOWED,wci]])
		call_next_process_frame.append(0.1)
		call_next_process_frame.append([window_set_position,[Vector2i(wrect.position*Vector2(screen_size))+DisplayServer.screen_get_position(wcs),wci]])
		
		

func window_set_borderless_ontop(bt:bool,wci:int)->void:
	Global.Print("window_set_borderless_ontop: %s" % bt)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, bt,wci)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, bt,wci)

func window_set_mode(mode:DisplayServer.WindowMode,wci:int)->void:
	Global.Print("window_set_mode: %s" % mode)
	DisplayServer.window_set_mode(mode,wci)

func window_set_position(pos:Vector2i,wci:int)->void:
	Global.Print("window_set_position: %s" % pos)
	DisplayServer.window_set_position(pos,wci)

func window_set_size(s:Vector2i,wci:int)->void:
	Global.Print("window_set_size: %s" % s)
	DisplayServer.window_set_size(s,wci)

func _on_user_settings_pressed()->void:
	TabCont.current_tab = 1
	UserSettings.show_popup()
	#if !UserSetPopup.visible:
	#	UserSetPopup.show_popup()
	#else:
	#	UserSetPopup.visible = false

func _on_game_settings_on_settings_changed()->void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		Lobby.update_game_settings_on_server()

func _on_game_settings_pressed()->void:
	TabCont.current_tab = 2
	GameSettings.show_popup()
	#if !GameSetPopup.visible:
	#	GameSetPopup.show_popup()
	#else:
	#	GameSetPopup.visible = false

func _on_home_pressed()->void:
	TabCont.current_tab = 0
	update_playernames_list()

func _on_control_settings_pressed()->void:
	TabCont.current_tab = 3
	InputSettings.button_update()

func _on_action_remapper_remap_done()->void:
	Global.set_section_dict(Global.inputconfig,Global.config_inputmap_sec, Global.get_inputmap_dict())
	Global.inputconfig.save(Global.inputconfig_path)
	Global.Print("saving InputMap to inputconfig",6)
	Global.Print("saving inputconfig to %s" % Global.inputconfig_path)

func _process(delta:float)->void:
	if len(call_next_process_frame) > 0:
		if call_next_process_frame[0] is float:
			call_next_process_frame[0] -= delta
			if call_next_process_frame[0] <= 0:
				call_next_process_frame.remove_at(0)
		else:
			call_next_process_frame[0][0].callv(call_next_process_frame[0][1])
			call_next_process_frame.remove_at(0)


func _on_watch_replay_pressed() -> void:
	Lobby.load_scene(Global.gameviewer_path)

func _on_stats_pressed() -> void:
	TabCont.current_tab = 4
	Statistics.update_stats()
	#InputSettings.button_update()
