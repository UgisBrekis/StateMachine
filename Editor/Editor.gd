tool
extends "Views/EditorView.gd"

const EditorTheme = preload("EditorTheme.gd")

const GraphEditorNode = preload("GraphEditorNode.gd")
const GraphEditorEntryNode = preload("GraphEditorEntryNode.gd")
const GraphEditorStateNode = preload("GraphEditorStateNode.gd")

# Currently selected state machine
var active_state_machine : StateMachine = null setget set_active_state_machine

# Dependencies
var editor_interface : EditorInterface = null
var editor_selection : EditorSelection = null
var undo_redo : UndoRedo = null

# Signals
signal attention_request

func _init(p_editor_interface : EditorInterface, p_undo_redo : UndoRedo):
	editor_interface = p_editor_interface as EditorInterface
	editor_selection = editor_interface.get_selection() as EditorSelection
	undo_redo = p_undo_redo as UndoRedo

	theme = editor_interface.get_base_control().theme
	EditorTheme.create_editor_theme(theme)

	initialize_view()

func _enter_tree():
	connect_signals()
	
	graph_editor.undo_redo = undo_redo

func _exit_tree():
	disconnect_signals()

func connect_signals():
	editor_selection.connect("selection_changed", self, "on_editor_interface_selection_changed")

	graph_editor.connect("selection_changed", self, "on_graph_editor_selection_changed")
	graph_editor.connect("inspect_state_request", self, "on_inspect_state_request")
	graph_editor.connect("graph_edited", self, "on_graph_edited")

func disconnect_signals():
	editor_selection.disconnect("selection_changed", self, "on_editor_interface_selection_changed")

	graph_editor.disconnect("selection_changed", self, "on_graph_editor_selection_changed")
	graph_editor.disconnect("inspect_state_request", self, "on_inspect_state_request")
	graph_editor.disconnect("graph_edited", self, "on_graph_edited")

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
		
	for superstate in active_state_machine.graph.superstates:
		superstate.update_property_cache()

func on_header_button_graph_id_pressed(p_id : int):
	match p_id:
		PopupMenuItems.CREATE_NEW:
			create_new_state_machine_graph()

		PopupMenuItems.OPEN:
			show_open_file_dialog()

		PopupMenuItems.SAVE_AS:
			show_save_file_dialog()

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

func on_file_dialog_file_selected(p_path):
	match file_dialog.mode:
		FileDialog.MODE_OPEN_FILE:
			var resource = ResourceLoader.load(p_path)
			
			if !(resource is StateMachine.Graph):
				print("Selected could not be loaded")
				return
			
			active_state_machine.graph = resource
			active_state_machine.property_list_changed_notify()

			graph_editor.graph = active_state_machine.graph

			editor_interface.inspect_object(active_state_machine)

		FileDialog.MODE_SAVE_FILE:
			var err = ResourceSaver.save(p_path, active_state_machine.graph)

			if err != OK:
				print("Error saving state machine graph")
				return

			active_state_machine.graph.take_over_path(p_path)
			active_state_machine.property_list_changed_notify()

			graph_editor.graph = active_state_machine.graph

			editor_interface.inspect_object(active_state_machine)

func on_snaping_toggled(p_toggled):
	graph_editor.snapping_enabled = p_toggled

func on_graph_editor_selection_changed(p_state : StateMachine.Graph.State):
	if active_state_machine == null:
		return

	if active_state_machine.graph == null:
		return

	active_state_machine.active_state = p_state
	active_state_machine.property_list_changed_notify()

	editor_interface.inspect_object(active_state_machine)

func on_inspect_state_request(p_state : StateMachine.Graph.State):
	if active_state_machine == null:
		return

	if p_state == null:
		active_state_machine.active_state = null
		active_state_machine.property_list_changed_notify()
		return

	# Show state script
	if p_state.superstate.state_script != null:
		editor_interface.inspect_object(p_state.superstate.state_script)

	# Show state properties in inspector
	editor_interface.inspect_object(p_state.superstate)

func on_graph_edited():
	if active_state_machine == null:
		return

	active_state_machine.property_list_changed_notify()

func create_new_state_machine_graph():
	if active_state_machine == null:
		return
	
	var graph_resource = StateMachine.Graph.new()
	active_state_machine.graph = graph_resource.duplicate() as StateMachine.Graph

	graph_editor.graph = active_state_machine.graph

	active_state_machine.property_list_changed_notify()

	editor_interface.inspect_object(active_state_machine)

func set_active_state_machine(p_state_machine : StateMachine):
	active_state_machine = p_state_machine

	graph_editor.graph = null

	if active_state_machine == null:
		self.disabled = true
		return

	self.disabled = false
	emit_signal("attention_request")

	if active_state_machine.graph == null:
		return

	graph_editor.graph = active_state_machine.graph

	graph_editor.snapping_enabled = snap_toggle.pressed


