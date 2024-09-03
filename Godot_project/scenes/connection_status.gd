extends TextureRect
class_name ConnectionStatusTexture

const shader_processing = preload("res://assets/Shader/shader_ready.tres")

@onready var disconnected:Texture2D = preload("res://assets/MatIcons/conversion_path_off_24dp_000000_FILL0_wght400_GRAD0_opsz24.svg")
@onready var connected:Texture2D = preload("res://assets/MatIcons/conversion_path_24dp_000000_FILL0_wght400_GRAD0_opsz24.svg")
@onready var hosting:Texture2D = preload("res://assets/MatIcons/tenancy_24dp_000000_FILL0_wght400_GRAD0_opsz24.svg")

func _ready()->void:
	texture = disconnected
	shader_processing.set_shader_parameter("color", Color.BLUE)
	shader_processing.set_shader_parameter("line_thickness", 0.04)
	shader_processing.set_shader_parameter("phase_speed", 10)

func set_connecting()->void:
	material = shader_processing
	texture = disconnected
	tooltip_text = "connecting..."
	#self_modulate = Color.BLUE

func set_disconnected()->void:
	material = null
	texture = disconnected
	tooltip_text = "disconnected"
	self_modulate = Color.WHITE

func set_connected_to_server()->void:
	material = null
	texture = connected
	tooltip_text = "connected to server"
	self_modulate = Color.WEB_GREEN

func set_hosting()->void:
	material = null
	texture = hosting
	tooltip_text = "hosting"
	self_modulate = Color.WEB_GREEN

func network_connected()->bool:
	return texture != disconnected
