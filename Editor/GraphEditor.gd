tool
extends "GraphEditorView.gd"

enum PopupMenuIDs {
	CREATE_NEW_STATE,
	SET_AS_START_STATE,
	DUPLICATE_STATE,
	DELETE_STATE
}

const StateMachineGraph = preload("../Resources/StateMachineGraph.gd")

const GraphEditorNode = preload("GraphEditorNode.gd")

const GraphEditorEntryNode = preload("GraphEditorEntryNode.gd")
const GraphEditorStateNode = preload("GraphEditorStateNode.gd")

# Properties
var disabled : bool = true setget set_disabled
var snapping_enabled : bool = false setget set_snapping_enabled

var valid_connection_pairs = []
var selection = []

var display_scale : float = 1.0
var grid_cell_size : int = 0

# Signals
signal selection_changed

signal create_state_request(p_position, p_state_script)
signal set_start_state_request(p_state_node)
signal remove_state_request(p_state_node)
signal inspect_state_request(p_state)

signal create_connection_request(p_from, p_from_index, p_to, p_to_index)
signal duplicate_state_request(p_position, p_state_node)
signal remove_connection_request(p_from, p_from_index, p_to, p_to_index)
signal reconnect_connection_request(p_connection, p_from_index, p_to_index)
signal reroute_points_changed(p_connection)

func _init(p_theme : Theme):
	theme = p_theme
	initialize_view()
	
	display_scale = theme.get_constant("scale", "Editor")
	grid_cell_size = theme.get_constant("graph_editor_grid_cell_size", "Editor")

func _enter_tree():
	# Scroll Container
	if !scroll_container.is_connected("gui_input", self, "on_scroll_container_gui_input"):
		scroll_container.connect("gui_input", self, "on_scroll_container_gui_input")
		
	if !scroll_container.is_connected("state_scripts_dropped", self, "on_state_scripts_dropped"):
		scroll_container.connect("state_scripts_dropped", self, "on_state_scripts_dropped")
		
	# Connections layer
	if !connections_layer.is_connected("reconnect_requested", self, "on_connection_reconnect_requested"):
		connections_layer.connect("reconnect_requested", self, "on_connection_reconnect_requested")
		
	if !connections_layer.is_connected("remove_requested", self, "on_connection_remove_requested"):
		connections_layer.connect("remove_requested", self, "on_connection_remove_requested")
		
	if !connections_layer.is_connected("reroute_points_changed", self, "on_reroute_points_changed"):
		connections_layer.connect("reroute_points_changed", self, "on_reroute_points_changed")
	
	# Overlay Layer
	if !overlay_layer.is_connected("connection_drag_completed", self, "on_overlay_layer_connection_drag_completed"):
		overlay_layer.connect("connection_drag_completed", self, "on_overlay_layer_connection_drag_completed")
		
	if !overlay_layer.is_connected("selection_box_drag_completed", self, "on_overlay_layer_selection_box_drag_completed"):
		overlay_layer.connect("selection_box_drag_completed", self, "on_overlay_layer_selection_box_drag_completed")
	
	# Popup Menu
	if !popup_menu.is_connected("id_pressed", self, "on_popup_menu_id_pressed"):
		popup_menu.connect("id_pressed", self, "on_popup_menu_id_pressed")
	
func set_disabled(p_disabled : bool):
	disabled = p_disabled
	
func set_snapping_enabled(p_snapping_enabled : bool):
	snapping_enabled = p_snapping_enabled
	
	var snap_distance = -1
	
	if snapping_enabled:
		snap_distance = grid_cell_size
	
	for node in nodes_layer.get_children():
		node.snap_distance = snap_distance
		
	for connection in connections_layer.get_children():
		connection.snap_distance = snap_distance

func on_scroll_container_gui_input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				BUTTON_LEFT:
					if !Input.is_key_pressed(KEY_SHIFT) && !Input.is_key_pressed(KEY_META):
						# Deselect everything
						clear_selection()
					
					overlay_layer.begin_selection_box_drag(overlay_layer.get_local_mouse_position())
				
				BUTTON_RIGHT:
					show_popup_menu(event.global_position, null)
	
func on_connection_reconnect_requested(p_connection, p_from_index : int, p_to_index : int):
	emit_signal("reconnect_connection_request", p_connection, p_from_index, p_to_index)
	
func on_connection_remove_requested(p_connection):
	emit_signal("remove_connection_request", p_connection.from_node, p_connection.from_slot_index, p_connection.to_node, p_connection.to_slot_index)
	
func on_reroute_points_changed(p_connection):
	emit_signal("reroute_points_changed", p_connection)
	
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
			emit_signal("remove_connection_request", connection.from_node, connection.from_slot_index, connection.to_node, connection.to_slot_index)
	
	overlay_layer.begin_connection_drag(p_input, socket_position, snap_positions)
	
func on_overlay_layer_connection_drag_completed(p_from_position : Vector2, p_to_position : Vector2, p_is_empty_space : bool):
	if p_is_empty_space:
		return
	
	# Find nodes in positions
	var from_node : GraphEditorNode = null
	var to_node : GraphEditorNode = null
	
	# From node
	var nodes = nodes_layer.get_nodes_from_position(p_from_position)
	
	if nodes.size() > 0:
		from_node = nodes[0]
		
		# Get the node that's on top of all others
		for node in nodes:
			if node.get_position_in_parent() > from_node.get_position_in_parent():
				from_node = node
				
	# To node
	nodes = nodes_layer.get_nodes_from_position(p_to_position)
	
	if nodes.size() > 0:
		to_node = nodes[0]
		
		# Get the node that's on top of all others
		for node in nodes:
			if node.get_position_in_parent() > to_node.get_position_in_parent():
				to_node = node
	
	if from_node == null || to_node == null:
		return
		
	if from_node == to_node:
		return
	
	# Find slots in nodes
	var from_slot = null
	var to_slot = null
	
	from_slot = from_node.get_slot_index_from_position(false, p_from_position)
	to_slot = to_node.get_slot_index_from_position(true, p_to_position)
	
	if from_slot == null || to_slot == null:
		return
		
	emit_signal("create_connection_request", from_node, from_slot, to_node, to_slot)
	
func on_overlay_layer_selection_box_drag_completed(p_rect : Rect2):
	for node in nodes_layer.get_children():
		if !p_rect.intersects(node.get_rect()):
			continue
			
		if Input.is_key_pressed(KEY_META):
			remove_from_selection(node)
			continue
			
		add_to_selection(node)
		
func on_state_scripts_dropped(p_state_scripts):
	var root_position = layers_container.get_local_mouse_position() / display_scale
	var position_step = Vector2(20, 20) * display_scale
	
	for i in p_state_scripts.size():
		emit_signal("create_state_request", root_position + position_step * i, p_state_scripts[i])
	
func on_popup_menu_id_pressed(p_id):
	match p_id:
		CREATE_NEW_STATE:
			emit_signal("create_state_request", layers_container.get_local_mouse_position() / display_scale, null)
			
		SET_AS_START_STATE:
			if selection.size() != 1:
				return
			
			emit_signal("set_start_state_request", selection[0])
			
		DUPLICATE_STATE:
			var position_offset = Vector2(20, 20) * display_scale
			
			for i in selection.size():
				emit_signal("duplicate_state_request", layers_container.get_local_mouse_position() / display_scale + position_offset * i, selection[i])
			
		DELETE_STATE:
			var states_to_remove = []
			
			for node in selection:
				states_to_remove.push_back(node.state)
			
			for state in states_to_remove:
				emit_signal("remove_state_request", state)
				
			states_to_remove.clear()
	
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
	
func on_graph_node_drag_request(p_relative_position : Vector2):
	for node in selection:
		var graph_editor_node = node as GraphEditorNode
		
		graph_editor_node.offset += p_relative_position
	
func on_state_node_right_clicked(p_node : GraphEditorStateNode):
	if selection.size() > 1:
		pass
	else:
		select_node(p_node)
		
	show_popup_menu(get_global_mouse_position(), p_node)
	
func on_state_node_doubleclicked(p_node : GraphEditorStateNode):
	emit_signal("inspect_state_request", p_node.state)
	
func select_node(p_node : GraphEditorNode):
	for node in selection:
		var graph_editor_node = node as GraphEditorNode
		graph_editor_node.is_selected = false
		
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
		var graph_editor_node = node as GraphEditorNode
		graph_editor_node.is_selected = false
		
	selection.clear()
	
	emit_signal("selection_changed")
	
func show_popup_menu(p_position : Vector2, p_node : GraphEditorNode):
	if popup_menu == null:
		return
		
	popup_menu.clear()
	popup_menu.rect_size = Vector2()
	
	if p_node == null:
		clear_selection()

	if selection.size() == 0:
		popup_menu.add_item("New state", CREATE_NEW_STATE)
		
	elif selection.size() == 1:
		popup_menu.add_item("Set as default", SET_AS_START_STATE)
		popup_menu.add_separator()
		popup_menu.add_item("Duplicate", DUPLICATE_STATE)
		popup_menu.add_separator()
		popup_menu.add_item("Remove", DELETE_STATE)
	
	else:
		popup_menu.add_item("Duplicate", DUPLICATE_STATE)
		popup_menu.add_separator()
		popup_menu.add_item("Remove", DELETE_STATE)
	
	popup_menu.rect_position = p_position
	popup_menu.popup()
	
func add_valid_connection_pair(p_from_type : int, p_to_type : int):
	for pair in valid_connection_pairs:
		if pair.from_type == p_from_type:
			if pair.to_type == p_to_type:
				return
	
	var pair = { "from_type" : p_from_type, "to_type" : p_to_type }
	
	valid_connection_pairs.push_back(pair)
	
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
	
func populate_graph(p_graph : StateMachineGraph):
	clear_graph()
	
	# Entry node
	add_entry_node(p_graph)
	
	# State nodes
	for state in p_graph.states:
		add_state_node(state)
		
	# Entry->Start transition
	if p_graph.start_state_id != -1:
		var entry_node : GraphEditorEntryNode = get_entry_node()
		var start_node : GraphEditorStateNode = null
		
		for child in nodes_layer.get_children():
			if !(child is GraphEditorStateNode):
				continue
				
			var state_node = child as GraphEditorStateNode
			
			if state_node.state == p_graph.states[p_graph.start_state_id]:
				start_node = state_node
				break
				
		if entry_node != null && start_node != null:
			connect_graph_nodes(entry_node, 0, start_node, 0)
		
	# State transitions
	for transition in p_graph.transitions:
		var from_state = p_graph.states[transition.from_state_index]
		var to_state = p_graph.states[transition.to_state_index]
		
		if from_state == null || to_state == null:
			continue
			
		var from_node : GraphEditorStateNode = null
		var to_node : GraphEditorStateNode = null
		
		for state_node in nodes_layer.get_children():
			if !(state_node is GraphEditorStateNode):
				continue
				
			if state_node.state == from_state:
				from_node = state_node
				
			elif state_node.state == to_state:
				to_node = state_node
				
			if from_node != null && to_node != null:
				break
				
		if from_node == null || to_node == null:
			return
		
		connect_graph_nodes(from_node, transition.from_slot_index, to_node, transition.to_slot_index, transition.reroute_points)
	
func clear_graph():
	clear_selection()
	
	connections_layer.clear()
	nodes_layer.clear()
	
	return OK

func add_entry_node(p_graph : StateMachineGraph):
	var entry_node : GraphEditorEntryNode = GraphEditorEntryNode.new(theme)
	
	nodes_layer.add_child(entry_node)
	
	entry_node.initialize(p_graph)
	
	entry_node.connect("left_clicked", self, "on_node_left_clicked", [entry_node])
	entry_node.connect("drag_request", self, "on_graph_node_drag_request")
	entry_node.connect("socket_drag_started", self, "on_node_socket_drag_started")
	
	return OK

func add_state_node(p_state):
	var state_node : GraphEditorStateNode = GraphEditorStateNode.new(theme)
	
	nodes_layer.add_child(state_node)
	
	state_node.initialize(p_state)
	
	state_node.connect("left_clicked", self, "on_node_left_clicked", [state_node])
	state_node.connect("drag_request", self, "on_graph_node_drag_request")
	state_node.connect("right_clicked", self, "on_state_node_right_clicked", [state_node])
	state_node.connect("doubleclicked", self, "on_state_node_doubleclicked", [state_node])
	state_node.connect("socket_drag_started", self, "on_node_socket_drag_started")
	
	return OK
	
func get_entry_node():
	for child in nodes_layer.get_children():
		if child is GraphEditorEntryNode:
			return child
	
	return null
	
func get_state_node(p_state : StateMachineGraph.State):
	for child in nodes_layer.get_children():
		if !(child is GraphEditorStateNode):
			continue
			
		if child.state == p_state:
			return child
	
	return null
	
func remove_state_node(p_state_node : GraphEditorStateNode):
	if selection.size() > 0:
		clear_selection()
	
	p_state_node.queue_free()
	
	return OK
	
func remove_all_connections_from_node(p_node : GraphEditorNode):
	var err = OK
	
	if p_node is GraphEditorStateNode:
		for child in connections_layer.get_children():
			if p_node == child.from_node || p_node == child.to_node:
				err = connections_layer.remove_connection(child.from_node, child.from_slot_index, child.to_node, child.to_slot_index)
				
				if err != OK:
					return err
	
	return err
	
func connect_graph_nodes(p_from : GraphEditorNode, p_from_index: int, p_to : GraphEditorNode, p_to_index : int, p_reroute_points : PoolVector2Array = PoolVector2Array()):
	if connections_layer.add_new_connection(p_from, p_from_index, p_to, p_to_index, p_reroute_points) != OK:
		return ERR_BUG
		
	return OK
	
func disconnect_graph_nodes(p_from : GraphEditorNode, p_from_index: int, p_to : GraphEditorNode, p_to_index : int):
	if connections_layer.remove_connection(p_from, p_from_index, p_to, p_to_index) != OK:
		return ERR_BUG
		
	return OK
	
func reconnect_graph_nodes(p_connection, p_from_index : int, p_to_index : int):
	if connections_layer.reassign_connection(p_connection, p_from_index, p_to_index) != OK:
		return ERR_BUG
		
	return OK