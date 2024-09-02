extends CanvasLayer

@onready var FPS_l = $Control/VBoxContainer/FPS_l
@onready var RTT_l = $Control/VBoxContainer/RTT_l

func set_fps(fps:float)->void:
	FPS_l.text = "%.0d fps" % [fps]

func set_rtt(rtt:float)->void:
	RTT_l.text = "%.2d ms" % [rtt*1000.0]
