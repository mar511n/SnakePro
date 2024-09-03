extends Node2D

@onready var static_node = $Static
@onready var variable_node = $Variable
@onready var time_slider = $GUI/Control/TimeSlider
@onready var play_btn = $GUI/Control/HBoxContainer/PlayBtn
@onready var cam = $Camera2D
#@onready var file_dialog = $FileDialog
@onready var replay_btn = $GUI/Control/HBoxContainer/ReplaysBtn

var timer = 0
var next_gsi = 0
var paused = false

const CamSpeed = 500
const CamZoom = 0.2

func _ready() -> void:
	timer = 0
	next_gsi = 0
	clear_variable_gs()
	Global.load_game_state(static_node,Global.static_gamestate)
	if len(Global.variable_gamestates) > 0:
		Global.load_game_state(variable_node,Global.variable_gamestates[0][1])
		next_gsi = 1
		time_slider.max_value = Global.variable_gamestates[-1][0]
		time_slider.step = time_slider.max_value/float(10*len(Global.variable_gamestates))
	time_slider.call_deferred("grab_focus")

var update_needed = false
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_select"):
		set_pause(!paused)
	var cam_move_dir = Vector2.ZERO
	if Input.is_action_pressed("abs_down"):
		cam_move_dir += Vector2.DOWN
	elif Input.is_action_pressed("abs_up"):
		cam_move_dir += Vector2.UP
	elif Input.is_action_pressed("abs_left"):
		cam_move_dir += Vector2.LEFT
	elif Input.is_action_pressed("abs_right"):
		cam_move_dir += Vector2.RIGHT
	if Input.is_action_just_pressed("ui_page_down"):
		cam.zoom += Vector2.ONE*CamZoom
	elif Input.is_action_just_pressed("ui_page_up"):
		cam.zoom -= Vector2.ONE*CamZoom
	cam.global_position += cam_move_dir.normalized()*CamSpeed*delta
	if not paused or update_needed:
		timer += delta
		if abs(timer-time_slider.value) > 0.1:
			time_slider.set_value_no_signal(timer)
		while len(Global.variable_gamestates)>next_gsi and Global.variable_gamestates[next_gsi][0]<timer:
			next_gsi += 1
			update_needed = true
	if update_needed:
		update_needed = false
		clear_variable_gs()
		Global.load_game_state(variable_node,Global.variable_gamestates[next_gsi-1][1])
		if next_gsi == len(Global.variable_gamestates):
			paused = true

func clear_variable_gs():
	for node in variable_node.get_children():
		variable_node.remove_child(node)
		node.queue_free()

func set_to_time(time:float):
	if len(Global.variable_gamestates) > 0:
		#print("setting time to %s" % time)
		timer = time
		next_gsi = 0
		update_needed = true
		#for cgsi in range(len(Global.variable_gamestates)):
		#	if time < Global.variable_gamestates[cgsi][0]:
		#		break
		#	next_gsi = cgsi+1
		#clear_variable_gs()
		#Global.load_game_state(variable_node,Global.variable_gamestates[next_gsi-1][1])

func _on_play_btn_toggled(toggled_on: bool) -> void:
	paused = toggled_on
	time_slider.call_deferred("grab_focus")

func _on_back_btn_pressed() -> void:
	Lobby.load_scene(Global.main_menu_path)

func set_pause(p:bool):
	paused = p
	play_btn.set_pressed_no_signal(p)

func _on_time_slider_value_changed(value: float) -> void:
	set_to_time(value)


func _on_save_btn_pressed() -> void:
	create_replay_dir_if_needed()
	var fname = Time.get_datetime_string_from_system().replace(":","_")
	fname += ".dat"
	var file = FileAccess.open(Global.replay_dir_path+fname,FileAccess.WRITE)
	file.store_var([Global.static_gamestate, Global.variable_gamestates])
	file.close()
	Global.Print("replay saved as %s" % fname, 60)
	time_slider.call_deferred("grab_focus")

func create_replay_dir_if_needed():
	if DirAccess.dir_exists_absolute(Global.replay_dir_path):
		return
	DirAccess.make_dir_absolute(Global.replay_dir_path)

func _on_load_btn_pressed() -> void:
	set_replay_btn()
	replay_btn.visible = true
	#file_dialog.show()
	#time_slider.call_deferred("grab_focus")

func _on_file_dialog_file_selected(path: String) -> void:
	load_replay(path)

func load_replay(path:String):
	Global.Print("loading replay %s ..." % path.trim_prefix(Global.replay_dir_path), 60)
	var file = FileAccess.open(path,FileAccess.READ)
	var gs = file.get_var()
	file.close()
	Global.static_gamestate = gs[0]
	Global.variable_gamestates = gs[1]
	_ready()

func set_replay_btn():
	replay_btn.clear()
	replay_btn.add_item("")
	replay_btn.select(0)
	var dir = DirAccess.open(Global.replay_dir_path)
	for file in dir.get_files():
		replay_btn.add_item(file)

func _on_replays_btn_item_selected(index: int) -> void:
	if index > 0:
		var file = replay_btn.get_item_text(index)
		load_replay(Global.replay_dir_path+file)
		replay_btn.visible = false
		time_slider.call_deferred("grab_focus")
