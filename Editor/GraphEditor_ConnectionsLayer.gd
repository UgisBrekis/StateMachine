tool
extends Control

const GraphEditorNode = preload("GraphEditorNode.gd")
const Connection = preload("GraphEditorConnection.gd")

var connection_width : float = 1
var connection_curvature : float = 20

var selected_connections = []

# Signals
signal connection_added(p_from, p_from_index, p_to, p_to_index)
signal connection_removed

signal cleared
signal reconnect_requested(p_connection, p_from_index, p_to_index)
signal remove_requested(p_connection)

func _init(p_theme : Theme):
	theme = p_theme
	connection_width = theme.get_constant("graph_editor_connection_width", "Editor")
	connection_curvature = theme.get_constant("graph_editor_connection_curvature", "Editor")
	
func _input(event):
	if event is InputEventMouseMotion:
		selected_connections.clear()
		
		for child in get_children():
			var connection = child as Connection
			
			if connection == null:
				return
			
			if connection.curve.get_closest_point(get_local_mouse_position()).distance_to(get_local_mouse_position()) < 20:
				selected_connections.push_back(connection)
				
		update()

func on_reconnect_requested(p_connection : Connection, p_from_index : int, p_to_index : int):
	emit_signal("reconnect_requested", p_connection, p_from_index, p_to_index)
	
func on_remove_requested(p_connection : Connection):
	emit_signal("remove_requested", p_connection)

func add_new_connection(p_from : GraphEditorNode, p_from_index: int, p_to : GraphEditorNode, p_to_index : int):
	var connection : Connection = Connection.new()
	add_child(connection)
	
	connection.initialize(connection_width, connection_curvature, p_from, p_from_index, p_to, p_to_index)
	
	connection.connect("reconnect_requested", self, "on_reconnect_requested")
	connection.connect("remove_requested", self, "on_remove_requested")
	
	return OK
	
func remove_connection(p_from : GraphEditorNode, p_from_index: int, p_to : GraphEditorNode, p_to_index : int):
	var connection = get_connection(p_from, p_from_index, p_to, p_to_index)
	
	if connection == null:
		return ERR_DOES_NOT_EXIST
		
	connection.queue_free()
	
	return OK
	
func reassign_connection(p_connection : Connection, p_from_index : int, p_to_index : int):
	p_connection.from_slot_index = p_from_index
	p_connection.to_slot_index = p_to_index
	
	p_connection.update_positions()
	
func clear():
	for child in get_children():
		if !(child is Connection):
			continue
			
		child.queue_free()
	
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
	
func _draw():
	for connection in selected_connections:
		var p = connection.curve.get_closest_point(get_local_mouse_position())
		
		draw_circle(p, 20, Color(1, 1, 0, 0.5))
	
	
	
	
	