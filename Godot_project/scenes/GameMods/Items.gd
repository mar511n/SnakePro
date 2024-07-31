extends GameModBase

var item_drawer : TileMap
var ItemCount : int = 4
var spawnable_items = {}
var cumm_spawn_prob = 0.0
var local_player_item : ItemModBase = null

var ItemRedrawCounter = 0

const local_player_ui = preload("res://scenes/ModResources/item_player_ui.tscn")

const ItemSpawnTries = 1000

func _init():
	name = "ItemsMod"
	set_meta("name", "Items")
	set_meta("ItemCount", [ItemCount,0,100,1])
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
	
	var local_pl:SnakePlayer = g.playerlist.get(multiplayer.get_unique_id(), null)
	var lp_ui = local_player_ui.instantiate()
	lp_ui.name = "ItemGUI"
	local_pl.gui_node.add_child(lp_ui)
	
	if is_server:
		game.module_vars["IngameItems"] = {}
		game.module_vars["ItemRedrawCounter"] = 0

func on_game_post_ready():
	if is_server:
		Global.Print("spawning items")
		for i in range(ItemCount):
			spawn_item()

@rpc("any_peer", "call_local", "reliable")
func spawn_item():
	if !is_server:
		Global.Print("ERROR: spawn_item should only be called on server")
		return
	var pos = Vector2i.ZERO
	for i in range(ItemSpawnTries):
		pos = Vector2i(randi_range(0,game.coll_map.size_x),randi_range(0,game.coll_map.size_y))
		if not pos in game.module_vars["ApplePositions"] and not pos in game.module_vars["GhostApplePositions"] and not pos in game.module_vars["IngameItems"].keys():
			if len(game.tile_check_collisions(pos, [Global.scl.alive,Global.scl.dead,Global.scl.wall],1))==0:
				break
	game.module_vars["IngameItems"][pos] = get_random_item_code()
	game.module_vars["ItemRedrawCounter"] += 1

@rpc("any_peer", "call_local","reliable")
func remove_item(pos:Vector2i):
	if !is_server:
		Global.Print("ERROR: remove_item should only be called on server")
		return
	if game.module_vars["IngameItems"].has(pos):
		game.module_vars["IngameItems"].erase(pos)
		game.module_vars["ItemRedrawCounter"] += 1
		spawn_item()

@rpc("any_peer", "call_local", "reliable")
func ghostify_item(pos:Vector2i):
	if game.module_vars["IngameItems"].has(pos):
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
	var player = game.playerlist.get(multiplayer.get_unique_id(), null)
	if player != null:
		var head = player.get_head_tile()
		if head in game.module_vars["IngameItems"].keys():
			var item_code = game.module_vars["IngameItems"][head]
			if player.module_vars["PlayerIsAlive"]:
				#Global.Print("fett += %s" % AppleNutrition, 7)
				#player.fett += AppleNutrition
				if local_player_item != null:
					local_player_item.mark_for_removal()
				var mod = spawnable_items[item_code.trim_suffix("_g")][2].new(item_code_is_ghost(item_code))
				local_player_item = mod
				player.modules.append(mod)
				mod.on_player_pre_ready(player,[])
				player.module_node.add_child(mod)
				mod.on_player_ready()
				remove_item.rpc_id(1,head)
			else:
				if !item_code_is_ghost(item_code):
					ghostify_item.rpc_id(1,head)

func on_game_physics_process(_delta):
	if game.module_vars.get("ItemRedrawCounter",0) != ItemRedrawCounter:
		redraw_items()
		ItemRedrawCounter = game.module_vars.get("ItemRedrawCounter",0)
