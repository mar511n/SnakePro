extends Panel

signal host(port)
signal join(ip,port)

@onready var ip_l = $VBoxContainer/IP_Label
@onready var ip_e = $VBoxContainer/IP
@onready var port_l = $VBoxContainer/Port_Label
@onready var port_e = $VBoxContainer/Port
@onready var hj_b = $VBoxContainer/HostJoin
@onready var vbox = $VBoxContainer
@onready var conf_b = $VBoxContainer/HBoxContainer/Confirm
@onready var canc_b = $VBoxContainer/HBoxContainer/Cancel

var ip_addr = "127.0.0.1"
var port = 8080

func show_popup(ip="",p=0):
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

func set_ip_vis():
	ip_l.visible = not hj_b.button_pressed
	ip_e.visible = not hj_b.button_pressed
	if hj_b.button_pressed:
		conf_b.text = "Host"
	else:
		conf_b.text = "Join"

func resize():
	var width = vbox.size.x+20
	var height = vbox.get_minimum_size().y +20
	set_size(Vector2(width,height))

func _on_host_join_toggled(_toggled_on):
	set_ip_vis()
	resize()

func _on_ok_pressed():
	if hj_b.button_pressed:
		if ip_e.text.is_valid_ip_address():
			ip_addr = ip_e.text
		else:
			return
	else:
		ip_addr = "127.0.0.1"
	port = port_e.value
	if hj_b.button_pressed:
		host.emit(port)
	else:
		join.emit(ip_addr,port)
	visible = false

func _on_cancel_pressed():
	visible = false
