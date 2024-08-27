extends GameModBase

const fd = preload("res://scenes/ModResources/FartDrawer.tscn")

var update_period = 1.0
var owner_peer_id : int
var fart_drawer : Node2D

var is_ghost : bool
var fart_id : int
var alive_time = 10.0
var max_alive_time = 10.0
var gui_id = 0

var position = Vector2i.ZERO
var radius : int = 2
var coll_rect : Rect2i

var active = true

var time_since_last_update = 0.0

func _init() -> void:
	pass
	#name = "Bullet"

func on_module_start(owner_id:int, ghost:bool, duration:float, rad:float, damage:float, pos:Vector2i, local_player_gui_id:int):
	Global.Print("spawning fart of player %s"%owner_id)
	owner_peer_id = owner_id
	is_ghost = ghost
	update_period = 1.0/damage
	alive_time = duration
	max_alive_time = duration
	position = pos
	radius = rad
	gui_id = local_player_gui_id
	coll_rect = Rect2i(pos-Vector2i.ONE*int(rad-0.5),Vector2i.ONE*int(2*rad))
	fart_id = fart_drawer.add_fart()
	fart_drawer.set_radius(fart_id, radius)
	fart_drawer.set_pos(fart_id, game.sn_drawer.to_global(game.sn_drawer.map_to_local(pos)))
	fart_drawer.set_ghost(fart_id, is_ghost)

func on_game_ready(g:InGame, g_is_server:bool):
	super(g,g_is_server)
	fart_drawer = null
	for child in game.get_children():
		if child.name == "FartDrawer":
			fart_drawer = child
			#Global.Print("found BulletDrawer")
	if not is_instance_valid(fart_drawer):
		fart_drawer = fd.instantiate()
		game.add_child(fart_drawer)
		#Global.Print("instantiated BulletDrawer")
		fart_drawer.scale_to_tile_size(game.tile_size_px*Vector2.ONE)

func on_game_physics_process(delta):
	super(delta)
	if !active:
		return
	time_since_last_update += delta
	alive_time -= delta
	if time_since_last_update > update_period:
		time_since_last_update = fmod(time_since_last_update,update_period)
		if is_server and alive_time <= 0:
			remove_fart.rpc()
			return
		if is_server:
			check_collision()
		# handle collision only on server

func check_collision():
	#if game.coll_map.collides_at(pos.x,pos.y) != 0:
		#return
	for peer_id in game.playerlist:
		if peer_id != owner_peer_id and coll_rect.has_point(game.playerlist[peer_id].tiles[-1]):
			var survives = game.playerlist[peer_id].has_enough_tiles(1)
			if survives:
				game.playerlist[peer_id].remove_tiles_from_tail.rpc_id(peer_id,1)
			else:
				game.playerlist[peer_id].hit.rpc([Global.hit_causes.FART, {"caused_by_id":owner_peer_id}])

@rpc("authority", "call_local", "reliable")
func remove_fart():
	active = false
	if owner_peer_id == multiplayer.get_unique_id():
		var local_player_gui = game.playerlist[owner_peer_id].gui_node.get_node("ItemGUI")
		if local_player_gui != null:
			local_player_gui.remove_item(gui_id)
		else:
			Global.Print("ERROR: ItemGUI node not found in player", 7)
	fart_drawer.remove_fart(fart_id)
	remove_module()
