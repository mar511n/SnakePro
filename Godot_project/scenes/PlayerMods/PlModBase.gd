extends Node
class_name PlModBase

var pl : SnakePlayer

func on_player_pre_ready(player:SnakePlayer, _enabled_mods=[]):
	pl = player

func on_player_ready():
	pass

func on_player_reset_snake_tiles():
	pass

func on_player_process(_delta:float):
	pass

func on_player_physics_process(_delta:float):
	pass

func on_player_hit(_cause:Array):
	pass
