extends Panel
class_name UserSettingsPanel

signal on_settings_changed(plinfo:Dictionary,usetts:Dictionary)

const playable_snakes:Dictionary = {0:"test",1:"blue",2:"red",3:"yellow",4:"pink"}
const input_options:Dictionary = {0:["rel","relative"],1:["abs","absolute"]}

@onready var SnakeOpt:OptionButton = $ScrollContainer/VFlowContainer/SnakeOpt
@onready var InputOpt:OptionButton = $ScrollContainer/VFlowContainer/InputOpt
@onready var PlayerName:LineEdit = $ScrollContainer/VFlowContainer/PlayerName
@onready var SmoothCam:Button = $ScrollContainer/VFlowContainer/SmoothCam
@onready var SmoothCam_L:Label = $ScrollContainer/VFlowContainer/SmoothCam_L
@onready var VSyncOpt:OptionButton = $ScrollContainer/VFlowContainer/VSyncB
@onready var MusicVolSl:LabeledHSlider = $ScrollContainer/VFlowContainer/MusicVolume
@onready var SplitScreenOpt:OptionButton = $ScrollContainer/VFlowContainer/SplitScreenOpt
@onready var vflow:VFlowContainer = $ScrollContainer/VFlowContainer
@onready var scrollCont:ScrollContainer = $ScrollContainer
@onready var shaderBtn:CheckButton = $ScrollContainer/VFlowContainer/Shader

#@export var min_width:int = -1

# Called when the node enters the scene tree for the first time.
func _ready()->void:
	#if min_width > 0:
	#	$ScrollContainer/VBoxContainer.custom_minimum_size.x = min_width
	SnakeOpt.clear()
	InputOpt.clear()
	for psi:int in playable_snakes:
		var tex:Texture2D = load("res://assets/Images/Snakes/"+playable_snakes[psi]+"_preview.png")
		var tex_img : Image = tex.get_image()
		var max_snake_icon_height:float = SnakeOpt.size.y
		var aspect:float = float(tex_img.get_width())/float(tex_img.get_height())
		tex_img.resize(int(aspect*max_snake_icon_height),int(max_snake_icon_height),Image.INTERPOLATE_LANCZOS)
		tex = ImageTexture.create_from_image(tex_img)
		SnakeOpt.add_icon_item(tex, " ", psi)
	for ioi:int in input_options:
		InputOpt.add_item(input_options[ioi][1],ioi)
		InputOpt.set_item_metadata(InputOpt.get_item_index(ioi),input_options[ioi][0])

func show_popup()->void:
	PlayerName.text = Lobby.player_info.get("name", "")
	SnakeOpt.select(SnakeOpt.get_item_index(Lobby.player_info.get("snake_tile_idx",0)))
	var id:int = 0
	for ioi:int in input_options:
		if input_options[ioi][0] == Global.config.get_value(Global.config_user_settings_sec,"inputmethod","rel"):
			id = ioi
	InputOpt.select(InputOpt.get_item_index(id))
	set_smoothcam(!Global.config.get_value(Global.config_user_settings_sec,"smoothCam", true))
	VSyncOpt.select(Global.config.get_value(Global.config_user_settings_sec,"vsyncMode", 0))
	SplitScreenOpt.select(Global.config.get_value(Global.config_user_settings_sec,"splitscreenMode", 0))
	MusicVolSl.set_prop_value(Global.config.get_value(Global.config_user_settings_sec,"musicvolume", 100.0))
	shaderBtn.set_pressed_no_signal(Global.config.get_value(Global.config_user_settings_sec,"useShader", true))
	visible = true

func make_user_settings_dict() -> Dictionary:
	var us:Dictionary = {}
	#us["name"] = PlayerName.text
	#us["snake_tile_idx"] = SnakeOpt.get_selected_id()
	# TODO: actually change vsync and make these settings not synced but only local(maybe look at netwroking and make some improvement to not use to much bandwidth)
	us["inputmethod"] = InputOpt.get_selected_metadata()
	us["smoothCam"] = !SmoothCam.button_pressed
	us["vsyncMode"] = VSyncOpt.selected
	us["splitscreenMode"] = SplitScreenOpt.selected
	us["musicvolume"] = MusicVolSl.value
	us["useShader"] = shaderBtn.button_pressed
	return us
func make_player_info_dict() -> Dictionary:
	var pli:Dictionary = {}
	pli["name"] = PlayerName.text
	pli["snake_tile_idx"] = SnakeOpt.get_selected_id()
	return pli

func set_smoothcam(off:bool)->void:
	SmoothCam.button_pressed = off
	SmoothCam_L.text = "Smooth camera: " + str(!off)
	if off:
		SmoothCam.text = "enable"
	else:
		SmoothCam.text = "disable"

func _on_settings_changed()->void:
	on_settings_changed.emit(make_player_info_dict(),make_user_settings_dict())

func _on_player_name_focus_exited()->void:
	_on_settings_changed()

func _on_player_name_text_submitted(_new_text:String)->void:
	_on_settings_changed()

func _on_snake_opt_item_selected(_index:int)->void:
	_on_settings_changed()

func _on_input_opt_item_selected(_index:int)->void:
	_on_settings_changed()

func _on_smooth_cam_toggled(toggled_on:bool)->void:
	set_smoothcam(toggled_on)
	_on_settings_changed()

func _on_v_sync_b_item_selected(_index:int)->void:
	_on_settings_changed()

func _on_scroll_container_resized()->void:
	if is_instance_valid(scrollCont) and is_instance_valid(vflow):
		vflow.custom_minimum_size = scrollCont.size

func _on_split_screen_opt_item_selected(_index:int)->void:
	_on_settings_changed()

func _on_music_volume_drag_ended(_value_changed: bool) -> void:
	_on_settings_changed()

func _on_shader_toggled(_toggled_on: bool) -> void:
	_on_settings_changed()
