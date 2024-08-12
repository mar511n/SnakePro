extends PlModBase

var recheck_alive_pl_timer = 0
var recheck_alive_pl = false
var MaxTimeBeforeGameover = 2

func _init():
	name = "Basic hit handler"
	set_meta("name", "Basic hit handler")
	set_meta("MaxTimeBeforeGameover", [2,0.2,10,0.2])
	autoload = true
	#set_meta("print_hit_cause", [true])

func on_player_ready():
	pl.module_vars["PlayerIsAlive"] = true
	pl.module_vars["PlayerSetDeadFunc"] = set_player_dead
	MaxTimeBeforeGameover = Global.get_property(Global.config_game_mod_props_sec, "MaxTimeBeforeGameover", 2)
	pl.CollLayers.append(Global.scl.alive)
	pl.CollMasks.append(Global.scl.alive)
	pl.CollMasks.append(Global.scl.wall)

# this is called on every client if any player dies
func on_player_hit(_cause:Array):
	#queued_for_dying = true
	set_player_dead(true)
	pl.reset_snake_tiles()
	if not recheck_alive_pl and pl.IG.multiplayer.is_server() and pl.IG.get_alive_players() <= 1:
		recheck_alive_pl = true
		recheck_alive_pl_timer = MaxTimeBeforeGameover

func on_player_physics_process(delta):
	if recheck_alive_pl:
		recheck_alive_pl_timer -= delta
		if recheck_alive_pl_timer <= 0:
			recheck_alive_pl = false
			if pl.IG.get_alive_players() <= 1:
				pl.IG.return_to_main_menu(false,true)
#func on_player_physics_process(delta):
#	super(delta)
#	if queued_for_dying:
#		queued_for_dying = false
#		set_player_dead(true)
#		pl.reset_snake_tiles()

@rpc("any_peer", "call_local", "reliable")
func set_player_dead(dead:bool)->void:
	Global.Print("setting player %s to dead=%s" % [pl.peer_id,dead])
	pl.module_vars["PlayerIsAlive"] = !dead
	if dead:
		for mod in pl.modules:
			if mod.is_in_group(Global.group_name_player_item):
				mod.mark_for_removal()
		
		var idx = pl.CollLayers.find(Global.scl.alive)
		if idx >= 0:
			pl.CollLayers.remove_at(idx)
		if not Global.scl.dead in pl.CollLayers:
			pl.CollLayers.append(Global.scl.dead)
		pl.sn_drawer.set_layer_modulate(pl.pl_idx,Color(1.0,1.0,1.0,0.5))
		pl.DeadSound.play()
		#pl.reset_snake_tiles()
	else:
		var idx = pl.CollLayers.find(Global.scl.dead)
		if idx >= 0:
			pl.CollLayers.remove_at(idx)
		if not Global.scl.alive in pl.CollLayers:
			pl.CollLayers.append(Global.scl.alive)
		pl.sn_drawer.set_layer_modulate(pl.pl_idx,Color(1.0,1.0,1.0,1.0))
