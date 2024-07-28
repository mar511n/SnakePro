extends PlModBase

func _init():
	set_meta("name", "Basic hit handler")
	#set_meta("print_hit_cause", [true])

func ready():
	pl.module_vars["pl_alive"] = true
	pl.CollLayers.append(Global.scl.alive)
	pl.CollMasks.append(Global.scl.alive)
	pl.CollMasks.append(Global.scl.wall)

func on_player_hit(_cause:Array):
	pl.module_vars["pl_alive"] = false
	var idx = pl.CollLayers.find(Global.scl.alive)
	if idx >= 0:
		pl.CollLayers.remove_at(idx)
	if not Global.scl.dead in pl.CollLayers:
		pl.CollLayers.append(Global.scl.dead)
	pl.sn_drawer.set_layer_modulate(pl.pl_idx,Color(1.0,1.0,1.0,0.5))
	pl.reset_snake_tiles()

