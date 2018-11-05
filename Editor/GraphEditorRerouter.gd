tool
extends TextureRect

var offset : Vector2 = Vector2() setget set_offset

func set_offset(p_offset : Vector2):
	offset = p_offset
	
	rect_position = offset - rect_size/2
	
	get_parent().reroute_points[get_position_in_parent()] = offset
	get_parent().update_shape()
	
func _enter_tree():
	mouse_filter = Control.MOUSE_FILTER_STOP
	rect_size = Vector2(20, 20)
	self.offset = get_parent().reroute_points[get_position_in_parent()]
	
func _gui_input(event):
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			self.offset = get_parent().get_local_mouse_position()
	
func _draw():
	draw_circle(rect_size/2, 10, Color.aquamarine)