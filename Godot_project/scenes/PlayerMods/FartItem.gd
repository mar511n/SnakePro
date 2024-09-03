extends ItemModBase

static var fart_num = 0

var ItemFartDuration = 8.0
var ItemFartRadius = 2.5
var ItemFartDamage = 3.0

var is_used = false

func _init(ghost=false):
	super(ghost)
	item_rel_spawn_prob = Global.get_property(Global.config_player_mod_props_sec, "ItemFartProbability", 1)
	item_name = "Fart"
	item_code = "fart"
	name = item_name
	set_meta("name", item_name)
	set_meta("description", "spawns a fart area, which deals damage to players")
	set_meta("ItemFartProbability", [1,0,4,0.1])
	set_meta("ItemFartDuration",[ItemFartDuration,0,20,0.5,"time until the fart despawns"])
	set_meta("ItemFartRadius",[ItemFartRadius,0.5,10.5,1,"radius of the fart area in tiles"])
	set_meta("ItemFartDamage",[ItemFartDamage,0,8,0.2,"damage done to players in the fart area in tiles/second"])

func on_player_pre_ready(player:SnakePlayer, enabled_mods=[]):
	super(player,enabled_mods)
	ItemFartDuration = Global.get_property(Global.config_player_mod_props_sec, "ItemFartDuration", ItemFartDuration)
	ItemFartRadius = Global.get_property(Global.config_player_mod_props_sec, "ItemFartRadius", ItemFartRadius)
	ItemFartDamage = Global.get_property(Global.config_player_mod_props_sec, "ItemFartDamage", ItemFartDamage)

func on_player_physics_process(_delta:float):
	if !is_marked_for_removal and !is_used and Input.is_action_just_pressed("use_item"):
		is_used = true
		local_player_gui.set_item_ready(local_player_gui_id,false)
		pl.FartSound.play()
		Global.Print("Player %s used item %s (ghost=%s)" % [pl.peer_id, item_name, is_ghost], 35)
		pl.IG.start_module.rpc("fart.gd", [pl.peer_id,is_ghost,ItemFartDuration,ItemFartRadius,ItemFartDamage,pl.tiles[0],local_player_gui_id], "Fart_"+str(pl.peer_id)+"_"+str(fart_num))
		fart_num += 1
		mark_for_removal()
	if is_marked_for_removal:
		remove_item(is_used)
