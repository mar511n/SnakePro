extends Panel

signal on_settings_changed(plinfo,usetts)

const playable_snakes = {0:"test",1:"blue",2:"red",3:"yellow",4:"pink"}
const input_options = {0:["rel","relative"],1:["abs","absolute"]}

@onready var SnakeOpt = $ScrollContainer/VFlowContainer/SnakeOpt
@onready var InputOpt = $ScrollContainer/VFlowContainer/InputOpt
@onready var PlayerName = $ScrollContainer/VFlowContainer/PlayerName
@onready var SmoothCam = $ScrollContainer/VFlowContainer/SmoothCam
@onready var SmoothCam_L = $ScrollContainer/VFlowContainer/SmoothCam_L
@onready var VSyncOpt = $ScrollContainer/VFlowContainer/VSyncB
@onready var SplitScreenOpt = $ScrollContainer/VFlowContainer/SplitScreenOpt
@onready var vflow = $ScrollContainer/VFlowContainer
@onready var scrollCont = $ScrollContainer

#@export var min_width:int = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	#if min_width > 0:
	#	$ScrollContainer/VBoxContainer.custom_minimum_size.x = min_width
	SnakeOpt.clear()
	InputOpt.clear()
	for psi in playable_snakes:
		var tex = load("res://assets/Images/Snakes/"+playable_snakes[psi]+"_preview.png")
		var tex_img : Image = tex.get_image()
		var max_snake_icon_height = SnakeOpt.size.y
		var aspect = float(tex_img.get_width())/float(tex_img.get_height())
		tex_img.resize(aspect*max_snake_icon_height,max_snake_icon_height,Image.INTERPOLATE_LANCZOS)
		tex = ImageTexture.create_from_image(tex_img)
		SnakeOpt.add_icon_item(tex, " ", psi)
	for ioi in input_options:
		InputOpt.add_item(input_options[ioi][1],ioi)
		InputOpt.set_item_metadata(InputOpt.get_item_index(ioi),input_options[ioi][0])

func show_popup():
	PlayerName.text = Lobby.player_info.get("name", "")
	SnakeOpt.select(SnakeOpt.get_item_index(Lobby.player_info.get("snake_tile_idx",0)))
	var id = 0
	for ioi in input_options:
		if input_options[ioi][0] == Global.config.get_value(Global.config_user_settings_sec,"inputmethod","rel"):
			id = ioi
	InputOpt.select(InputOpt.get_item_index(id))
	set_smoothcam(!Global.config.get_value(Global.config_user_settings_sec,"smoothCam", true))
	VSyncOpt.select(Global.config.get_value(Global.config_user_settings_sec,"vsyncMode", 0))
	SplitScreenOpt.select(Global.config.get_value(Global.config_user_settings_sec,"splitscreenMode", 0))
	visible = true

func make_user_settings_dict() -> Dictionary:
	var us = {}
	#us["name"] = PlayerName.text
	#us["snake_tile_idx"] = SnakeOpt.get_selected_id()
	# TODO: actually change vsync and make these settings not synced but only local(maybe look at netwroking and make some improvement to not use to much bandwidth)
	us["inputmethod"] = InputOpt.get_selected_metadata()
	us["smoothCam"] = !SmoothCam.button_pressed
	us["vsyncMode"] = VSyncOpt.selected
	us["splitscreenMode"] = SplitScreenOpt.selected
	return us
func make_player_info_dict() -> Dictionary:
	var pli = {}
	pli["name"] = PlayerName.text
	pli["snake_tile_idx"] = SnakeOpt.get_selected_id()
	return pli

func set_smoothcam(off):
	SmoothCam.button_pressed = off
	SmoothCam_L.text = "Smooth camera: " + str(!off)
	if off:
		SmoothCam.text = "enable"
	else:
		SmoothCam.text = "disable"

func _on_settings_changed():
	on_settings_changed.emit(make_player_info_dict(),make_user_settings_dict())

func _on_player_name_focus_exited():
	_on_settings_changed()

func _on_player_name_text_submitted(_new_text):
	_on_settings_changed()

func _on_snake_opt_item_selected(_index):
	_on_settings_changed()

func _on_input_opt_item_selected(_index):
	_on_settings_changed()

func _on_smooth_cam_toggled(toggled_on):
	set_smoothcam(toggled_on)
	_on_settings_changed()

func _on_v_sync_b_item_selected(_index):
	_on_settings_changed()


func _on_scroll_container_resized():
	if scrollCont != null and vflow != null:
		vflow.custom_minimum_size = scrollCont.size

func _on_split_screen_opt_item_selected(_index):
	_on_settings_changed()
