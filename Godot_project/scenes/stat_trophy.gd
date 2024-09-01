extends Control

@export var trophy_texture:Texture2D
@export var trophy_name:String

func set_trophy(tex:Texture2D, tname:String=""):
	$TextureRect.texture = tex
	$TextureRect.tooltip_text = tname

# pl_arr = [[int: stat, String:pl_name, color],...]
func set_places(pl_arr:Array):
	pl_arr.sort_custom(func(a, b): return a[0] > b[0])
	$Panel/RichTextLabel.clear()
	for i in range(pl_arr.size()):
		if pl_arr[i].size()>2:
			$Panel/RichTextLabel.append_text("[center][color=%s]%s[/color] : %s[/center]\n" % [pl_arr[i][2].to_html(),pl_arr[i][1],pl_arr[i][0]])
		else:
			$Panel/RichTextLabel.append_text("[center]%s : %s[/center]\n" % [pl_arr[i][1],pl_arr[i][0]])

func _ready() -> void:
	set_trophy(trophy_texture,trophy_name)
#	set_trophy(load("res://assets/Images/UI/HallPokal2.png"), "Killleader")
#	set_places([[0,"Peter",Color.RED],[10,"Gerdlinde",Color.BLUE],[5,"Bob",Color.GREEN],[3,"Sabine",Color.HOT_PINK]])
