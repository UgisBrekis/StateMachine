tool
extends "Views/EditorView.gd"

const EditorTheme = preload("EditorTheme.gd")

const StateMachineGraph = preload("../Resources/StateMachineGraph.gd")

const GraphEditorNode = preload("GraphEditorNode.gd")
const GraphEditorEntryNode = preload("GraphEditorEntryNode.gd")
const GraphEditorStateNode = preload("GraphEditorStateNode.gd")

# Currently selected state machine
var active_state_machine : StateMachine = null setget set_active_state_machine

# Dependencies
var editor_interface : EditorInterface = null
var editor_selection : EditorSelection = null

# Signals
signal attention_request

func _init(p_editor_interface : EditorInterface):
	editor_interface = p_editor_interface as EditorInterface
	editor_selection = editor_interface.get_selection() as EditorSelection

	theme = editor_interface.get_base_control().theme
	EditorTheme.create_editor_theme(theme)

	initialize_view()

func _enter_tree():
	# Set up valid connection pairs
	graph_editor.add_valid_connection_pair(0, 1)
	graph_editor.add_valid_connection_pair(1, 2)

	connect_signals()

func _exit_tree():
	disconnect_signals()

func connect_signals():
	editor_selection.connect("selection_changed", self, "on_editor_interface_selection_changed")

	graph_editor.connect("selection_changed", self, "on_selection_changed")

	graph_editor.connect("create_state_request", self, "on_create_state_request")
	graph_editor.connect("set_start_state_request", self, "on_set_start_state_request")
	graph_editor.connect("duplicate_state_request", self, "on_duplicate_state_request")
	graph_editor.connect("remove_state_request", self, "on_remove_state_request")
	graph_editor.connect("inspect_state_request", self, "on_inspect_state_request")

	graph_editor.connect("create_connection_request", self, "on_create_connection_request")
	graph_editor.connect("remove_connection_request", self, "on_remove_connection_request")
	graph_editor.connect("reconnect_connection_request", self, "on_reconnect_connection_request")
	graph_editor.connect("reroute_points_changed", self, "on_reroute_points_changed")

func disconnect_signals():
	editor_selection.disconnect("selection_changed", self, "on_editor_interface_selection_changed")

	graph_editor.disconnect("selection_changed", self, "on_selection_changed")

	graph_editor.disconnect("create_state_request", self, "on_create_state_request")
	graph_editor.disconnect("set_start_state_request", self, "on_set_start_state_request")
	graph_editor.disconnect("duplicate_state_request", self, "on_duplicate_state_request")
	graph_editor.disconnect("remove_state_request", self, "on_remove_state_request")
	graph_editor.disconnect("inspect_state_request", self, "on_inspect_state_request")

	graph_editor.disconnect("create_connection_request", self, "on_create_connection_request")
	graph_editor.disconnect("remove_connection_request", self, "on_remove_connection_request")
	graph_editor.disconnect("reconnect_connection_request", self, "on_reconnect_connection_request")

func on_editor_interface_selection_changed():
	var selected_nodes = editor_selection.get_selected_nodes()

	if selected_nodes.size() != 1:
		self.active_state_machine = null
		return

	if !(selected_nodes[0] is StateMachine):
		self.active_state_machine = null
		return

	self.active_state_machine = selected_nodes[0]

func apply_changes():
	if active_state_machine == null:
		return

	if active_state_machine.graph == null:
		return
		
	if graph_editor == null:
		return

	if graph_editor.nodes_layer == null:
		return

	graph_editor.nodes_layer.apply_changes()

func can_drop_data(position, data):
	return true

func drop_data(position, data):
	print("data dropped: %s" % [data])

func on_header_button_graph_id_pressed(p_id : int):
	match p_id:
		CREATE_NEW:
			create_new_state_machine_graph()

		OPEN:
			show_open_file_dialog()

		SAVE_AS:
			show_save_file_dialog()

		MAKE_UNIQUE:
			make_unique_state_machine_graph()

func show_open_file_dialog():
	file_dialog.mode = FileDialog.MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.clear_filters()
	file_dialog.add_filter("*.tres")

	file_dialog.popup_centered_ratio()

func show_save_file_dialog():
	file_dialog.mode = FileDialog.MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.clear_filters()
	file_dialog.add_filter("*.tres")

	file_dialog.popup_centered_ratio()

func make_unique_state_machine_graph():
	if active_state_machine.graph == null:
		return

	var graph_resource = active_state_machine.graph.duplicate()

	graph_editor.clear_graph()

	active_state_machine.graph = graph_resource

	graph_editor.populate_graph(active_state_machine.graph)

	active_state_machine.property_list_changed_notify()

	editor_interface.inspect_object(active_state_machine)

func on_file_dialog_file_selected(p_path):
	match file_dialog.mode:
		FileDialog.MODE_OPEN_FILE:
			var graph_resource = ResourceLoader.load(p_path)

			if !(graph_resource is StateMachineGraph):
				return

			graph_editor.clear_graph()

			active_state_machine.graph = graph_resource

			graph_editor.populate_graph(active_state_machine.graph)

			active_state_machine.property_list_changed_notify()

			editor_interface.inspect_object(active_state_machine)

		FileDialog.MODE_SAVE_FILE:
			ResourceSaver.save(p_path, active_state_machine.graph)

			graph_editor.clear_graph()

			active_state_machine.graph = ResourceLoader.load(p_path)

			graph_editor.populate_graph(active_state_machine.graph)

			active_state_machine.property_list_changed_notify()

			editor_interface.inspect_object(active_state_machine)

func on_snaping_toggled(p_toggled):
	graph_editor.snapping_enabled = p_toggled

func on_selection_changed():
	if active_state_machine == null:
		return

	if active_state_machine.graph == null:
		return

	if graph_editor.selection.size() == 1:
		if graph_editor.selection[0] is GraphEditorStateNode:
			active_state_machine.graph.selected_state = graph_editor.selection[0].state

		else:
			active_state_machine.graph.selected_state = null

	else:
		active_state_machine.graph.selected_state = null

	graph_editor.snapping_enabled = snap_toggle.pressed

	active_state_machine.property_list_changed_notify()

	editor_interface.inspect_object(active_state_machine)

func on_create_state_request(p_position : Vector2, p_state_script : GDScript):
	create_new_state(p_position, p_state_script)

func on_set_start_state_request(p_state_node : GraphEditorStateNode):
	set_start_state(p_state_node)

func on_duplicate_state_request(p_position : Vector2, p_state_node : GraphEditorStateNode):
	duplicate_state(p_position, p_state_node)

func on_remove_state_request(p_state : StateMachineGraph.State):
	remove_state(p_state)

func on_inspect_state_request(p_state : StateMachineGraph.State):
	if active_state_machine == null:
		return

	if p_state == null:
		active_state_machine.graph.selected_state = null
		active_state_machine.property_list_changed_notify()
		return

	# Show state script
	if p_state.state_script != null:
		editor_interface.inspect_object(p_state.state_script)

	# Show state properties in inspector
	editor_interface.inspect_object(p_state)

func on_create_connection_request(p_from : GraphEditorNode, p_from_index : int, p_to : GraphEditorNode, p_to_index : int):
	create_new_transition(p_from, p_from_index, p_to, p_to_index)

func on_remove_connection_request(p_from : GraphEditorNode, p_from_index : int, p_to : GraphEditorNode, p_to_index : int):
	remove_transition(p_from, p_from_index, p_to, p_to_index)

func on_reconnect_connection_request(p_connection, p_from_index : int, p_to_index : int):
	reconnect_transition(p_connection, p_from_index, p_to_index)

func on_reroute_points_changed(p_connection):
	update_reroute_points(p_connection)

func create_new_state_machine_graph():
	if active_state_machine == null:
		return

	graph_editor.clear_graph()

	var graph_resource = StateMachineGraph.new()
	active_state_machine.graph = graph_resource.duplicate()

	graph_editor.populate_graph(active_state_machine.graph)

	active_state_machine.property_list_changed_notify()

	editor_interface.inspect_object(active_state_machine)

func set_active_state_machine(p_state_machine : StateMachine):
	active_state_machine = p_state_machine

	graph_editor.clear_graph()

	if active_state_machine == null:
		self.disabled = true
		return

	self.disabled = false
	emit_signal("attention_request")
	
	if active_state_machine.graph == null:
		return

	if !(active_state_machine.graph is StateMachineGraph):
		active_state_machine.graph = null
		return

	graph_editor.populate_graph(active_state_machine.graph)

	graph_editor.snapping_enabled = snap_toggle.pressed

func set_start_state(p_state_node : GraphEditorStateNode):
	if active_state_machine == null:
		return

	if active_state_machine.graph == null:
		return

	var entry_node = graph_editor.get_entry_node()

	# Disconnect present default node if it's set
	if active_state_machine.graph.start_state_id != -1:
		var default_state = active_state_machine.graph.states[active_state_machine.graph.start_state_id]
		var state_node = graph_editor.get_state_node(default_state)

		remove_transition(entry_node, 0, state_node, 0)

	create_new_transition(entry_node, 0, p_state_node, 0)

func create_new_state(p_position : Vector2, p_state_script : GDScript):
	if active_state_machine == null:
		return

	if active_state_machine.graph == null:
		return

	var new_state = StateMachineGraph.State.new().duplicate()

	new_state.offset = p_position

	if active_state_machine.graph.add_state(new_state) != OK:
		print("create_new_empty_state :: Failed to add state")
		return

	if p_state_script != null:
		new_state.state_script = p_state_script

		# Filename as state name
		var extension = p_state_script.resource_path.get_extension()
		var file_name = p_state_script.resource_path.get_file()
		new_state.label = file_name.rstrip(".%s" % [extension])

	if graph_editor.add_state_node(new_state) != OK:
		print("create_new_empty_state :: Failed to add state node")
		return

	print("create_new_empty_state :: New empty state node added")

func duplicate_state(p_position : Vector2, p_state_node : GraphEditorStateNode):
	if active_state_machine == null:
		return

	if active_state_machine.graph == null:
		return

	var new_state = StateMachineGraph.State.new().duplicate()

	new_state.offset = p_position

	if active_state_machine.graph.add_state(new_state) != OK:
		print("duplicate_state :: Failed to duplicate state")
		return

	# Assign the same state script
	if p_state_node.state.state_script != null:
		new_state.state_script = p_state_node.state.state_script
		
	# Duplicate outputs
	new_state.outputs = p_state_node.state.outputs

	# Duplicate properties
	new_state.properties = p_state_node.state.properties.duplicate()

	if graph_editor.add_state_node(new_state) != OK:
		print("duplicate_state :: Failed to add state node")
		return

	print("duplicate_state :: State duplicated")

func remove_state(p_state : StateMachineGraph.State):
	if active_state_machine == null:
		return

	if active_state_machine.graph == null:
		return

	# Make sure selection is cleared
	if p_state == active_state_machine.graph.selected_state:
		active_state_machine.graph.selected_state = null
		active_state_machine.graph.property_list_changed_notify()

	# Get state index
	var state_index = -1

	for i in active_state_machine.graph.states.size():
		if p_state == active_state_machine.graph.states[i]:
			state_index = i
			break

	if state_index == -1:
		return

	# Remove all transitions connected to this state
	var redundant_transitions = []

	for transition in active_state_machine.graph.transitions:
		if transition.from_state_index == state_index || transition.to_state_index == state_index:
			redundant_transitions.push_back(transition)

	for transition in redundant_transitions:
		var from_state_index = transition.from_state_index
		var from_slot_index = transition.from_slot_index
		var to_state_index = transition.to_state_index
		var to_slot_index = transition.to_slot_index

		if active_state_machine.graph.remove_transition(from_state_index, from_slot_index, to_state_index, to_slot_index) != OK:
			print("remove_state :: Failed to remove transition %s->%s" % [from_state_index, to_state_index])
			return

	redundant_transitions.clear()

	# If state is set as start state, reset it to none
	if active_state_machine.graph.start_state_id == state_index:
		active_state_machine.graph.start_state_id = -1
		active_state_machine.graph.property_list_changed_notify()

	# Get graph editor state node and remove connections
	var state_node : GraphEditorStateNode = graph_editor.get_state_node(p_state)

	if graph_editor.remove_all_connections_from_node(state_node) != OK:
		print("remove_state :: Failed to remove all connections from state node")
		return

	if graph_editor.remove_state_node(state_node) != OK:
		print("remove_state :: Failed to remove state node")
		return

	if active_state_machine.graph.remove_state(p_state) != OK:
		print("remove_state :: Failed to remove state")
		return

	print("remove_state :: State removed")

func create_new_transition(p_from : GraphEditorNode, p_from_index : int, p_to : GraphEditorNode, p_to_index : int):
	if active_state_machine == null:
		return

	if active_state_machine.graph == null:
		return

	# Check if trying to assign new start node
	if p_from is GraphEditorEntryNode && p_to is GraphEditorStateNode:
		var to_state_index = -1

		for i in active_state_machine.graph.states.size():
			if p_to.state == active_state_machine.graph.states[i]:
				to_state_index = i
				break

		if to_state_index == -1:
			print("create_new_transition :: Failed to find to_state_index")
			return

		active_state_machine.graph.start_state_id = to_state_index
		active_state_machine.graph.property_list_changed_notify()

		if graph_editor.connect_graph_nodes(p_from, p_from_index, p_to, p_to_index) != OK:
			print("create_new_transition :: Failed to connect entry to state node")
			return

		print("create_new_transition :: Entry->State transition created!")
		return

	if !(p_from is GraphEditorStateNode) || !(p_to is GraphEditorStateNode):
		print("create_new_transition :: Super stranger bug: p_from || p_to != GraphEditorStateNode")
		return

	# Create a transition in graph resource and if everything's ok, create connection
	var from_state_index : int = -1
	var to_state_index : int = -1

	for i in active_state_machine.graph.states.size():
		if p_from.state == active_state_machine.graph.states[i]:
			from_state_index = i
			continue

		if p_to.state == active_state_machine.graph.states[i]:
			to_state_index = i

		if from_state_index != -1 && to_state_index != -1:
			break

	if from_state_index == -1 || to_state_index == -1:
		print("create_new_transition :: Failed to find from_state_index or to_state_index")
		return

	if active_state_machine.graph.add_transition(from_state_index, p_from_index, to_state_index, p_to_index) != OK:
		print("create_new_transition :: Failed to add transition")
		return

	if graph_editor.connect_graph_nodes(p_from, p_from_index, p_to, p_to_index) != OK:
		print("create_new_transition :: Failed to connect state node to state node")
		return

	print("create_new_transition :: Transition added")

func remove_transition(p_from : GraphEditorNode, p_from_index : int, p_to : GraphEditorNode, p_to_index : int):
	if active_state_machine == null:
		return

	if active_state_machine.graph == null:
		return

	# If start node is being disconnected from entry
	if p_from is GraphEditorEntryNode && p_to is GraphEditorStateNode:
		active_state_machine.graph.start_state_id = -1
		active_state_machine.graph.property_list_changed_notify()

		if graph_editor.disconnect_graph_nodes(p_from, p_from_index, p_to, p_to_index) != OK:
			print("remove_transition :: Failed to disconnect Entry->State nodes")
			return

		print("remove_transition :: Removed Entry-State transition")
		return

	# If state node if being disconnected from another state node
	if !(p_from is GraphEditorStateNode) || !(p_to is GraphEditorStateNode):
		print("remove_transition :: Super stranger bug: p_from || p_to != GraphEditorStateNode")
		return

	var from_state_index : int = -1
	var to_state_index : int = -1

	for i in active_state_machine.graph.states.size():
		if p_from.state == active_state_machine.graph.states[i]:
			from_state_index = i
			continue

		if p_to.state == active_state_machine.graph.states[i]:
			to_state_index = i

		if from_state_index != -1 && to_state_index != -1:
			break

	if from_state_index == -1 || to_state_index == -1:
		print("remove_transition :: Failed to find from_state_index || to_state_index")
		return

	if active_state_machine.graph.remove_transition(from_state_index, p_from_index, to_state_index, p_to_index) != OK:
		print("remove_transition :: Failed to remove state->state transition")
		return

	if graph_editor.disconnect_graph_nodes(p_from, p_from_index, p_to, p_to_index) != OK:
		print("remove_transition :: Failed to disconnect state->state graph nodes")
		return

	print("remove transition :: Removed State->State transition")

func reconnect_transition(p_connection, p_from_index : int, p_to_index : int):
	var from_node : GraphEditorNode = p_connection.from_node
	var to_node : GraphEditorNode = p_connection.to_node
	var from_slot_index : int = p_connection.from_slot_index
	var to_slot_index : int = p_connection.to_slot_index

	# If state node if being disconnected from another state node
	if !(from_node is GraphEditorStateNode) || !(to_node is GraphEditorStateNode):
		return

	var from_state_index : int = -1
	var to_state_index : int = -1

	for i in active_state_machine.graph.states.size():
		if from_node.state == active_state_machine.graph.states[i]:
			from_state_index = i
			continue

		if to_node.state == active_state_machine.graph.states[i]:
			to_state_index = i

		if from_state_index != -1 && to_state_index != -1:
			break

	if from_state_index == -1 || to_state_index == -1:
		return

	var transition = active_state_machine.graph.get_transition(from_state_index, from_slot_index, to_state_index, to_slot_index)

	if transition == null:
		return

	if active_state_machine.graph.reassign_transition(transition, p_from_index, p_to_index) != OK:
		return

	graph_editor.reconnect_graph_nodes(p_connection, p_from_index, p_to_index)

	print("reconnect_transition :: Transition reconnected")
	
func update_reroute_points(p_connection):
	var from_node : GraphEditorNode = p_connection.from_node
	var to_node : GraphEditorNode = p_connection.to_node
	var from_slot_index : int = p_connection.from_slot_index
	var to_slot_index : int = p_connection.to_slot_index

	# If state node if being disconnected from another state node
	if !(from_node is GraphEditorStateNode) || !(to_node is GraphEditorStateNode):
		return

	var from_state_index : int = -1
	var to_state_index : int = -1

	for i in active_state_machine.graph.states.size():
		if from_node.state == active_state_machine.graph.states[i]:
			from_state_index = i
			continue

		if to_node.state == active_state_machine.graph.states[i]:
			to_state_index = i

		if from_state_index != -1 && to_state_index != -1:
			break

	if from_state_index == -1 || to_state_index == -1:
		return

	var transition = active_state_machine.graph.get_transition(from_state_index, from_slot_index, to_state_index, to_slot_index)

	if transition == null:
		return
		
	active_state_machine.graph.update_reroute_points(transition, p_connection.reroute_points)


