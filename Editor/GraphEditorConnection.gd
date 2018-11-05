tool
extends "GraphEditorConnectionBase.gd"

const GraphEditorNode = preload("GraphEditorNode.gd")
const Rerouter = preload("GraphEditorRerouter.gd")

var from_node : GraphEditorNode = null
var to_node : GraphEditorNode = null

var from_slot_index : int = -1
var to_slot_index : int = -1

var from_slot_text : String
var to_slot_text : String

# Signals
signal reconnect_requested(p_transition, p_from_slot_index, p_to_slot_index)
signal remove_requested(p_transition)

func initialize(p_width : float, p_curvature : float, p_from : GraphEditorNode, p_from_slot : int, p_to : GraphEditorNode, p_to_slot : int):
	create_texture()
	width = p_width
	curvature = p_curvature
	
	from_node = p_from
	to_node = p_to
	
	from_slot_index = p_from_slot
	to_slot_index = p_to_slot
	
	from_slot_text = from_node.get_output_slot(from_slot_index).text
	to_slot_text = to_node.get_input_slot(to_slot_index).text
	
	call_deferred("update_positions")
	
	from_node.connect("offset_changed", self, "on_from_node_offset_changed")
	from_node.connect("resized", self, "on_from_node_resized")
	
	to_node.connect("offset_changed", self, "on_to_node_offset_changed")
		
func on_from_node_resized():
	call_deferred("check_validity")
		
func check_validity():
	if from_node == null:
		emit_signal("remove_requested", self)
		return
		
	var from_slot = null
	
	if from_slot_index <= from_node.get_output_slot_count() - 1:
		from_slot = from_node.get_output_slot(from_slot_index)
	
	if from_slot != null:
		if from_slot.text == from_slot_text:
			update_from_position()
			return
		
	# Check if slot with the same name is still present
	var new_from_slot_index = -1
	
	for i in from_node.get_output_slot_count():
		if from_node.get_output_slot(i).text == from_slot_text:
			new_from_slot_index = i
			break
	
	# There is no slot with the same name in the node
	if new_from_slot_index == -1:
		emit_signal("remove_requested", self)
		return
		
	# Assign new index and update position
	emit_signal("reconnect_requested", self, new_from_slot_index, to_slot_index)
	
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
	
func add_reroute_point(p_position : Vector2):
	var index = 0
	
	for i in reroute_points.size():
		if curve.get_closest_offset(p_position) < curve.get_closest_offset(reroute_points[i]):
			break
			
		index = i + 1
		
	reroute_points.insert(index, p_position)
	add_child(Rerouter.new())
	
	update_shape()
	
func remove_reroute_point(p_position : Vector2):
	pass
	
