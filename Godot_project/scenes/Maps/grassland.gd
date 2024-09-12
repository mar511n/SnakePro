extends SaveableTileMap

@export var wind_offset : Texture2D

@onready var windshader = $TileMapLayer.tile_set.get_source(0).get_tile_data(Vector2i(1,3),0).material

@onready var tps_curve:Curve2D = $tps.curve
var map_size = Vector2i(49,49)
var map_off = Vector2i(1,1)

func _ready() -> void:
	#RenderingServer.set_default_clear_color(Color("a8ca58"))
	if not Global.config.get_value(Global.config_user_settings_sec,"useParticles", true):
		remove_child($GPUParticles2D)
		remove_child($GPUParticles2D2)
		remove_child($GPUParticles2D3)
		remove_child($GPUParticles2D4)
	if not Global.config.get_value(Global.config_user_settings_sec,"useShader", true):
		for x in range(1,28):
			$TileMapLayer.tile_set.get_source(0).get_tile_data(Vector2i(x,3),0).material = CanvasItemMaterial.new()

func get_tps(tmap:TileMap)->Dictionary:
	var tps = super(tmap)
	for idx in range(map_size.x*2+map_size.y*2+4):
		var opos = tmap.local_to_map(tmap.to_local($tps.to_global(tps_curve.sample_baked(48*idx))))-map_off
		var tpos = opos
		for axis in range(2):
			if tpos[axis] == 0:
				tpos[axis] = map_size[axis]+1
			elif tpos[axis] == map_size[axis]+1:
				tpos[axis] = 0
		tps[opos+map_off] = [tpos+map_off]
	return tps

func get_res_path()->String:
	return "res://scenes/Maps/grassland.tscn"
