extends ItemModBase

static var bot_num = 0

var ItemBotSpeed = 4.0
var ItemBotUseAstar = true
var ItemBotLength = 6
var ItemBotDuration = 10.0

var is_used = false

func _init(ghost=false):
	super(ghost)
	item_rel_spawn_prob = Global.get_property(Global.config_player_mod_props_sec, "ItemBotProbability", 1)
	item_name = "Bot"
	item_code = "bot"
	name = item_name
	set_meta("name", item_name)
	set_meta("ItemBotProbability", [1,0,4,0.1])
	set_meta("ItemBotSpeed",[ItemBotSpeed,0,40,1])
	set_meta("ItemBotLength",[ItemBotLength,0,60,1])
	set_meta("ItemBotDuration",[ItemBotDuration,0,60,1])
	set_meta("ItemBotUseAstar",[ItemBotUseAstar])

func on_player_pre_ready(player:SnakePlayer, enabled_mods=[]):
	super(player,enabled_mods)
	ItemBotSpeed = Global.get_property(Global.config_player_mod_props_sec, "ItemBotSpeed", ItemBotSpeed)
	ItemBotLength = Global.get_property(Global.config_player_mod_props_sec, "ItemBotLength", ItemBotLength)
	ItemBotDuration = Global.get_property(Global.config_player_mod_props_sec, "ItemBotDuration", ItemBotDuration)
	ItemBotUseAstar = Global.get_property(Global.config_player_mod_props_sec, "ItemBotUseAstar", ItemBotUseAstar)

func on_player_physics_process(_delta:float):
	if !is_marked_for_removal and !is_used and Input.is_action_just_pressed("use_item"):
		#pl.ShootingSound.play()
		Global.Print("Player %s used item %s (ghost=%s)" % [pl.peer_id, item_name, is_ghost])
		pl.IG.start_module.rpc("bot.gd", [pl.peer_id,is_ghost,ItemBotSpeed,ItemBotLength,ItemBotUseAstar,ItemBotDuration], "Bot_"+str(pl.peer_id)+"_"+str(bot_num))
		bot_num += 1
		mark_for_removal()
	if is_marked_for_removal:
		remove_item()
