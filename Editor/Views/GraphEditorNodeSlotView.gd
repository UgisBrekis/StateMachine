tool
extends PanelContainer

var container : HBoxContainer = null
var socket : TextureRect = null
var label : Label = null

func initialize_view():
	container = HBoxContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Socket
	socket = TextureRect.new()
	socket.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	socket.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	socket.texture = theme.get_icon("state_machine_editor_socket", "EditorIcons")
	
	container.add_child(socket)
	
	# Label
	label = Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	container.add_child(label)
	
	add_child(container)
	
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_stylebox_override("panel", theme.get_stylebox("state_node_slot", "Editor"))