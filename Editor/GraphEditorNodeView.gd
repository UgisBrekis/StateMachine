tool
extends PanelContainer

var content_container : VBoxContainer = null

var header_panel : PanelContainer = null
var title_label : Label = null
var warning_button : Button = null

var inputs_container : VBoxContainer = null
var outputs_container : VBoxContainer = null

var focus_panel : Panel = null
	
func initialize_view():
	add_stylebox_override("panel", theme.get_stylebox("state_node", "Editor"))
	
	content_container = VBoxContainer.new()
	content_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Header panel
	header_panel = PanelContainer.new()
	header_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	header_panel.add_stylebox_override("panel", theme.get_stylebox("state_node_header", "Editor"))
	
	var header_hbox = HBoxContainer.new()
	
	# Title label
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Warning icon
	warning_button = Button.new()
	warning_button.flat = true
	warning_button.add_stylebox_override("focus", StyleBoxEmpty.new())
	warning_button.icon = theme.get_icon("NodeWarning", "EditorIcons")
	
	header_hbox.add_child(title_label)
	header_hbox.add_child(warning_button)
	
	header_panel.add_child(header_hbox)
	
	content_container.add_child(header_panel)
	
	# Body
	var margin_container = MarginContainer.new()
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	margin_container.add_constant_override("margin_left", theme.get_constant("state_node_content_margin_left", "Editor"))
	margin_container.add_constant_override("margin_top", theme.get_constant("state_node_content_margin_top", "Editor"))
	margin_container.add_constant_override("margin_right", theme.get_constant("state_node_content_margin_right", "Editor"))
	margin_container.add_constant_override("margin_bottom", theme.get_constant("state_node_content_margin_bottom", "Editor"))
	
	var slots_container = HBoxContainer.new()
	slots_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	slots_container.add_constant_override("separation", theme.get_constant("state_node_slot_separation", "Editor"))
	
	# Inputs
	inputs_container = VBoxContainer.new()
	inputs_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inputs_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	slots_container.add_child(inputs_container)
	
	# Ouputs
	outputs_container = VBoxContainer.new()
	outputs_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outputs_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	slots_container.add_child(outputs_container)
	
	margin_container.add_child(slots_container)
	
	content_container.add_child(margin_container)
	
	add_child(content_container)
	
	# Focus panel
	focus_panel = Panel.new()
	focus_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_panel.hide()
	
	focus_panel.add_stylebox_override("panel", theme.get_stylebox("state_node_focus", "Editor"))
	
	add_child(focus_panel)
