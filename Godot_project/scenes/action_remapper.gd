extends Panel

signal remap_done()

@onready var optBtn = $VBoxContainer/OptionButton
@onready var Btn = $VBoxContainer/Button
@onready var rtl = $VBoxContainer/RichTextLabel

var waiting_for_input = false

@onready var remappables = {
	"rel_left":["Turn left", "res://assets/MatIcons/turn_left_24dp_000000_FILL0_wght700_GRAD200_opsz24.svg"],
	"rel_right":["Turn right", "res://assets/MatIcons/turn_right_24dp_000000_FILL0_wght700_GRAD200_opsz24.svg"],
	"abs_left":["Left", "res://assets/MatIcons/arrow_back_24dp_000000_FILL0_wght700_GRAD200_opsz24.svg"],
	"abs_right":["Right", "res://assets/MatIcons/arrow_forward_24dp_000000_FILL0_wght700_GRAD200_opsz24.svg"],
	"abs_up":["Up", "res://assets/MatIcons/arrow_upward_24dp_000000_FILL0_wght700_GRAD200_opsz24.svg"],
	"abs_down":["Down", "res://assets/MatIcons/arrow_downward_24dp_000000_FILL0_wght700_GRAD200_opsz24.svg"]
}
var id_to_action = {}

func _ready():
	var actions = InputMap.get_actions()
	var id = 0
	for action in actions:
		if remappables.has(action):
			#var img = Image.load_from_file(remappables[action][1])
			
			var tex = load(remappables[action][1])
			var img = tex.get_image()
			img.resize(46,46,Image.INTERPOLATE_CUBIC)
			tex = ImageTexture.create_from_image(img)
			
			optBtn.add_icon_item(tex, remappables[action][0], id)
			id_to_action[id] = action
			id += 1
	optBtn.select(0)
	button_update()
	

func button_update(wfo=false):
	if wfo:
		Btn.text = "waiting for input..."
		Btn.button_pressed = true
	else:
		var action = id_to_action[optBtn.selected]
		var events = InputMap.action_get_events(action)
		if len(events)>0:
			Btn.text = events[0].as_text()
		else:
			Btn.text = "no input event configured"
		Btn.button_pressed = false

func _input(event):
	if waiting_for_input and not event is InputEventMouseButton and not event is InputEventMouseMotion:
		var action = id_to_action[optBtn.selected]
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)
		waiting_for_input = false
		button_update()
		remap_done.emit()
	elif event is InputEventMouseButton:
		pass
	else:
		if event.is_action_type():
			for action in remappables:
				if event.is_action(action) and Input.is_action_just_pressed(action):
					rtl.add_text(remappables[action][0]+" : ")
					rtl.add_text(event.as_text()+"\n")

func _on_option_button_item_selected(_index):
	button_update()

func _on_button_toggled(toggled_on):
	if toggled_on:
		waiting_for_input = true
		button_update(true)
	else:
		waiting_for_input = false
		button_update()


func _on_v_box_container_resized():
	size = $VBoxContainer.size+Vector2(20,20)

func _on_texture_button_pressed():
	InputMap.load_from_project_settings()
	button_update()
	remap_done.emit()
