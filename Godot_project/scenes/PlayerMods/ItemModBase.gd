extends PlModBase
class_name ItemModBase

# display name
var item_name = "BaseItem"
# used for the tilemap
var item_code = "baseitem"
# relativ item spawn probability
var item_rel_spawn_prob = 1

var is_ghost = false
var is_marked_for_removal = false

var local_player_gui_id = 0
var local_player_gui = null

# should set item_name, item_code (from script name) and item_rel_spawn_prob (from Globals) (also set metadata)
func _init(ghost=false):
	add_to_group(Global.group_name_player_item)
	autoload = false
	is_ghost = ghost

# called when a player (dead/alive) collects the item, should return, if the item is collected
func on_collected_by_player(player:SnakePlayer)->bool:
	return player.module_vars["PlayerIsAlive"]

func mark_for_removal():
	is_marked_for_removal = true

func remove_item():
	Global.Print("Removing item %s from player %s" % [item_name, pl.peer_id])
	if local_player_gui != null:
		local_player_gui.remove_item(local_player_gui_id)
	pl.module_node.remove_child(self)
	var idx = pl.modules.find(self)
	if idx >= 0:
		pl.modules.remove_at(idx)
	queue_free()

func on_player_physics_process(_delta:float):
	if is_marked_for_removal:
		remove_item()

func on_player_ready():
	super()
	Global.Print("Player %s collected item %s (ghost=%s)" % [pl.peer_id, item_name, is_ghost], 6)
	
	local_player_gui = pl.gui_node.get_node("ItemGUI")
	if local_player_gui != null:
		local_player_gui_id = local_player_gui.add_item(item_code,true,true)
	else:
		Global.Print("ERROR: ItemGUI node not found in player", 7)
	
	if item_code == "baseitem":
		remove_item()
