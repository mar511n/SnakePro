extends TextureRect
class_name ConnectionStatusTexture

@onready var disconnected:Texture2D = preload("res://assets/MatIcons/conversion_path_off_24dp_000000_FILL0_wght400_GRAD0_opsz24.svg")
@onready var connected:Texture2D = preload("res://assets/MatIcons/conversion_path_24dp_000000_FILL0_wght400_GRAD0_opsz24.svg")
@onready var hosting:Texture2D = preload("res://assets/MatIcons/tenancy_24dp_000000_FILL0_wght400_GRAD0_opsz24.svg")

func _ready()->void:
	texture = disconnected

func set_disconnected()->void:
	texture = disconnected
	tooltip_text = "disconnected"

func set_connected_to_server()->void:
	texture = connected
	tooltip_text = "connected to server"

func set_hosting()->void:
	texture = hosting
	tooltip_text = "hosting"

func network_connected()->bool:
	return texture != disconnected
