extends ItemModBase

var ItemSpeedNewSpeed = 30.0
var ItemSpeedDuration = 0.5

var old_speed = 1.0
var duration = 0.0

var is_used = false

func _init(ghost=false):
	super(ghost)
	item_rel_spawn_prob = Global.get_property(Global.config_player_mod_props_sec, "ItemSpeedProbability", 1)
	item_name = "Speed Boost"
	item_code = "speed"
	name = item_name
	set_meta("name", item_name)
	set_meta("ItemSpeedProbability", [1,0,4,0.1])
	set_meta("ItemSpeedNewSpeed",[ItemSpeedNewSpeed,0,60,1])
	set_meta("ItemSpeedDuration",[ItemSpeedDuration,0,5,0.1])

func on_player_pre_ready(player:SnakePlayer, enabled_mods=[]):
	super(player,enabled_mods)
	ItemSpeedNewSpeed = Global.get_property(Global.config_player_mod_props_sec, "ItemSpeedNewSpeed", ItemSpeedNewSpeed)
	ItemSpeedDuration = Global.get_property(Global.config_player_mod_props_sec, "ItemSpeedDuration", ItemSpeedDuration)

func on_player_physics_process(delta:float):
	if !is_marked_for_removal and !is_used and !pl.module_vars.get("ItemSpeeding",false) and Input.is_action_just_pressed("use_item"):
		pl.SpeedSound.play()
		Global.Print("Player %s used item %s (ghost=%s)" % [pl.peer_id, item_name, is_ghost])
		pl.module_vars["ItemSpeeding"] = true
		is_used = true
		duration = ItemSpeedDuration
		old_speed = pl.get_speed()
		pl.set_speed(ItemSpeedNewSpeed)
		if local_player_gui != null:
			local_player_gui.set_item_ready(local_player_gui_id, false, true)
	elif is_used:
		duration -= delta
		if duration <= 0.0:
			pl.set_speed(old_speed)
			pl.module_vars["ItemSpeeding"] = false
			remove_item()
	elif is_marked_for_removal:
		remove_item()
