tool
extends TextureRect

var offset : Vector2 = Vector2() setget set_offset
var display_scale : float = 1.0

signal offset_changed(p_id, p_offset)
signal remove_requested(p_id)

func _init(p_width : float, p_display_scale : float, p_offset : Vector2):
	mouse_filter = Control.MOUSE_FILTER_STOP
	rect_size = Vector2(p_width, p_width) * 2
	display_scale = p_display_scale
	
	self.offset = p_offset

func set_offset(p_offset : Vector2):
	offset = p_offset
	
	rect_position = offset  * display_scale - rect_size/2
	
	emit_signal("offset_changed", get_position_in_parent(), offset)
	
func _gui_input(event):
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			self.offset = get_parent().get_local_mouse_position() / display_scale
			
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed:
			if Input.is_key_pressed(KEY_ALT):
				emit_signal("remove_requested", get_position_in_parent())
	
func _draw():
	draw_rect(Rect2(Vector2(), rect_size), Color(1, 1, 1, 0.3))
	#draw_circle(rect_size/2, rect_size.x/2, Color.aquamarine)