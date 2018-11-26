tool
extends Control

const GraphEditorNode = preload("GraphEditorNode.gd")
const Connection = preload("GraphEditorConnection.gd")

var connection_width : float = 1
var connection_curvature : float = 20
var display_scale : float = 1.0

var reroute = {
	"connection" : null,
	"position" : null
}

var snapping_enabled = false setget set_snapping_enabled
var grid_cell_size = 10

# Signals
signal reroute_points_changed(p_connection)

func _init(p_theme : Theme):
	theme = p_theme
	display_scale = theme.get_constant("scale", "Editor")
	connection_width = theme.get_constant("graph_editor_connection_width", "Editor")
	connection_curvature = theme.get_constant("graph_editor_connection_curvature", "Editor")
	grid_cell_size = theme.get_constant("graph_editor_grid_cell_size", "Editor")
	
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index != BUTTON_LEFT:
			return
			
		if !event.pressed:
			return
			
		var key = KEY_CONTROL
		
		if OS.get_name() == "OSX":
			key = KEY_META
			
		if Input.is_key_pressed(key):
			reroute.connection = null
			reroute.position = null
			
			for child in get_children():
				var connection = child as Connection
				
				if connection == null:
					continue
				
				var point = connection.curve.get_closest_point(get_local_mouse_position())
				
				if point.distance_to(get_local_mouse_position()) > 40:
					continue
					
				if reroute.position == null:
					reroute.connection = connection
					reroute.position = point
					
					continue
					
				if point.distance_to(get_local_mouse_position()) < reroute.position.distance_to(get_local_mouse_position()):
					reroute.connection = connection
					reroute.position = point
			
			if reroute.connection != null:
				var connection  = reroute.connection as Connection
				
				connection.add_reroute_point(reroute.position)
				
				on_reroute_points_changed(connection)

func set_snapping_enabled(p_snapping_enabled : bool):
	snapping_enabled = p_snapping_enabled
	
	var snap_distance = -1
	
	if snapping_enabled:
		snap_distance = grid_cell_size
	
	for connection in get_children():
		connection = connection as Connection
		
		connection.snap_distance = snap_distance

func on_reroute_points_changed(p_connection : Connection):
	emit_signal("reroute_points_changed", p_connection)

func add_new_connection(p_from : GraphEditorNode, p_from_index: int, p_to : GraphEditorNode, p_to_index : int, p_reroute_points : PoolVector2Array):
	var connection : Connection = Connection.new()
	
	connection.reroute_default_texture = theme.get_icon("grabber", "HSlider")
	connection.reroute_highlight_texture = theme.get_icon("grabber_highlight", "HSlider")
	
	add_child(connection)
	
	connection.initialize(connection_width, display_scale, connection_curvature, p_from, p_from_index, p_to, p_to_index, p_reroute_points)
	
	var snap_distance = -1
	
	if snapping_enabled:
		snap_distance = grid_cell_size
		
	connection.snap_distance = snap_distance
	
	connection.connect("reroute_points_changed", self, "on_reroute_points_changed")
	
	return OK
	
func remove_connection(p_from : GraphEditorNode, p_from_index: int, p_to : GraphEditorNode, p_to_index : int):
	var connection = get_connection(p_from, p_from_index, p_to, p_to_index)
	
	if connection == null:
		return ERR_DOES_NOT_EXIST
		
	connection.queue_free()
	
	return OK
	
func clear():
	for child in get_children():
		child.free()
	
func get_connection(p_from : GraphEditorNode, p_from_index: int, p_to : GraphEditorNode, p_to_index : int):
	for child in get_children():
		var connection = child as Connection
		
		if connection == null:
			continue
		
		if connection.from_node == p_from && connection.to_node == p_to:
			if connection.from_slot_index == p_from_index && connection.to_slot_index == p_to_index:
				return connection
	
	return null
	
func get_incomming_connections(p_node : GraphEditorNode, p_slot_index : int):
	var connections = []
	
	for child in get_children():
		var connection = child as Connection
		
		if connection == null:
			continue
		
		if p_node == connection.to_node && p_slot_index == connection.to_slot_index:
			connections.push_back(connection)
			
	return connections
	
func get_outgoing_connections(p_node : GraphEditorNode, p_slot_index : int):
	var connections = []
	
	for child in get_children():
		var connection = child as Connection
		
		if connection == null:
			continue
		
		if p_node == connection.from_node && p_slot_index == connection.from_slot_index:
			connections.push_back(connection)
			
	return connections
	
	
	
	
	