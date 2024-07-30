extends Control


@export_file var game_scene_path : String

# 2d menu nodes
@onready var ConPopup = $ConnectionPopup
@onready var PlList = $TabContainer/Main/Background/PlayerList
@onready var StartG_b = $Buttons/VBoxContainer/StartGame
@onready var ConnSet_b = $Buttons/VBoxContainer/ConnectionSettings
@onready var GameSet_b = $Buttons/VBoxContainer/GameSettings
@onready var Disconn_b = $Buttons/VBoxContainer/Disconnect
@onready var UserSettings = $"TabContainer/User Settings/UserSettings"
@onready var GameSettings = $"TabContainer/Game Settings/GameSettings"
@onready var InputSettings = $"TabContainer/Control Settings/ActionRemapper"
@onready var TabCont = $TabContainer
@onready var ConnStat = $ConnectionStatus

# reset completely at the first time, but keep network otherwise
func _ready():
	if !Global.first_game_reset:
		reset()
		Global.first_game_reset = true
	else:
		initialize()
		show_hide_buttons_and_popups(multiplayer.is_server(), !multiplayer.has_multiplayer_peer())
		update_playernames_list()

func initialize():
	Lobby.player_connected.connect(self.a_player_connected)
	Lobby.connecting_failed.connect(self.connection_failed)
	Lobby.server_disconnected.connect(self.server_disconnected)
	Lobby.player_disconnected.connect(self.player_disconnected)
	Lobby.player_info_updated.connect(self.player_info_updated)
	load_con_settings()
	load_usersettings()
	ConPopup.visible = false
	TabCont.current_tab = 0
	#UserSetPopup.visible = false
	#GameSetPopup.visible = false

func reset():
	Global.Print("loading config from %s" % Global.config_path, 5)
	if Global.config.load(Global.config_path) != OK:
		Global.Print("ERROR while loading config from %s" % Global.config_path, 7)
	if Global.config.has_section(Global.config_inputmap_sec):
		Global.set_inputmap_dict(Global.config_get_section_dict(Global.config_inputmap_sec))
	randomize()
	initialize()
	network_reset()
	update_playernames_list()

func network_reset():
	Lobby.reset_network()
	show_hide_buttons_and_popups(false,true)

func show_hide_buttons_and_popups(is_hosting:bool, disconnected=false):
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

func _on_disconnect_pressed():
	network_reset()
	update_playernames_list()

func player_info_updated(_peer_id, _pl_info):
	update_playernames_list()

func connection_failed():
	Global.Print("ERROR: connection failed", 7)
	network_reset()

func player_disconnected(peer_id):
	Global.Print("Player with id %s disconnected" % peer_id, 6)
	update_playernames_list()

func server_disconnected():
	Global.Print("ERROR: Server disconnected", 7)
	network_reset()

func a_player_connected(peer_id, _player_info):
	Global.Print("player joined with id %s and info %s" % [peer_id, _player_info],6)
	update_playernames_list()
	if multiplayer.is_server():
		ConnStat.set_hosting()
	else:
		ConnStat.set_connected_to_server()

func _on_start_game_pressed():
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		Global.Print("loading game_scene: %s" % game_scene_path, 5)
		Lobby.load_scene.rpc(game_scene_path)

func _on_quit_game_pressed():
	get_tree().quit()

func _on_connection_popup_host(port):
	Global.Print("hosting on %s" % port, 6)
	var err = Lobby.create_game()
	if err != OK:
		Global.Print("ERROR while hosting server: %s" % err, 7)
		return
	save_con_settings()
	show_hide_buttons_and_popups(true)

func _on_connection_popup_join(ip, port):
	Global.Print("joining on %s:%s" % [ip,port],6)
	var err = Lobby.join_game(ip,port)
	if err != OK:
		Global.Print("ERROR while connection to server: %s" % err, 7)
		return
	save_con_settings()
	show_hide_buttons_and_popups(false)

func update_playernames_list():
	PlList.clear()
	for peer_id in Lobby.players:
		if peer_id == multiplayer.get_unique_id():
			PlList.append_text("[center][b]%s[/b][/center]\n" % Lobby.players[peer_id]["name"])
		else:
			PlList.append_text("[center]%s[/center]\n" % Lobby.players[peer_id]["name"])

func _on_connection_settings_pressed():
	if !ConPopup.visible:
		ConPopup.show_popup()
	else:
		ConPopup.visible = false

func save_usersettings():
	Global.config_set_section_dict("UserSettings", Lobby.player_info)
	Global.config.save(Global.config_path)
	Global.Print("saving UserSettings %s to config" % Lobby.player_info,6)
	Global.Print("saving config to %s" % Global.config_path)
func load_usersettings():
	if Global.config.has_section("UserSettings"):
		Lobby.player_info = Global.config_get_section_dict("UserSettings")
func save_con_settings():
	Global.config.set_value("conn", "ip", ConPopup.ip_addr)
	Global.config.set_value("conn", "port", ConPopup.port)
	Global.config.save(Global.config_path)
	Global.Print("saving IP %s:%s to config" % [ConPopup.ip_addr,ConPopup.port],6)
	Global.Print("saving config to %s" % Global.config_path)
func load_con_settings():
	if Global.config.has_section_key("conn", "ip"):
		ConPopup.ip_addr = Global.config.get_value("conn","ip")
	if Global.config.has_section_key("conn", "port"):
		ConPopup.port = Global.config.get_value("conn","port")


func _on_user_settings_on_settings_changed(settings):
	Lobby.player_info = settings
	if ConnStat.network_connected():
		Lobby.player_info_update.rpc(multiplayer.get_unique_id(),settings)
	save_usersettings()

func _on_user_settings_pressed():
	TabCont.current_tab = 1
	UserSettings.show_popup()
	#if !UserSetPopup.visible:
	#	UserSetPopup.show_popup()
	#else:
	#	UserSetPopup.visible = false

func _on_game_settings_on_settings_changed():
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		Lobby.update_game_settings_on_server()

func _on_game_settings_pressed():
	TabCont.current_tab = 2
	GameSettings.show_popup()
	#if !GameSetPopup.visible:
	#	GameSetPopup.show_popup()
	#else:
	#	GameSetPopup.visible = false

func _on_home_pressed():
	TabCont.current_tab = 0
	update_playernames_list()

func _on_control_settings_pressed():
	TabCont.current_tab = 3
	InputSettings.button_update()

func _on_action_remapper_remap_done():
	Global.config_set_section_dict(Global.config_inputmap_sec, Global.get_inputmap_dict())
	Global.config.save(Global.config_path)
	Global.Print("saving InputMap to config",6)
	Global.Print("saving config to %s" % Global.config_path)
