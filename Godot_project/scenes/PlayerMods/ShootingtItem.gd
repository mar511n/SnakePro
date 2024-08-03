extends ItemModBase

var ItemShootingSpeed = 20.0
var ItemShootingRange = 10

func _init(ghost=false):
	super(ghost)
	item_rel_spawn_prob = Global.get_property(Global.config_player_mod_props_sec, "ItemShootingProbability", 1)
	item_name = "Shooting"
	item_code = "shot"
	name = item_name
	set_meta("name", item_name)
	set_meta("ItemShootingProbability", [1,0,4,0.1])
	set_meta("ItemShootingSpeed",[ItemShootingSpeed,0,60,1])
	set_meta("ItemShootingRange",[ItemShootingRange,0,30,1])

func on_player_pre_ready(player:SnakePlayer, enabled_mods=[]):
	super(player,enabled_mods)
	ItemShootingSpeed = Global.get_property(Global.config_player_mod_props_sec, "ItemShootingSpeed", ItemShootingSpeed)
	ItemShootingRange = Global.get_property(Global.config_player_mod_props_sec, "ItemShootingRange", ItemShootingRange)

func on_player_physics_process(delta:float):
	if !is_marked_for_removal and Input.is_action_just_pressed("use_item"):
		pl.ShootingSound.play()
		Global.Print("Player %s used item %s (ghost=%s)" % [pl.peer_id, item_name, is_ghost])
		var dir = pl.get_direction_facing()
		if is_ghost:
			var rn = randf()
			if rn < 0.4:
				dir = Global.rotate_direction(dir,true)
			elif rn < 0.8:
				dir = Global.rotate_direction(dir,false)
		pl.IG.start_module.rpc("bullet.gd", [pl.get_head_tile(),dir,ItemShootingSpeed,ItemShootingRange,pl.peer_id])
		mark_for_removal()
	if is_marked_for_removal:
		remove_item()
