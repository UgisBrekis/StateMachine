tool
extends "Views/GraphEditorView.gd"

enum PopupMenuIDs {
	CREATE_NEW_STATE,
	SET_AS_START_STATE,
	DUPLICATE_STATE,
	DELETE_STATE
}

const GraphEditorNode = preload("GraphEditorNode.gd")

const GraphEditorEntryNode = preload("GraphEditorEntryNode.gd")
const GraphEditorStateNode = preload("GraphEditorStateNode.gd")

# Properties
var graph : StateMachine.Graph = null setget set_graph

var disabled : bool = true setget set_disabled
var snapping_enabled : bool = false setget set_snapping_enabled

var valid_connection_pairs = []

var display_scale : float = 1.0

# Signals
signal selection_changed(p_state)

signal set_start_state_request(p_state_node)
signal inspect_state_request(p_state)

signal reroute_points_changed(p_connection)

signal graph_edited

func _init(p_theme : Theme):
	theme = p_theme
	initialize_view()
	
	display_scale = theme.get_constant("scale", "Editor")

func _enter_tree():
	# Set up valid connection pairs
	add_valid_connection_pair(0, 1)
	add_valid_connection_pair(1, 2)
	
	# Scroll Container
	scroll_container.connect("left_click_down", self, "on_scroll_container_left_click_down")
	scroll_container.connect("right_click_down", self, "on_scroll_container_context_menu_request")
	scroll_container.connect("state_scripts_dropped", self, "on_state_scripts_dropped")
	
	# Connections layer
	connections_layer.connect("reroute_points_changed", self, "on_reroute_points_changed")
	
	# Nodes layer
	nodes_layer.connect("selection_changed", self, "on_nodes_layer_selection_changed")
	nodes_layer.connect("inspect_state_request", self, "on_inspect_state_request")
	nodes_layer.connect("state_node_context_menu_request", self, "on_state_node_context_menu_request")
	nodes_layer.connect("begin_connection_drag_request", self, "on_begin_connection_drag_request")
	nodes_layer.connect("dragged", self, "on_nodes_layer_dragged")
	
	# Overlay Layer
	overlay_layer.connect("connection_drag_completed", self, "on_overlay_layer_connection_drag_completed")
	overlay_layer.connect("selection_box_drag_completed", self, "on_overlay_layer_selection_box_drag_completed")
	
	# Popup Menu
	popup_menu.connect("id_pressed", self, "on_popup_menu_id_pressed")
	
func set_graph(p_graph : StateMachine.Graph):
	clear_graph()
	
	if !(p_graph is StateMachine.Graph):
		graph = null
		return
	
	graph = p_graph
	
	populate_graph(graph)
	
func set_disabled(p_disabled : bool):
	disabled = p_disabled
	
func set_snapping_enabled(p_snapping_enabled : bool):
	snapping_enabled = p_snapping_enabled
	
	connections_layer.snapping_enabled = snapping_enabled
	nodes_layer.snapping_enabled = snapping_enabled

func on_scroll_container_left_click_down():
	if !Input.is_key_pressed(KEY_SHIFT) && !Input.is_key_pressed(KEY_META):
		nodes_layer.clear_selection()
		
	overlay_layer.begin_selection_box_drag()
	
func on_scroll_container_context_menu_request():
	show_popup_menu(null)

func on_reroute_points_changed(p_connection):
	update_reroute_points(p_connection)
	
func on_nodes_layer_selection_changed():
	var state = null
	
	if nodes_layer.selection.size() == 1:
		if nodes_layer.selection[0] is GraphEditorStateNode:
			state = nodes_layer.selection[0].state
	
	emit_signal("selection_changed", state)
	
func on_inspect_state_request(p_state):
	emit_signal("inspect_state_request", p_state)
	
func on_state_node_context_menu_request(p_node):
	show_popup_menu(p_node)
	
func on_begin_connection_drag_request(p_node : GraphEditorNode, p_input : bool, p_slot_index : int, snap_positions : PoolVector2Array):
	var socket_position = p_node.get_socket_position(p_input, p_slot_index)
	
	# If it's output slot, remove already existing connection
	if !p_input:
		var output_connections = connections_layer.get_outgoing_connections(p_node, p_slot_index)
		
		for connection in output_connections:
			remove_transition(connection.from_node, connection.from_slot_index, connection.to_node, connection.to_slot_index)
	
	overlay_layer.begin_connection_drag(p_input, socket_position, snap_positions)
	
func on_nodes_layer_dragged(p_relative : Vector2):
	emit_signal("graph_edited")
	
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
		
	create_new_transition(from_node, from_slot, to_node, to_slot)
	
func on_overlay_layer_selection_box_drag_completed(p_rect : Rect2):
	if Input.is_key_pressed(KEY_META):
		nodes_layer.box_deselect(p_rect)
		return
		
	nodes_layer.box_select(p_rect)
		
func on_state_scripts_dropped(p_state_scripts):
	var root_position = layers_container.get_local_mouse_position() / display_scale
	var position_step = Vector2(20, 20) * display_scale
	
	for i in p_state_scripts.size():
		create_new_state(root_position + position_step * i, p_state_scripts[i])
	
func on_popup_menu_id_pressed(p_id):
	match p_id:
		PopupMenuIDs.CREATE_NEW_STATE:
			create_new_state(layers_container.get_local_mouse_position() / display_scale, null)
			
		PopupMenuIDs.SET_AS_START_STATE:
			if nodes_layer.selection.size() != 1:
				return
				
			if !(nodes_layer.selection[0] is GraphEditorStateNode):
				return
			
			set_start_state(nodes_layer.selection[0])
			
		PopupMenuIDs.DUPLICATE_STATE:
			var position_offset = Vector2(20, 20) * display_scale
			
			for i in nodes_layer.selection.size():
				if !(nodes_layer.selection[i] is GraphEditorStateNode):
					continue
				
				duplicate_state(nodes_layer.selection[i].state, layers_container.get_local_mouse_position() / display_scale + position_offset * i)
			
		PopupMenuIDs.DELETE_STATE:
			var states_to_remove = []
			
			for node in nodes_layer.selection:
				if !(node is GraphEditorStateNode):
					continue
				
				states_to_remove.push_back(node.state)
			
			for state in states_to_remove:
				remove_state(state)
				
			states_to_remove.clear()
	
func set_start_state(p_state_node : GraphEditorStateNode):
	if graph == null:
		return

	var entry_node = nodes_layer.get_entry_node()

	# Disconnect present default node if it's set
	if graph.start_state_id != -1:
		var default_state = graph.states[graph.start_state_id]
		var state_node = nodes_layer.get_state_node(default_state)
		
		remove_transition(entry_node, 0, state_node, 0)

	create_new_transition(entry_node, 0, p_state_node, 0)
	
func create_new_state(p_position : Vector2, p_state_script : GDScript):
	if graph == null:
		return

	nodes_layer.add_state_node(graph.add_state(p_position, p_state_script))
	
func duplicate_state(p_state : StateMachine.Graph.State, p_position : Vector2):
	if graph == null:
		return

	nodes_layer.add_state_node(graph.duplicate_state(p_state, p_position))
	
func remove_state(p_state : StateMachine.Graph.State):
	if graph == null:
		return

	# Make sure selection is cleared
	nodes_layer.clear_selection()

	# Remove all transitions connected to this state
	var redundant_transitions = []

	for transition in graph.transitions:
		transition = transition as StateMachine.Graph.Transition
		
		if transition.from_state == p_state || transition.to_state == p_state:
			redundant_transitions.push_back(transition)

	for transition in redundant_transitions:
		transition = transition as StateMachine.Graph.Transition
		
		var from_state = transition.from_state
		var from_slot_index = transition.from_slot_index
		var to_state = transition.to_state
		var to_slot_index = transition.to_slot_index

		if graph.remove_transition(from_state, from_slot_index, to_state, to_slot_index) != OK:
			return

	redundant_transitions.clear()

	# If state is set as start state, reset it to none
	if graph.states[graph.start_state_id] == p_state:
		graph.start_state_id = -1

	# Get graph editor state node and remove connections
	var state_node : GraphEditorStateNode = nodes_layer.get_state_node(p_state)

	if remove_all_connections_from_node(state_node) != OK:
		print("remove_state :: Failed to remove all connections from state node")
		return

	nodes_layer.remove_state_node(state_node)

	if graph.remove_state(p_state) != OK:
		print("remove_state :: Failed to remove state")
		return

	print("remove_state :: State removed")
	
func create_new_transition(p_from : GraphEditorNode, p_from_index : int, p_to : GraphEditorNode, p_to_index : int):
	if graph == null:
		return

	if p_from is GraphEditorEntryNode && p_to is GraphEditorStateNode:
		graph.set_state_as_default(p_to.state)
		
	elif p_from is GraphEditorStateNode && p_to is GraphEditorStateNode:
		graph.add_transition(p_from.state, p_from_index, p_to.state, p_to_index)
		
	else:
		return
	
	connections_layer.add_new_connection(p_from, p_from_index, p_to, p_to_index, PoolVector2Array())
	
func remove_transition(p_from : GraphEditorNode, p_from_index : int, p_to : GraphEditorNode, p_to_index : int):
	if graph == null:
		return

	# If start node is being disconnected from entry
	if p_from is GraphEditorEntryNode && p_to is GraphEditorStateNode:
		graph.set_state_as_default(null)
		
	elif p_from is GraphEditorStateNode && p_to is GraphEditorStateNode:
		graph.remove_transition(p_from.state, p_from_index, p_to.state, p_to_index)
		
	else:
		return
	
	connections_layer.remove_connection(p_from, p_from_index, p_to, p_to_index)
	
func update_reroute_points(p_connection):
	if graph == null:
		return
	
	var from_node : GraphEditorNode = p_connection.from_node
	var to_node : GraphEditorNode = p_connection.to_node
	var from_slot_index : int = p_connection.from_slot_index
	var to_slot_index : int = p_connection.to_slot_index

	# If state node if being disconnected from another state node
	if !(from_node is GraphEditorStateNode) || !(to_node is GraphEditorStateNode):
		return
	
	var transition = graph.get_transition(from_node.state, from_slot_index, to_node.state, to_slot_index)

	if transition == null:
		return
		
	graph.update_reroute_points(transition, p_connection.reroute_points)
	
func show_popup_menu(p_node : GraphEditorNode):
	if popup_menu == null:
		return
		
	popup_menu.clear()
	popup_menu.rect_size = Vector2()
	
	if p_node == null:
		nodes_layer.clear_selection()

	if nodes_layer.selection.size() == 0:
		popup_menu.add_item("New state", PopupMenuIDs.CREATE_NEW_STATE)
		
	elif nodes_layer.selection.size() == 1:
		popup_menu.add_item("Set as default", PopupMenuIDs.SET_AS_START_STATE)
		popup_menu.add_separator()
		popup_menu.add_item("Duplicate", PopupMenuIDs.DUPLICATE_STATE)
		popup_menu.add_separator()
		popup_menu.add_item("Remove", PopupMenuIDs.DELETE_STATE)
	
	else:
		popup_menu.add_item("Duplicate", PopupMenuIDs.DUPLICATE_STATE)
		popup_menu.add_separator()
		popup_menu.add_item("Remove", PopupMenuIDs.DELETE_STATE)
	
	popup_menu.rect_position = get_global_mouse_position()
	popup_menu.popup()
	
func add_valid_connection_pair(p_from_type : int, p_to_type : int):
	for pair in valid_connection_pairs:
		if pair.from_type == p_from_type:
			if pair.to_type == p_to_type:
				return
	
	var pair = { "from_type" : p_from_type, "to_type" : p_to_type }
	
	valid_connection_pairs.push_back(pair)
	
	nodes_layer.valid_connection_pairs = valid_connection_pairs
	
func populate_graph(p_graph : StateMachine.Graph):
	clear_graph()
	
	# Entry node
	nodes_layer.add_entry_node(p_graph)
	
	# State nodes
	for state in p_graph.states:
		nodes_layer.add_state_node(state)
		
	# Entry->Start transition
	if p_graph.start_state_id != -1:
		var entry_node : GraphEditorEntryNode = nodes_layer.get_entry_node()
		var start_node : GraphEditorStateNode = null
		
		for child in nodes_layer.get_children():
			if !(child is GraphEditorStateNode):
				continue
				
			var state_node = child as GraphEditorStateNode
			
			if state_node.state == p_graph.states[p_graph.start_state_id]:
				start_node = state_node
				break
				
		if entry_node != null && start_node != null:
			connections_layer.add_new_connection(entry_node, 0, start_node, 0, PoolVector2Array())
		
	# State transitions
	for transition in p_graph.transitions:
		transition = transition as StateMachine.Graph.Transition
		
		var from_state = transition.from_state
		var to_state = transition.to_state
		
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
		
		connections_layer.add_new_connection(from_node, transition.from_slot_index, to_node, transition.to_slot_index, transition.reroute_points)
	
func clear_graph():
	nodes_layer.clear_selection()
	
	connections_layer.clear()
	nodes_layer.clear()
	
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
	
	

	
	