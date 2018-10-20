tool
extends "GraphEditorNode.gd"

const StateMachineGraph = preload("../Resources/StateMachineGraph.gd")

var graph : StateMachineGraph = null

func _init(p_theme : Theme):
	theme = p_theme
	initialize_view()

func initialize(p_graph : StateMachineGraph):
	graph = p_graph
	
	# Apply properties
	display_scale = theme.get_constant("scale", "Editor")
	self.offset = graph.entry_node_offset
	self.title = "Entry"
	
	# Create output slot
	add_output_slot(0, Color.yellowgreen, "OnStart")
	
	# Connect signals
	connect("offset_changed", self, "on_offset_changed")
	
func on_offset_changed():
	graph.entry_node_offset = offset
	
	graph.property_list_changed_notify()