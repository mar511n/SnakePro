extends Node2D

@export var fartSpriteScene : PackedScene
#@onready var fartSprite = $FartSprite

var fart_id = 0
var farts = {}

var o_tile_size = 320
const o_tile_rad = 2.5

func _ready() -> void:
	var fart_scene = fartSpriteScene.instantiate()
	o_tile_size = fart_scene.get_node("SpriteG").texture.get_size().x/(2*o_tile_rad)
	fart_scene.queue_free()

func scale_to_tile_size(ts:Vector2)->void:
	scale *= ts/(Vector2.ONE*o_tile_size)

func add_fart()->int:
	var fart_scene = fartSpriteScene.instantiate()
	if not Global.config.get_value(Global.config_user_settings_sec,"useParticles", true):
		fart_scene.get_node("SpriteG/GPUParticles2D").visible = false
		fart_scene.get_node("SpriteN/GPUParticles2D").visible = false
		#get_tree().call_deferred("set_group","Particles","visible",false)
	fart_id += 1
	fart_scene.name = "Fart"+str(fart_id)
	add_child(fart_scene)
	fart_scene.visible = true
	farts[fart_id] = fart_scene
	return fart_id

func remove_fart(f_id:int):
	if farts.has(f_id):
		remove_child(farts[f_id])
		farts.erase(f_id)

func set_radius(f_id:int,rad:float):
	if farts.has(f_id):
		farts[f_id].scale = rad/o_tile_rad*Vector2.ONE

func set_ghost(f_id:int,is_ghost:bool):
	if farts.has(f_id):
		farts[f_id].get_node("SpriteG").visible = is_ghost
		farts[f_id].get_node("SpriteN").visible = !is_ghost

func set_pos(f_id:int,pos:Vector2):
	if farts.has(f_id):
		farts[f_id].position = to_local(pos)

func get_res_path()->String:
	return "res://scenes/ModResources/FartDrawer.tscn"

func get_data()->Dictionary:
	var dic = {"scale":scale}
	for f_id in farts:
		dic[f_id] = [farts[f_id].scale,farts[f_id].position,farts[f_id].get_node("SpriteG").visible]
	return dic

func set_data(dic:Dictionary):
	for f_id in farts:
		remove_child(farts[f_id])
	_ready()
	farts = {}
	scale = dic.get("scale", 1)
	for f_id_f in dic:
		if not f_id_f is String:
			var f_id = int(f_id_f)
			var fart_scene = fartSpriteScene.instantiate()
			fart_scene.get_node("SpriteG/GPUParticles2D").visible = false
			fart_scene.get_node("SpriteN/GPUParticles2D").visible = false
			fart_scene.name = "Fart"+str(f_id)
			add_child(fart_scene)
			fart_scene.visible = true
			farts[f_id] = fart_scene
			farts[f_id].scale = dic[f_id][0]
			farts[f_id].position = dic[f_id][1]
			farts[f_id].get_node("SpriteG").visible = dic[f_id][2]
			farts[f_id].get_node("SpriteN").visible = dic[f_id][2]
	#if farts.size() > 0 and not Global.config.get_value(Global.config_user_settings_sec,"useParticles", true):
	#	get_tree().call_deferred("set_group","Particles","visible",false)
