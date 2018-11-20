tool
extends Control

const GraphEditorNode = preload("GraphEditorNode.gd")
const GraphEditorNodeSlot = preload("GraphEditorNodeSlot.gd")

const GraphEditorEntryNode = preload("GraphEditorEntryNode.gd")
const GraphEditorStateNode = preload("GraphEditorStateNode.gd")

var snapping_enabled = false setget set_snapping_enabled
var grid_cell_size = 10

var selection = []

signal selection_changed
signal inspect_state_request(p_state)
signal state_node_context_menu_request(p_state_node)

func _init(p_theme : Theme):
	theme = p_theme
	grid_cell_size = theme.get_constant("graph_editor_grid_cell_size", "Editor")

func set_snapping_enabled(p_snapping_enabled : bool):
	snapping_enabled = p_snapping_enabled
	
	var snap_distance = -1
	
	if snapping_enabled:
		snap_distance = grid_cell_size
	
	for node in get_children():
		node = node as GraphEditorNode
		
		node.snap_distance = snap_distance

func add_entry_node(p_graph : StateMachine.Graph):
	var entry_node : GraphEditorEntryNode = GraphEditorEntryNode.new(theme)
	
	add_child(entry_node)
	
	entry_node.initialize(p_graph)
	
	entry_node.connect("left_clicked", self, "on_node_left_clicked", [entry_node])
	entry_node.connect("drag_request", self, "on_graph_node_drag_request")
	entry_node.connect("socket_drag_started", self, "on_node_socket_drag_started")
	
func get_entry_node():
	for child in get_children():
		if child is GraphEditorEntryNode:
			return child
	
	return null

func add_state_node(p_state):
	var state_node : GraphEditorStateNode = GraphEditorStateNode.new(theme)
	
	add_child(state_node)
	
	state_node.initialize(p_state)
	
	state_node.connect("left_clicked", self, "on_node_left_clicked", [state_node])
	state_node.connect("right_clicked", self, "on_state_node_right_clicked", [state_node])
	state_node.connect("doubleclicked", self, "on_state_node_doubleclicked", [state_node])
	state_node.connect("drag_request", self, "on_graph_node_drag_request")
	state_node.connect("socket_drag_started", self, "on_node_socket_drag_started")
	
func get_state_node(p_state : StateMachine.Graph.State):
	for child in get_children():
		if !(child is GraphEditorStateNode):
			continue
			
		if child.state == p_state:
			return child
	
	return null
	
func remove_state_node(p_state_node : GraphEditorStateNode):
	if selection.size() > 0:
		clear_selection()
	
	p_state_node.queue_free()

func clear():
	for child in get_children():
		child.free()
		
func box_select(p_rect : Rect2):
	for node in get_children():
		node = node as GraphEditorNode
		
		if p_rect.intersects(node.get_rect()):
			add_to_selection(node)
	
func box_deselect(p_rect : Rect2):
	for node in get_children():
		node = node as GraphEditorNode
		
		if p_rect.intersects(node.get_rect()):
			remove_from_selection(node)
		
func select_node(p_node : GraphEditorNode):
	for node in selection:
		node = node as GraphEditorNode
		
		node.is_selected = false
		
	selection.clear()
	
	selection.push_back(p_node)
	p_node.is_selected = true
	
	emit_signal("selection_changed")
	
func add_to_selection(p_node : GraphEditorNode):
	if selection.has(p_node):
		return
	
	selection.push_back(p_node)
	p_node.is_selected = true
		
	emit_signal("selection_changed")
	
func remove_from_selection(p_node : GraphEditorNode):
	if !selection.has(p_node):
		return
		
	selection.erase(p_node)
	p_node.is_selected = false
	
	emit_signal("selection_changed")
	
func clear_selection():
	for node in selection:
		node = node as GraphEditorNode
		node.is_selected = false
		
	selection.clear()
	
	emit_signal("selection_changed")
		
func on_node_left_clicked(p_node : GraphEditorNode):
	if Input.is_key_pressed(KEY_SHIFT):
		add_to_selection(p_node)
		return
		
	elif Input.is_key_pressed(KEY_META):
		remove_from_selection(p_node)
		return
		
	if selection.size() > 1:
		if selection.has(p_node):
			return
		
	select_node(p_node)
	
func on_state_node_right_clicked(p_node : GraphEditorStateNode):
	if selection.size() > 1:
		pass
	else:
		select_node(p_node)
		
	emit_signal("state_node_context_menu_request", p_node)
	
func on_state_node_doubleclicked(p_node : GraphEditorStateNode):
	emit_signal("inspect_state_request", p_node.state)
	
func on_graph_node_drag_request(p_relative_position : Vector2):
	for node in selection:
		var graph_editor_node = node as GraphEditorNode
		
		graph_editor_node.offset += p_relative_position
		
func on_node_socket_drag_started(p_node : GraphEditorNode, p_input : bool, p_slot_index : int):
	var slot_type = p_node.get_slot_type(p_input, p_slot_index)
	var socket_position = p_node.get_socket_position(p_input, p_slot_index)
	
	# Find snap positions for this type of slot
	var valid_types = get_valid_connection_types(p_input, slot_type)
	var snap_positions : PoolVector2Array = get_socket_positions(valid_types)
	
	# If it's output slot, remove already existing connection
	if !p_input:
		var output_connections = connections_layer.get_outgoing_connections(p_node, p_slot_index)
		
		for connection in output_connections:
			remove_transition(connection.from_node, connection.from_slot_index, connection.to_node, connection.to_slot_index)
	
	emit_signal("begin_connection_drag_request", p_input, socket_position, snap_positions)
	
func get_valid_connection_types(p_is_input : bool, p_type : int):
	var valid_types : PoolIntArray = PoolIntArray()
	
	for pair in valid_connection_pairs:
		if pair.from_type == p_type:
			valid_types.push_back(pair.to_type)
			
		elif pair.to_type == p_type:
			valid_types.push_back(pair.from_type)
		
	return valid_types
	
func get_socket_positions(p_valid_types : PoolIntArray = PoolIntArray()):
	var socket_positions : PoolVector2Array = PoolVector2Array()
	
	for child in nodes_layer.get_children():
		if !(child is GraphEditorNode):
			return
			
		var node : GraphEditorNode = child
		
		var input_slot_count = node.get_input_slot_count()
		var output_slot_count = node.get_output_slot_count()
		
		# Input sockets
		for i in input_slot_count:
			var slot = node.get_input_slot(i)
			
			# Check slot type
			if p_valid_types.size() > 0 && !(slot.socket_type in p_valid_types):
				continue
			
			var socket_position = node.get_socket_position(true, i)
			socket_positions.push_back(socket_position)
			
		# Output sockets
		for i in output_slot_count:
			var slot = node.get_output_slot(i)
			
			# Check slot type
			if p_valid_types.size() > 0 && !(slot.socket_type in p_valid_types):
				continue
			
			var socket_position = node.get_socket_position(false, i)
			socket_positions.push_back(socket_position)
			
	return socket_positions

func get_nodes_from_position(p_position : Vector2):
	var nodes = []
	
	for child in get_children():
		if !(child is GraphEditorNode):
			continue
			
		if child.get_rect().has_point(p_position):
			nodes.push_back(child)
	
	return nodes
	
		


