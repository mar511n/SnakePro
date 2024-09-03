extends Control

const shader_processing = preload("res://assets/Shader/shader_processing.tres")
const shader_ready = preload("res://assets/Shader/shader_ready.tres")

var item_counter = 0
var is_in_splitscreen_mode = false
var pl_colors : Dictionary
var pl_itmIs : Dictionary
var pl_items : Dictionary
var local_peer_id : int
var itm_class : GameModBase
var split_screen_ids:Array = []
var block_next_remove = false

const items_path = "res://assets/Images/Items/"
const item_code_to_texture = {
	"baseitem":preload("res://assets/Images/Items/unknown.png"),
	#"bomb":preload("res://assets/Images/Items/bomb.png"),
	"bot":preload("res://assets/Images/Items/bot.png"),
	"fart":preload("res://assets/Images/Items/fart.png"),
	"shot":preload("res://assets/Images/Items/laser.png"),
	"speed":preload("res://assets/Images/Items/speed.png"),
	"revive":preload("res://assets/Images/Items/revive.png"),
	"baseitem_g":preload("res://assets/Images/Items/unknown.png"),
	#"bomb_g":preload("res://assets/Images/Items/bomb_G.png"),
	"bot_g":preload("res://assets/Images/Items/bot_G.png"),
	"fart_g":preload("res://assets/Images/Items/fart_G.png"),
	"shot_g":preload("res://assets/Images/Items/laser_G.png"),
	"speed_g":preload("res://assets/Images/Items/speed_G.png"),
	"revive_g":preload("res://assets/Images/Items/revive.png"),
}
@onready var hbox = $HBoxContainer
@onready var back = $Panel

func init_stuff(splitscreen:bool, spl_ids:Array, Items:GameModBase, playercolors:Dictionary={}):
	split_screen_ids = spl_ids
	itm_class = Items
	local_peer_id = multiplayer.get_unique_id()
	if splitscreen:
		pl_colors = playercolors
		pl_itmIs = {}
		pl_items = {}
		for peer_id in playercolors:
			pl_items[peer_id] = ""
			pl_itmIs[peer_id] = add_new_item("")
		is_in_splitscreen_mode = true

func add_item(item_code:String, is_ready=true)->int:
	if is_ready:
		for pid in split_screen_ids:
			itm_class.set_ui_player_item.rpc_id(pid,local_peer_id,item_code)
		if is_in_splitscreen_mode:
			return set_player_item(local_peer_id,item_code)
	return add_new_item(item_code,is_ready)

func set_player_item(peer_id:int, item_code:String)->int:
	if not is_in_splitscreen_mode:
		return 0
	Global.Print("splitscreen ui trying to set item %s for player %s"%[item_code,peer_id],30)
	var itmI = pl_itmIs[peer_id]
	var txr:TextureRect = hbox.get_node("ItemUI_element"+str(itmI))
	if item_code_to_texture.has(item_code):
		if pl_items[peer_id] != "":
			block_next_remove = true
		Global.Print("ui item was set",30)
		txr.texture = item_code_to_texture[item_code]
		if Global.config.get_value(Global.config_user_settings_sec,"useShader", true):
			txr.material = shader_ready.duplicate()
			txr.material.set_shader_parameter("color", pl_colors[peer_id])
		pl_items[peer_id] = item_code
		#txr.modulate = pl_colors[peer_id]
	elif not block_next_remove:
		Global.Print("ui item was removed", 30)
		txr.texture = ImageTexture.new()
	else:
		Global.Print("ui item was NOT removed", 30)
		block_next_remove = false
	return itmI

func add_new_item(item_code:String, is_ready=true)->int:
	Global.Print("adding item %s to ui list" % item_code, 35)
	item_counter += 1
	var txr = TextureRect.new()
	txr.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	txr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if item_code_to_texture.has(item_code):
		txr.texture = item_code_to_texture[item_code]
		if Global.config.get_value(Global.config_user_settings_sec,"useShader", true):
			if is_ready:
				txr.material = shader_ready
			else:
				txr.material = shader_processing
	txr.name = "ItemUI_element"+str(item_counter)
	hbox.add_child(txr)
	return item_counter

func set_item_ready(id:int, is_ready=false):
	var txr = hbox.get_node("ItemUI_element"+str(id))
	if is_instance_valid(txr):
		if is_ready:
			if Global.config.get_value(Global.config_user_settings_sec,"useShader", true):
				txr.material = shader_ready
		else:
			for pid in split_screen_ids:
				itm_class.set_ui_player_item.rpc_id(pid,local_peer_id,"")
			if is_in_splitscreen_mode:
				set_player_item(local_peer_id,"")
			elif Global.config.get_value(Global.config_user_settings_sec,"useShader", true):
				txr.material = shader_processing


func remove_item(id:int):
	var txr = hbox.get_node("ItemUI_element"+str(id))
	if is_instance_valid(txr):
		for pid in split_screen_ids:
			itm_class.set_ui_player_item.rpc_id(pid,local_peer_id,"")
		if is_in_splitscreen_mode:
			set_player_item(local_peer_id,"")
		else:
			hbox.remove_child(txr)


func _on_h_box_container_minimum_size_changed() -> void:
	back.size.x = hbox.get_minimum_size().x+20
	if back.size.x <= 20.01:
		back.size.x = 0
	back.position.x = hbox.size.x/2 + hbox.position.x - back.size.x/2
