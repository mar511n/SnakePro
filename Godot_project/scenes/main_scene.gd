extends Node

@onready var current_scene = $MainMenu
var main_menu_scene = preload(Global.main_menu_path)
var ingame_scene = preload(Global.ingame_path)

func _ready() -> void:
	Lobby.on_spawn_scene.connect(lobby_on_spawn_scene)
	#remove_child($SceneSpawner)

func lobby_on_spawn_scene(scene_path):
	if multiplayer.is_server():
		Global.Print("spawning scene: %s" % scene_path)
		spawn_scene.call_deferred(scene_path)

func spawn_scene(scene_path):
	remove_child(current_scene)
	current_scene.queue_free()
	if scene_path == Global.main_menu_path:
		current_scene = main_menu_scene.instantiate()
	else:
		current_scene = ingame_scene.instantiate()
	add_child(current_scene)

func _on_tree_entered():
	$SceneSpawner.set_multiplayer_authority(1)
