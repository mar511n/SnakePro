extends Panel

signal on_settings_changed(settings)

const playable_snakes = {0:"test",1:"blue",2:"red",3:"yellow",4:"pink"}
const input_options = {0:["rel","relative"],1:["abs","absolute"]}

@onready var SnakeOpt = $ScrollContainer/VBoxContainer/SnakeOpt
@onready var InputOpt = $ScrollContainer/VBoxContainer/InputOpt
@onready var PlayerName = $ScrollContainer/VBoxContainer/PlayerName
@onready var SmoothCam = $ScrollContainer/VBoxContainer/SmoothCam
@onready var SmoothCam_L = $ScrollContainer/VBoxContainer/SmoothCam_L
@onready var VSyncOpt = $ScrollContainer/VBoxContainer/VSyncB

@export var min_width:int = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	if min_width > 0:
		$ScrollContainer/VBoxContainer.custom_minimum_size.x = min_width
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
		if input_options[ioi][0] == Lobby.player_info.get("inputmethod","rel"):
			id = ioi
	InputOpt.select(InputOpt.get_item_index(id))
	set_smoothcam(!Lobby.player_info.get("smoothCam", true))
	VSyncOpt.select(Lobby.player_info.get("vsyncMode", 0))
	visible = true

func make_settings_dict() -> Dictionary:
	var us = {}
	us["name"] = PlayerName.text
	us["snake_tile_idx"] = SnakeOpt.get_selected_id()
	# TODO: actually change vsync and make these settings not synced but only local(maybe look at netwroking and make some improvement to not use to much bandwidth)
	us["inputmethod"] = InputOpt.get_selected_metadata()
	us["smoothCam"] = !SmoothCam.button_pressed
	us["vsyncMode"] = VSyncOpt.selected
	return us

func set_smoothcam(off):
	SmoothCam.button_pressed = off
	SmoothCam_L.text = "Smooth camera: " + str(!off)
	if off:
		SmoothCam.text = "enable"
	else:
		SmoothCam.text = "disable"

func _on_settings_changed():
	var us = make_settings_dict()
	on_settings_changed.emit(us)

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
