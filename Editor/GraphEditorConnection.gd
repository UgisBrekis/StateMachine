tool
extends "GraphEditorConnectionBase.gd"

const GraphEditorNode = preload("GraphEditorNode.gd")

var from_node : GraphEditorNode = null
var to_node : GraphEditorNode = null

var from_slot_index : int = -1
var to_slot_index : int = -1

var from_slot_text : String
var to_slot_text : String

func initialize(p_width : float, p_display_scale : float, p_curvature : float, p_from : GraphEditorNode, p_from_slot : int, p_to : GraphEditorNode, p_to_slot : int, p_reroute_points : PoolVector2Array):
	create_texture()
	width = p_width
	display_scale = p_display_scale
	curvature = p_curvature
	
	from_node = p_from
	to_node = p_to
	
	from_slot_index = p_from_slot
	to_slot_index = p_to_slot
	
	from_slot_text = from_node.get_output_slot(from_slot_index).text
	to_slot_text = to_node.get_input_slot(to_slot_index).text
	
	reroute_points = p_reroute_points
	
	for i in reroute_points.size():
		var rerouter = Rerouter.new(p_width, reroute_default_texture, reroute_highlight_texture, p_display_scale, reroute_points[i])
		add_child(rerouter)
		
		rerouter.connect("offset_changed", self, "on_rerouter_offset_changed")
		rerouter.connect("remove_requested", self, "on_rerouter_remove_requested")
	
	call_deferred("update_positions")
	
	from_node.connect("offset_changed", self, "on_from_node_offset_changed")
	from_node.connect("resized", self, "on_from_node_resized")
	
	to_node.connect("offset_changed", self, "on_to_node_offset_changed")
	to_node.connect("resized", self, "on_to_node_resized")
		
func on_from_node_resized():
	call_deferred("update_from_position")
	
func on_to_node_resized():
	call_deferred("update_to_position")
	
func on_from_node_offset_changed():
	update_from_position()
	
func on_to_node_offset_changed():
	update_to_position()
	
func update_positions():
	update_from_position()
	update_to_position()
	
func update_from_position():
	if from_node == null || from_slot_index == -1:
		queue_free()
		return
	
	self.from_position = from_node.get_output_slot_socket_position(from_slot_index)
	
func update_to_position():
	if to_node == null || to_slot_index == -1:
		queue_free()
		return
	
	self.to_position = to_node.get_input_slot_socket_position(to_slot_index)
	
