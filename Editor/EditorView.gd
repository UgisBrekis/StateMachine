tool
extends Control

const GraphEditor = preload("GraphEditor.gd")

enum PopupMenuItems {
	CREATE_NEW,
	OPEN,
	SAVE_AS,
	MAKE_UNIQUE
}

# Nodes
var header_button_graph : MenuButton = null
var snap_toggle : Button = null
var graph_editor : GraphEditor = null

var file_dialog : FileDialog = null

# Properties
var disabled : bool = true setget set_disabled

func initialize_view():
	rect_min_size = Vector2(256, 256)
	
	# Main VBox container
	var vbox_container = VBoxContainer.new()
	
	# Header
	var hbox_container = HBoxContainer.new()
	
	# Create State machine graph menu button
	header_button_graph = MenuButton.new()
	header_button_graph.text = "Graph"
	header_button_graph.disabled = disabled
	
	var popup = header_button_graph.get_popup()
	popup.add_icon_item(theme.get_icon("New", "EditorIcons"), "Create new", CREATE_NEW)
	popup.add_separator()
	popup.add_icon_item(theme.get_icon("Load", "EditorIcons"), "Open", OPEN)
	popup.add_icon_item(theme.get_icon("Save", "EditorIcons"), "Save As", SAVE_AS)
	popup.add_separator()
	popup.add_icon_item(theme.get_icon("Duplicate", "EditorIcons"), "Make unique", MAKE_UNIQUE)
	
	popup.connect("id_pressed", self, "on_header_button_graph_id_pressed")
	
	hbox_container.add_child(header_button_graph)
	
	# Spacer
	hbox_container.add_spacer(false)
	
	# Snapping controls
	snap_toggle = Button.new()
	snap_toggle.flat = true
	snap_toggle.add_stylebox_override("focus", StyleBoxEmpty.new())
	snap_toggle.icon = theme.get_icon("SnapGrid", "EditorIcons")
	snap_toggle.toggle_mode = true
	snap_toggle.disabled = disabled
	
	snap_toggle.connect("toggled", self, "on_snaping_toggled")
	
	hbox_container.add_child(snap_toggle)
	
	# End of header
	vbox_container.add_child(hbox_container)
	
	# Graph Editor
	graph_editor = GraphEditor.new(theme)
	
	graph_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# End of graph editor
	vbox_container.add_child(graph_editor)
	
	add_child(vbox_container)
	
	vbox_container.set_anchors_preset(Control.PRESET_WIDE)
	
	# File dialog
	file_dialog = FileDialog.new()
	
	file_dialog.connect("file_selected", self, "on_file_dialog_file_selected")
	
	add_child(file_dialog)
	
func set_disabled(p_disabled : bool):
	if p_disabled == disabled:
		return
	
	disabled = p_disabled
	
	header_button_graph.disabled = disabled
	snap_toggle.disabled = disabled
	graph_editor.disabled = disabled
	
func on_header_button_graph_id_pressed(p_id : int):
	pass
	
func on_file_dialog_file_selected(p_path):
	pass