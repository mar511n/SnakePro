extends TextureRect

@onready var disconnected = preload("res://assets/MatIcons/conversion_path_off_24dp_000000_FILL0_wght400_GRAD0_opsz24.svg")
@onready var connected = preload("res://assets/MatIcons/conversion_path_24dp_000000_FILL0_wght400_GRAD0_opsz24.svg")
@onready var hosting = preload("res://assets/MatIcons/tenancy_24dp_000000_FILL0_wght400_GRAD0_opsz24.svg")

func _ready():
	texture = disconnected

func set_disconnected():
	texture = disconnected
	tooltip_text = "disconnected"

func set_connected_to_server():
	texture = connected
	tooltip_text = "connected to server"

func set_hosting():
	texture = hosting
	tooltip_text = "hosting"

func network_connected()->bool:
	return texture != disconnected
