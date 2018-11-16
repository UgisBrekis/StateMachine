tool
extends "Views/GraphEditorNodeSlotView.gd"

# Properties
var is_input : bool = true setget set_is_input

var socket_type : int = -1
var socket_color : Color = Color.white setget set_socket_color

var text : String = "" setget set_text

# Signals
signal socket_pressed(p_is_input, p_socket_id)

func _init(p_theme : Theme):
	theme = p_theme
	initialize_view()

func _enter_tree():
	if !socket.is_connected("gui_input", self, "on_socket_gui_input"):
		socket.connect("gui_input", self, "on_socket_gui_input")
	
func on_socket_gui_input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.button_index != BUTTON_LEFT:
			return
			
		if event.pressed:
			emit_signal("socket_pressed", is_input, get_position_in_parent())
	
func set_is_input(p_is_input : bool):
	is_input = p_is_input
	
	if is_input:
		container.move_child(socket, 0)
		label.align = Label.ALIGN_LEFT
		
	else:
		container.move_child(socket, 1)
		label.align = Label.ALIGN_RIGHT
		
func set_socket_color(p_color : Color):
	socket.modulate = p_color
	
func set_text(p_text : String):
	text = p_text
	
	label.text = text
	
func initialize(p_is_input : bool, p_type : int, p_color : Color, p_text : String):
	self.is_input = p_is_input
	self.socket_type = p_type
	self.socket_color = p_color
	self.text = p_text
	