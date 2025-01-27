extends GameModBase

var item_drawer : TileMap
var ItemCount : int = 4
var spawnable_items = {}
var cumm_spawn_prob = 0.0
var local_player_item : ItemModBase = null
var lp_ui : Control

var ItemRedrawCounter = 0

const local_player_ui = preload("res://scenes/ModResources/item_player_ui.tscn")

const ItemSpawnTries = 1000

func _init():
	name = "ItemsMod"
	set_meta("name", "Items")
	set_meta("description", "adds items to the game, which can be collected and used by players")
	set_meta("ItemCount", [ItemCount,0,100,1,"number of items in the game"])
	#spawnable_items["baseitem"] = ["BaseItem", 1, preload("res://scenes/PlayerMods/ItemModBase.gd")]

func on_game_ready(g:InGame, g_is_server:bool):
	super(g,g_is_server)
	ItemCount = int(Global.get_property(Global.config_game_mod_props_sec, "ItemCount", ItemCount))
	ItemRedrawCounter = 0
	for mod_path in Global.get_enabled_mod_paths(Global.config_player_mods_sec):
		var mod = load(Global.player_modules_dir+mod_path)
		if mod != null:
			var mi = mod.new()
			if mi.is_in_group(Global.group_name_player_item):
				spawnable_items[mi.item_code] = [mi.item_name, mi.item_rel_spawn_prob, mod]
				cumm_spawn_prob += mi.item_rel_spawn_prob
	var item_drawer_r = preload("res://scenes/ModResources/item_map.tscn")
	if item_drawer_r != null:
		item_drawer = item_drawer_r.instantiate()
		game.add_child(item_drawer)
		item_drawer.scale_to_tile_size(Vector2.ONE*g.tile_size_px)
	
	if is_server:
		game.module_vars["IngameItems"] = {}
		game.module_vars["ItemRedrawCounter"] = 0

func on_game_post_ready():
	var local_pl:SnakePlayer = game.playerlist.get(multiplayer.get_unique_id(), null)
	if is_instance_valid(local_pl):
		Global.Print("Loading ItemGUI for player %s" % local_pl.peer_id, 40)
		lp_ui = local_player_ui.instantiate()
		lp_ui.name = "ItemGUI"
		local_pl.gui_node.add_child(lp_ui)
		
		var player_colors = {}
		var spl_ids = []
		for peer_id in Lobby.players:
			player_colors[peer_id] = Global.snake_colors[Lobby.players[peer_id]["snake_tile_idx"]]
			if peer_id != multiplayer.get_unique_id() and Lobby.players[peer_id].get("mainMultiplayerScreen", false):
				spl_ids.append(peer_id)
		lp_ui.init_stuff(local_pl.is_main_mul_screen,spl_ids,self,player_colors)

	
	if is_server:
		Global.Print("spawning items (from server)", 40)
		for i in range(ItemCount):
			spawn_item()

@rpc("any_peer","call_remote","reliable")
func set_ui_player_item(peer_id:int, item_code:String,spl_rm=false):
	lp_ui.set_player_item(peer_id,item_code,spl_rm)

@rpc("any_peer", "call_local", "reliable")
func spawn_item():
	if !is_server:
		Global.Print("ERROR: spawn_item should only be called on server", 85)
		return
	var pos = Vector2i.ZERO
	for i in range(ItemSpawnTries):
		pos = Vector2i(randi_range(0,game.coll_map.size_x-1),randi_range(0,game.coll_map.size_y-1))
		if not pos in game.module_vars["ApplePositions"] and not game.module_vars["GhostApplePositions"].has(pos) and not pos in game.module_vars["IngameItems"].keys():
			if len(game.tile_check_collisions(pos, [Global.scl.alive,Global.scl.dead,Global.scl.wall],1))==0:
				break
	game.module_vars["IngameItems"][pos] = get_random_item_code()#+"_g"
	game.module_vars["ItemRedrawCounter"] += 1

@rpc("any_peer", "call_local","reliable")
func remove_item(pos:Vector2i):
	if !is_server:
		Global.Print("ERROR: remove_item should only be called on server", 85)
		return
	if game.module_vars["IngameItems"].has(pos):
		game.module_vars["IngameItems"].erase(pos)
		game.module_vars["ItemRedrawCounter"] += 1
		spawn_item()

@rpc("any_peer", "call_local", "reliable")
func ghostify_item(pos:Vector2i):
	if game.module_vars["IngameItems"].has(pos) and not item_code_is_ghost(game.module_vars["IngameItems"][pos]):
		Global.Print("corrupting item at %s"%pos, 40)
		game.module_vars["IngameItems"][pos] += "_g" 
		game.module_vars["ItemRedrawCounter"] += 1

func redraw_items():
	item_drawer.clear_items()
	item_drawer.draw_items(game.module_vars["IngameItems"].keys(), game.module_vars["IngameItems"].values())

func get_random_item_code()->String:
	var rn = randf_range(0,cumm_spawn_prob)
	var n = 0
	for ic in spawnable_items:
		if rn > n and rn < n+spawnable_items[ic][1]:
			return ic
		n += spawnable_items[ic][1]
	return "baseitem"

func item_code_is_ghost(code:String)->bool:
	return code.ends_with("_g")

# gets all collisions that happened and returns which ones are handled
# colls is dictionary peer_id -> [[Global.collision, infos],...]
# returns array with peer_ids of handled collisions
# check if apple is eaten
func on_game_checked_collisions(_colls)->Array:
	for peer_id in game.playerlist:
		check_item_collision_for_local_player.rpc_id(peer_id)
	return []

@rpc("any_peer", "call_local","reliable")
func check_item_collision_for_local_player():
	var player : SnakePlayer = game.playerlist.get(multiplayer.get_unique_id(), null)
	if is_instance_valid(player):
		var head = player.get_head_tile()
		if head in game.module_vars["IngameItems"].keys():
			var ic:String = String(game.module_vars["IngameItems"][head])
			var is_ghost_item = item_code_is_ghost(ic)
			var ic_raw : String = String(ic)
			ic_raw = ic_raw.trim_suffix("_g")
			var mod : ItemModBase = spawnable_items[ic_raw][2].new(is_ghost_item)
			if mod.on_collected_by_player(player):
				player.CollectItemSound.play()
				if is_instance_valid(local_player_item):
					local_player_item.mark_for_removal()
				local_player_item = mod
				player.modules.append(mod)
				mod.on_player_pre_ready(player,[])
				player.module_node.add_child(mod)
				mod.on_player_ready()
				remove_item.rpc_id(1,head)
			elif !is_ghost_item:
				ghostify_item(head)
				ghostify_item.rpc_id(1,head)

func on_game_physics_process(_delta):
	if game.module_vars.get("ItemRedrawCounter",0) != ItemRedrawCounter:
		redraw_items()
		ItemRedrawCounter = game.module_vars.get("ItemRedrawCounter",0)
