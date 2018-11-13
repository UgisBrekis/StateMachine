tool
extends TextureRect

var default_texture : Texture
var highlight_texture : Texture

var offset : Vector2 = Vector2() setget set_offset
var display_scale : float = 1.0
var snap_distance : int = -1 setget set_snap_distance

var pressed : bool = false

signal offset_changed(p_id, p_offset)
signal remove_requested(p_id)

func _init(p_width : float, p_default_texture : Texture, p_highlight_texture : Texture, p_scale : float, p_offset : Vector2):
	mouse_filter = Control.MOUSE_FILTER_STOP
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	expand = true
	
	default_texture = p_default_texture
	highlight_texture = p_highlight_texture
	
	rect_size = Vector2(4, 4) * p_width
	texture = default_texture
	display_scale = p_scale
	
	self.offset = p_offset

func set_offset(p_offset : Vector2):
	offset = p_offset
	
	var target_position : Vector2 = offset * display_scale
	
	if snap_distance > -1:
		target_position = target_position.snapped(Vector2(snap_distance, snap_distance))
		
	rect_position = target_position - rect_size/2
	
	emit_signal("offset_changed", get_position_in_parent(), offset)
	
func set_snap_distance(p_snap_distance : int):
	snap_distance = p_snap_distance
	
	self.offset = offset.snapped(Vector2(snap_distance, snap_distance) / display_scale)
	
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed:
			pressed = true
			
			if Input.is_key_pressed(KEY_ALT):
				emit_signal("remove_requested", get_position_in_parent())
				
	elif event is InputEventMouseMotion:
		if texture != highlight_texture:
			texture = highlight_texture
		
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			pass
			
		else:
			match event.button_index:
				BUTTON_LEFT:
					if pressed:
						pressed = false
	
	if event is InputEventMouseMotion:
		if pressed:
			self.offset += event.relative / display_scale
			
		if !get_rect().has_point(get_local_mouse_position()):
			texture = default_texture