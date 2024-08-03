extends Node2D
class_name SnakePlayer

# called is tiles change
signal on_movement(peer_id:int, pl_idx:int)

enum input_dir {
	LEFT,
	RIGHT,
	NONE
}

# static stuff
var pl_idx = 0
var peer_id = 0
@onready var cam_node = $Camera2D
@onready var module_node = $Modules
@onready var gui_node = $GUI
@onready var DeadSound = $DeadSound
@onready var EatingSound = $EatingSound
@onready var EatingRottenSound = $EatingRottenSound
@onready var CollectItemSound = $CollectItemSound
@onready var ReviveSound = $ReviveSound
@onready var SpeedSound = $SpeedSound
@onready var ShootingSound = $ShootingSound
var sn_drawer_path : NodePath
var sn_drawer : TileMap
var startPos : Vector2
var startDir : Vector2i

var camLT_lim : Vector2
var camRB_lim : Vector2
var IG : InGame
var is_owner : bool

var modules : Array[PlModBase]

# frequently changing variables
@export var tiles = []
var last_drawn_tiles : Array[Vector2i] = []
var fett : int = 3
@onready var snake_path : Curve2D = $Path2D.curve
var movement_update_period : float = 1.0 # seconds
# helper variables
var path_pos : float = 0.0 # in px
var delta_speed : float = 0.0 # in px per second
var time_since_last_movement_update : float = 0.0 # seconds
var firstInput : input_dir = input_dir.NONE
var secondInput : input_dir = input_dir.NONE
@export var CollLayers = []
var CollMasks = []
var module_vars = {}

# on server/client:
# -> redraw, if tiles changed
# -> move camera if active player
func _process(delta):
	if last_drawn_tiles[0] != tiles[0] or last_drawn_tiles[-1] != tiles[-1]:
		on_movement.emit(peer_id,pl_idx)
		redraw_snake()
	
	if is_owner:
		if !Global.config.get_value(Global.config_user_settings_sec,"smoothCam", true):
			global_position = sn_drawer.to_global(sn_drawer.map_to_local(tiles[-1]))
		else:
			#var pos_frac = sn_drawer.map_to_local(tiles[-2]).lerp(sn_drawer.map_to_local(tiles[-1]), time_since_last_movement_update/movement_update_period)
			#global_position = sn_drawer.to_global(pos_frac)
			#global_position = sn_drawer.to_global(sn_drawer.to_local(global_position).lerp(pos_frac, 0.01))
			#var head_pos = sn_drawer.to_global(sn_drawer.map_to_local(tiles[-1]))
			#var dir = get_direction_facing()
			#global_position += dir*cam_speed*delta
			#global_position = global_position.lerp(head_pos,0.005)
			var spl = snake_path.get_baked_length()
			var cam_speed = get_speed()*IG.tile_size_px
			delta_speed = lerpf(delta_speed, (spl-IG.tile_size_px/2.0-path_pos), 0.01)
			#if abs(delta_speed)/cam_speed > 0.01:
			#	print(delta_speed)
			path_pos = clampf(path_pos+(cam_speed+delta_speed)*delta,0,spl)
			global_position = snake_path.sample_baked(path_pos)
			#global_position = sn_drawer.to_global(sn_drawer.map_to_local(tiles[-1]))
	for mod in module_node.get_children():
		mod.on_player_process(delta)

# on server/client:
# -> update snake
# -> update fps label
func _physics_process(delta):
	if is_owner:
		process_input()
		update_snake(delta)
		$GUI/FPS_L.text = str(int(Engine.get_frames_per_second()))
	for mod in module_node.get_children():
		mod.on_player_physics_process(delta)

# on server&client:
# cause is array[2] with first entry of hit_causes and second entry additional infos 
@rpc("any_peer","call_local","reliable")
func hit(cause:Array):
	Global.Print("player %s is hit by cause %s" % [peer_id, cause])
	for mod in module_node.get_children():
		mod.on_player_hit(cause)

# on server/client:
# -> handle movement input
func process_input():
	var new_dir = input_dir.NONE
	if Global.config.get_value(Global.config_user_settings_sec,"inputmethod", "abs") == "rel":
		if Input.is_action_just_pressed("rel_left"):
			new_dir = input_dir.LEFT
		elif Input.is_action_just_pressed("rel_right"):
			new_dir = input_dir.RIGHT
	elif Global.config.get_value(Global.config_user_settings_sec,"inputmethod", "abs") == "abs":
		var pdir = Vector2i.ZERO
		if Input.is_action_just_pressed("abs_left"):
			pdir = Vector2i.LEFT
		elif Input.is_action_just_pressed("abs_right"):
			pdir = Vector2i.RIGHT
		elif Input.is_action_just_pressed("abs_up"):
			pdir = Vector2i.UP
		elif Input.is_action_just_pressed("abs_down"):
			pdir = Vector2i.DOWN
		if pdir != Vector2i.ZERO:
			var dir = get_direction_facing()
			var prod_z = dir*pdir == Vector2i.ZERO
			if prod_z and firstInput == input_dir.NONE:
				if Vector2i(dir.y,-dir.x) == pdir:
					new_dir = input_dir.LEFT
				else:
					new_dir = input_dir.RIGHT
			elif !prod_z and firstInput != input_dir.NONE:
				if firstInput == input_dir.LEFT:
					dir = Vector2i(dir.y,-dir.x)
				else:
					dir = Vector2i(-dir.y,dir.x)
				if Vector2i(dir.y,-dir.x) == pdir:
					new_dir = input_dir.LEFT
				else:
					new_dir = input_dir.RIGHT
	make_turn(new_dir)

func make_turn(new_dir:input_dir)->void:
	if new_dir != input_dir.NONE:
		if firstInput == input_dir.NONE:
			firstInput = new_dir
		elif secondInput == input_dir.NONE:
			secondInput = new_dir
		else:
			firstInput = secondInput
			secondInput = new_dir

# on server/client:
# -> updates the snake (should only be used by active player)
func update_snake(delta):
	time_since_last_movement_update += delta
	if time_since_last_movement_update > movement_update_period:
		time_since_last_movement_update = fmod(time_since_last_movement_update, movement_update_period)
		var dir = get_direction_facing()
		if firstInput != input_dir.NONE:
			if firstInput == input_dir.LEFT:
				dir = Vector2i(dir.y,-dir.x)
			else:
				dir = Vector2i(-dir.y,dir.x)
			firstInput = secondInput
			secondInput = input_dir.NONE
		move_in_dir(dir)

# on server/client:
# -> redraws the snake
func redraw_snake():
	sn_drawer.clear_layer(pl_idx)
	sn_drawer.draw_snake(Lobby.players[peer_id].get("snake_tile_idx", pl_idx+1),pl_idx,tiles)
	last_drawn_tiles = [tiles[0],tiles[-1]]

# on server/client (mostly used for the active player (tiles are then synced to other peers)):
# moves the snake by one tile in dir, tracking the path if is active player
func move_in_dir(dir:Vector2i):
	tiles.append(tiles[-1]+dir)
	if fett > 0:
		fett -= 1
	else:
		tiles.remove_at(0)
	if is_owner:
		snake_path.add_point(sn_drawer.to_global(sn_drawer.map_to_local(tiles[-1])))
		while snake_path.point_count > Global.max_snake_path_length:
			pass
			snake_path.remove_point(0)
			path_pos -= IG.tile_size_px
		if Global.debugging_on:
			$Line2D.points = snake_path.get_baked_points()

# on server/client:
# -> called before _ready
# --> set start params
func pre_ready(marker:Marker2D, enabled_mods=[]):
	var gparams = Lobby.game_settings.get(Global.config_game_params_sec, Global.default_game_params.duplicate())
	if gparams.has("startSnakeLength"):
		fett = gparams["startSnakeLength"]-1
	if gparams.has("snakeSpeed"):
		set_speed(float(gparams["snakeSpeed"]))
		
	startPos = marker.global_position
	startDir = Vector2i.RIGHT
	var rot = fmod(marker.rotation_degrees + 360, 360)
	if rot >= 45 and rot < 135:
		startDir = Vector2i.DOWN
	elif rot >= 135 and rot < 225:
		startDir = Vector2i.LEFT
	elif rot >= 225 and rot < 315:
		startDir = Vector2i.UP
	
	modules = []
	for mod_path in enabled_mods:
		var mod = load(Global.player_modules_dir+mod_path)
		if mod != null:
			var mi = mod.new()
			if mi.autoload:
				modules.append(mi)
				Global.Print("loading player module %s: success" % mod_path)
			else:
				Global.Print("Autoload disabled for player module %s" % mod_path)
		else:
			Global.Print("loading player module %s: ERROR" % mod_path, 7)
	for mod in modules:
		mod.on_player_pre_ready(self,enabled_mods)
	Global.Print("%s with idx %s at %s starting in direction %s" % [peer_id, pl_idx, startPos, startDir])


# on server/client:
# -> set static stuff
# -> reset player
# -> inform peers that player is loaded
func _ready():
	set_physics_process(false)
	set_process(false)
	is_owner = peer_id == multiplayer.get_unique_id()
	if !Global.debugging_on:
		remove_child($Sprite2D)
		remove_child($Line2D)
	sn_drawer = get_node(sn_drawer_path)
	cam_node.enabled = is_owner
	gui_node.visible = cam_node.enabled
	cam_node.limit_left = camLT_lim.x
	cam_node.limit_top = camLT_lim.y
	cam_node.limit_right = camRB_lim.x
	cam_node.limit_bottom = camRB_lim.y
	for mod in modules:
		module_node.add_child(mod)
	for mod in module_node.get_children():
		mod.on_player_ready()
	reset_snake_tiles()
	if cam_node.enabled:
		cam_node.position_smoothing_speed = 6
		cam_node.position_smoothing_enabled = Global.config.get_value(Global.config_user_settings_sec,"smoothCam", true)
		Lobby.player_loaded.rpc()

func has_enough_tiles(n:int)->bool:
	return n+2 <= len(tiles)

@rpc("any_peer","call_local","reliable")
func remove_tiles_from_tail(n:int)->void:
	if has_enough_tiles(n):
		tiles = tiles.slice(n)
	else:
		tiles = tiles.slice(-2)

# returns the head of the snake
func get_head_tile()->Vector2i:
	return tiles[-1]

# on server/client:
# -> set snake to startpos
func reset_snake_tiles():
	var spos = sn_drawer.local_to_map(sn_drawer.to_local(startPos))
	tiles = [spos]
	fett = Lobby.game_settings.get(Global.config_game_params_sec).get("startSnakeLength", Global.default_game_params["startSnakeLength"]) -1
	set_speed(Lobby.game_settings.get(Global.config_game_params_sec).get("snakeSpeed", Global.default_game_params["snakeSpeed"]))
	for i in range(1):
		move_in_dir(startDir)
	redraw_snake()
	path_pos = snake_path.get_baked_length()-IG.tile_size_px/2.0
	global_position = startPos
	for mod in module_node.get_children():
		mod.on_player_reset_snake_tiles()

# on server/client:
# -> returns the direction the snake is currently facing
func get_direction_facing() -> Vector2i:
	return tiles[-1]-tiles[-2]

# on server/client:
# -> returns the current speed
func get_speed() -> float:
	return 1/movement_update_period

func set_speed(speed:float):
	movement_update_period = 1/speed

func _on_tree_entered():
	$MultiplayerSynchronizer.set_multiplayer_authority(peer_id)
