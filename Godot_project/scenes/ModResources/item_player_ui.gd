extends Control

const shader_processing = preload("res://assets/Shader/shader_processing.tres")
const shader_ready = preload("res://assets/Shader/shader_ready.tres")

var item_counter = 0

const items_path = "res://assets/Images/Items/"
const item_code_to_texture = {
	"baseitem":preload("res://assets/Images/Items/unknown.png"),
	"bomb":preload("res://assets/Images/Items/bomb.png"),
	"bot":preload("res://assets/Images/Items/bot.png"),
	"fart":preload("res://assets/Images/Items/fart.png"),
	"shot":preload("res://assets/Images/Items/laser.png"),
	"speed":preload("res://assets/Images/Items/speed.png"),
	"revive":preload("res://assets/Images/Items/revive.png"),
	"baseitem_g":preload("res://assets/Images/Items/unknown.png"),
	"bomb_g":preload("res://assets/Images/Items/bomb_G.png"),
	"bot_g":preload("res://assets/Images/Items/bot_G.png"),
	"fart_g":preload("res://assets/Images/Items/fart_G.png"),
	"shot_g":preload("res://assets/Images/Items/laser_G.png"),
	"speed_g":preload("res://assets/Images/Items/speed_G.png"),
	"revive_g":preload("res://assets/Images/Items/revive.png"),
}
@onready var hbox = $HBoxContainer
@onready var back = $Panel

func add_item(item_code:String, is_ready=true)->int:
	Global.Print("adding item %s to ui list" % item_code)
	item_counter += 1
	var txr = TextureRect.new()
	txr.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	txr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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
	if txr != null and Global.config.get_value(Global.config_user_settings_sec,"useShader", true):
		if is_ready:
			txr.material = shader_ready
		else:
			txr.material = shader_processing

func remove_item(id:int):
	var ch = hbox.get_node("ItemUI_element"+str(id))
	if ch != null:
		hbox.remove_child(ch)


func _on_h_box_container_minimum_size_changed() -> void:
	back.size.x = hbox.get_minimum_size().x+20
	if back.size.x <= 20.01:
		back.size.x = 0
	back.position.x = hbox.size.x/2 + hbox.position.x - back.size.x/2
