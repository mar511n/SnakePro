extends Node2D
class_name ImageConverter

@export_category("Food")
@export var Apple : Texture2D
@export var Apple_G : Texture2D

@export_category("Items")
@export var bot : Texture2D
@export var bot_G : Texture2D
#@export var bot_c : Texture2D
@export var fart : Texture2D
@export var fart_G : Texture2D
#@export var fart_c : Texture2D
@export var laser : Texture2D
@export var laser_G : Texture2D
#@export var laser_c : Texture2D
@export var revive : Texture2D
#@export var revive_c : Texture2D
@export var speed : Texture2D
@export var speed_G : Texture2D
#@export var speed_c : Texture2D
@export var unknown : Texture2D

@export var fart_A : Texture2D
@export var fart_A_G : Texture2D
@export var shoot : Texture2D
@export var shoot_s : Texture2D

@export_category("Snakes")
@export var blue : Texture2D
@export var blue_preview : Texture2D
@export var red : Texture2D
@export var red_preview : Texture2D
@export var pink : Texture2D
@export var pink_preview : Texture2D
@export var yellow : Texture2D
@export var yellow_preview : Texture2D
@export var bot_black : Texture2D
@export var bot_black_preview : Texture2D

func _ready() -> void:
	var props = get_script().get_script_property_list()
	var img_p = "res://assets/Images/"
	var cf = ""
	var suffix = ".png"
	for prop in props:
		if prop.get("class_name", "") == "Texture2D":
			#print(img_p+cf+prop.get("name",""))
			var txt:Texture2D = get(prop.get("name",""))
			if is_instance_valid(txt):
				overwrite_image(txt, img_p+cf+prop.get("name","")+suffix)
		else:
			cf = prop.get("name","")+"/"

func overwrite_image(txt:Texture2D, path:String):
	print("overwriting %s with texture of size %s"%[path,txt.get_size()])
	txt.get_image().save_png(path)

var runningT = 0.0
func _process(delta: float) -> void:
	runningT += delta
	if runningT > 1.0:
		get_tree().call_deferred("quit")
