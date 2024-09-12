extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var ts = Vector2.ONE*48
	print(ts)
	$ysorter/AppleMap.scale_to_tile_size(ts)
	$ysorter/FartDrawer.scale_to_tile_size(ts)
	$ysorter/BulletDrawer.scale_to_tile_size(ts)
	$ysorter/BotDrawer.scale_to_tile_size(ts)
	#var fid = $ysorter/FartDrawer.add_fart()
	#$ysorter/FartDrawer.set_radius(fid,2.5)
	#$ysorter/FartDrawer.set_ghost(fid,false)
	#$ysorter/FartDrawer.set_pos(fid,$ysorter/FartPos.global_position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
