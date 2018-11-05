tool
extends Control

const Connection = preload("GraphEditorConnectionBase.gd")
const SelectionBox = preload("GraphEditorSelectionBox.gd")

var connection : Connection = null
var selection_box : SelectionBox = null

# Properties
var snap_distance = 20

var snap_positions = []

# Flags
var is_input = true
var is_dragging = false
var is_empty_space = true

# Signals
signal connection_drag_completed(p_from, p_to, p_empty_space)
signal selection_box_drag_completed(p_rect)

func _init(p_theme : Theme):
	theme = p_theme

func _enter_tree():
	connection = Connection.new()
	selection_box = SelectionBox.new()
	
	connection.width = theme.get_constant("graph_editor_connection_width", "Editor")
	connection.curvature = theme.get_constant("graph_editor_connection_curvature", "Editor")
	snap_distance = theme.get_constant("graph_editor_socket_snap_distance", "Editor")
	
	add_child(connection)
	add_child(selection_box)
	
	connection.hide()
	
func begin_connection_drag(p_is_input : bool, p_position : Vector2, p_snap_positions : PoolVector2Array):
	is_input = p_is_input
	is_dragging = true
	
	snap_positions = p_snap_positions
	
	connection.from_position = p_position
	connection.to_position = p_position
	
	connection.show()
	selection_box.hide()
	
func begin_selection_box_drag(p_position : Vector2):
	is_dragging = true
	
	selection_box.from_position = p_position
	selection_box.to_position = p_position
	
	connection.hide()
	selection_box.show()
	
func stop_drag():
	if !is_dragging:
		return
	
	is_dragging = false
	
	var from_position : Vector2
	var to_position : Vector2
	
	if connection.visible:
		from_position = connection.from_position
		to_position = connection.to_position
		
		connection.hide()
		
		emit_signal("connection_drag_completed", from_position, to_position, is_empty_space)
		
	elif selection_box.visible:
		from_position = selection_box.from_position
		to_position = selection_box.to_position
		
		selection_box.hide()
		
		emit_signal("selection_box_drag_completed", selection_box.get_rect())
	
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			pass
			
		else:
			match event.button_index:
				BUTTON_LEFT:
					if is_dragging:
						stop_drag()
						
	elif event is InputEventMouseMotion:
		if !is_dragging:
			return
			
		var local_mouse_position = get_local_mouse_position()
		var target_position = local_mouse_position
		var distance = snap_distance
		
		# Connection is being dragged
		if connection.visible:
			# Check if mouse position is within snap distance
			for pos in snap_positions:
				var d = pos.distance_to(local_mouse_position)
				
				if d < distance:
					target_position = pos
					distance = d
					
			# Is the target position snapped?
			if target_position in snap_positions:
				is_empty_space = false
			
			else:
				is_empty_space = true
				
			if is_input:
				connection.from_position = target_position
				
			else:
				connection.to_position = target_position
		
		# Box selection is being dragged
		else:
			selection_box.to_position = target_position
			
		accept_event()
