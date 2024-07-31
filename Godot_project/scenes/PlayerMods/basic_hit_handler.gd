extends PlModBase

var queued_for_dying = false

func _init():
	name = "Basic hit handler"
	set_meta("name", "Basic hit handler")
	autoload = true
	#set_meta("print_hit_cause", [true])

func on_player_ready():
	pl.module_vars["PlayerIsAlive"] = true
	pl.CollLayers.append(Global.scl.alive)
	pl.CollMasks.append(Global.scl.alive)
	pl.CollMasks.append(Global.scl.wall)

func on_player_hit(_cause:Array):
	queued_for_dying = true

func on_player_physics_process(delta):
	super(delta)
	if queued_for_dying:
		queued_for_dying = false
		pl.module_vars["PlayerIsAlive"] = false
		
		for mod in pl.modules:
			if mod.is_in_group(Global.group_name_player_item):
				mod.mark_for_removal()
		
		var idx = pl.CollLayers.find(Global.scl.alive)
		if idx >= 0:
			pl.CollLayers.remove_at(idx)
		if not Global.scl.dead in pl.CollLayers:
			pl.CollLayers.append(Global.scl.dead)
		pl.sn_drawer.set_layer_modulate(pl.pl_idx,Color(1.0,1.0,1.0,0.5))
		pl.reset_snake_tiles()

