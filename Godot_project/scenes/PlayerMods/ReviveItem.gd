extends ItemModBase

var is_used = false

func _init(ghost=false):
	super(ghost)
	item_rel_spawn_prob = Global.get_property(Global.config_player_mod_props_sec, "ItemReviveProbability", 1)
	item_name = "Revive"
	item_code = "revive"
	name = item_name
	set_meta("name", item_name)
	set_meta("description", "revives the player, if killed")
	set_meta("ItemReviveProbability", [1,0,4,0.1])

func on_collected_by_player(player:SnakePlayer)->bool:
	if !player.module_vars["PlayerIsAlive"]:
		player.ReviveSound.play()
		is_used = true
		Global.Print("revive player %s and mark ReviveItem for removal" % player.peer_id,40)
		if player.module_vars.has("PlayerSetDeadFunc"):
			player.module_vars["PlayerSetDeadFunc"].rpc(false)
		mark_for_removal()
	return true

func on_player_physics_process(_delta:float):
	#if !is_marked_for_removal and !is_used and Input.is_action_just_pressed("use_item"):
	#	pl.ReviveSound.play()
	#	is_used = true
	#	pl.reset_snake_tiles()
	#	mark_for_removal()
	if is_marked_for_removal:
		remove_item()

func on_player_reset_snake_tiles():
	if !is_used and !pl.module_vars["PlayerIsAlive"]:
		pl.ReviveSound.play()
		is_used = true
		Global.Print("dont let player %s die and mark ReviveItem for removal" % pl.peer_id, 40)
		if pl.module_vars.has("PlayerSetDeadFunc"):
			pl.module_vars["PlayerSetDeadFunc"].rpc(false)
		mark_for_removal()
