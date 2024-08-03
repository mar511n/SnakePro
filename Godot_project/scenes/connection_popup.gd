extends Panel
class_name ConnectionPopupPanel

signal host(port:int)
signal join(ip:String,port:int)

@onready var ip_l:Label = $VBoxContainer/IP_Label
@onready var ip_e:LineEdit = $VBoxContainer/IP
@onready var port_l:Label = $VBoxContainer/Port_Label
@onready var port_e:SpinBox = $VBoxContainer/Port
@onready var hj_b:CheckButton = $VBoxContainer/HostJoin
@onready var vbox:VBoxContainer = $VBoxContainer
@onready var conf_b:Button = $VBoxContainer/HBoxContainer/Confirm
@onready var canc_b:Button = $VBoxContainer/HBoxContainer/Cancel

var ip_addr:String = "127.0.0.1"
var port:int = 8080

func show_popup(ip:String="",p:int=0)->void:
	if not ip.is_empty():
		ip_addr = ip
	if p != 0:
		port = p
	hj_b.set_pressed_no_signal(false)
	ip_e.text = ip_addr
	port_e.value = port
	set_ip_vis()
	resize()
	visible = true

func set_ip_vis()->void:
	ip_l.visible = not hj_b.button_pressed
	ip_e.visible = not hj_b.button_pressed
	if hj_b.button_pressed:
		conf_b.text = "Host"
	else:
		conf_b.text = "Join"

func resize()->void:
	var width:float = vbox.size.x+20
	var height:float = vbox.get_minimum_size().y +20
	set_size(Vector2(width,height))

func _on_host_join_toggled(_toggled_on:bool)->void:
	set_ip_vis()
	resize()

func _on_ok_pressed()->void:
	if not hj_b.button_pressed:
		if ip_e.text.is_valid_ip_address():
			ip_addr = ip_e.text
		else:
			return
	else:
		ip_addr = "127.0.0.1"
	port = int(port_e.value)
	if hj_b.button_pressed:
		host.emit(port)
	else:
		join.emit(ip_addr,port)
	visible = false

func _on_cancel_pressed()->void:
	visible = false
