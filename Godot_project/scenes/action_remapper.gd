extends Panel
class_name ControllSettingsPanel

signal remap_done()

@onready var actionOpt:OptionButton = $VBoxContainer/ActionsBtn
@onready var controllerOpt:OptionButton = $VBoxContainer/ControllerBtn
@onready var Btn:Button = $VBoxContainer/Button
@onready var rtl:RichTextLabel = $VBoxContainer/RichTextLabel

var waiting_for_input:bool = false

@onready var remappables:Dictionary = {
	"rel_left":["Turn left", "res://assets/MatIcons/turn_left_24dp_000000_FILL0_wght700_GRAD200_opsz24.svg"],
	"rel_right":["Turn right", "res://assets/MatIcons/turn_right_24dp_000000_FILL0_wght700_GRAD200_opsz24.svg"],
	"abs_left":["Left", "res://assets/MatIcons/arrow_back_24dp_000000_FILL0_wght700_GRAD200_opsz24.svg"],
	"abs_right":["Right", "res://assets/MatIcons/arrow_forward_24dp_000000_FILL0_wght700_GRAD200_opsz24.svg"],
	"abs_up":["Up", "res://assets/MatIcons/arrow_upward_24dp_000000_FILL0_wght700_GRAD200_opsz24.svg"],
	"abs_down":["Down", "res://assets/MatIcons/arrow_downward_24dp_000000_FILL0_wght700_GRAD200_opsz24.svg"],
	"use_item":["Use item"]
}
var id_to_action:Dictionary = {}

var connected_controller = []

func _ready()->void:
	var actions:Array = InputMap.get_actions()
	var id:int = 0
	for action:StringName in actions:
		if remappables.has(action):
			#var img = Image.load_from_file(remappables[action][1])
			if len(remappables[action])>1:
				var tex:Texture2D = load(remappables[action][1])
				var img:Image = tex.get_image()
				img.resize(46,46,Image.INTERPOLATE_CUBIC)
				tex = ImageTexture.create_from_image(img)
				
				actionOpt.add_icon_item(tex, remappables[action][0], id)
			else:
				actionOpt.add_item(remappables[action][0], id)
			id_to_action[id] = action
			id += 1
	actionOpt.select(0)
	button_update()

func button_update(wfo:bool=false)->void:
	if wfo:
		Btn.text = "waiting for input..."
		Btn.button_pressed = true
	else:
		var action:StringName = id_to_action[actionOpt.selected]
		var events:Array = InputMap.action_get_events(action)
		if len(events)>0:
			Btn.text = events[0].as_text()
		else:
			Btn.text = "no input event configured"
		Btn.button_pressed = false

func _input(event:InputEvent)->void:
	if waiting_for_input and not event is InputEventMouseButton and not event is InputEventMouseMotion:
		var action:StringName = id_to_action[actionOpt.selected]
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			Input.start_joy_vibration(event.device,0.5,0.5,0.3)
		if not event.is_action("ui_accept"):
			waiting_for_input = false
			button_update()
		remap_done.emit()
	else:
		if event.is_action_type():
			for action:StringName in remappables:
				if event.is_action(action) and Input.is_action_just_pressed(action):
					rtl.add_text(remappables[action][0]+" : ")
					rtl.add_text(event.as_text()+"\n")
					if event is InputEventJoypadButton or event is InputEventJoypadMotion:
						Input.start_joy_vibration(event.device,0.5,0.5,0.3)

func _on_option_button_item_selected(_index:int)->void:
	Btn.set_pressed_no_signal(true)
	_on_button_toggled(true)
	#button_update()

func _on_button_toggled(toggled_on:bool)->void:
	if toggled_on:
		waiting_for_input = true
		button_update(true)
	else:
		waiting_for_input = false
		button_update()


func _on_v_box_container_resized()->void:
	pass
	#size = $VBoxContainer.size+Vector2(20,20)

func _on_texture_button_pressed()->void:
	InputMap.load_from_project_settings()
	button_update()
	remap_done.emit()

func _on_controller_btn_pressed() -> void:
	connected_controller = Input.get_connected_joypads()
	var old_selected = controllerOpt.selected
	controllerOpt.clear()
	for contr in connected_controller:
		controllerOpt.add_item(str(contr)+" : "+str(Input.get_joy_name(contr)), contr)
	controllerOpt.selected = old_selected

func _on_controller_btn_item_selected(index: int) -> void:
	Input.start_joy_vibration(controllerOpt.get_item_id(index),0.5,0.5,1)
