tool
extends "Views/GraphEditorNodeView.gd"

# Slot constants
const Slot = preload("GraphEditorNodeSlot.gd")

# Properties
var title : String = "Node" setget set_title
var is_selected : bool = false setget set_is_selected
var offset : Vector2 = Vector2() setget set_offset
var display_scale : float = 1
var snap_distance : int = -1 setget set_snap_distance

# Flags
var pressed = false

# Signals
signal selected
signal deselected

signal left_clicked
signal right_clicked
signal doubleclicked

signal offset_changed
signal drag_request(p_relative)

signal socket_drag_started(p_node, p_slot_index)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				BUTTON_LEFT:
					pressed = true
					
					emit_signal("left_clicked")
						
				BUTTON_RIGHT:
					emit_signal("right_clicked")
					
		if event.doubleclick:
			match event.button_index:
				BUTTON_LEFT:
					emit_signal("doubleclicked")
		
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			pass
			
		else:
			match event.button_index:
				BUTTON_LEFT:
					if pressed:
						pressed = false
						
					if snap_distance > -1:
						apply_snapped_offset()
		
	elif event is InputEventMouseMotion:
		if pressed && is_selected:
			emit_signal("drag_request", event.relative / display_scale)
	
func update_size():
	rect_size = Vector2()
	
func set_title(p_title : String):
	title = p_title
	
	if title_label == null:
		return
		
	title_label.text = title
	
func set_is_selected(p_is_selected : bool):
	is_selected = p_is_selected
	
	if is_selected:
		raise()
		focus_panel.show()
		emit_signal("selected")
		
	else:
		focus_panel.hide()
		emit_signal("deselected")
	
func set_offset(p_offset : Vector2):
	if offset == p_offset:
		return
	
	offset = p_offset
	
	var target_position = offset * display_scale
	
	# Apply snapping if needed
	if snap_distance > -1:
		target_position = target_position.snapped(Vector2(snap_distance, snap_distance))
	
	rect_position = target_position
	
	emit_signal("offset_changed")
	
func set_snap_distance(p_snap_distance):
	snap_distance = p_snap_distance
	
	if snap_distance > -1:
		apply_snapped_offset()
	
func apply_snapped_offset():
	self.offset = offset.snapped(Vector2(snap_distance, snap_distance) / display_scale)
	
func add_slot(p_is_input : bool, p_type : int, p_color : Color, p_text : String):
	var container : Container = null
	
	if p_is_input:
		container = inputs_container
		
	else:
		container = outputs_container
		
	if container == null:
		return
		
	var slot : Slot = Slot.new(theme)
	container.add_child(slot)
	
	slot.initialize(p_is_input, p_type, p_color, p_text)
	
	slot.connect("socket_pressed", self, "on_socket_pressed")
	
	update_size()
	
func remove_slot(p_is_input : bool, p_index : int):
	var container : Container = null
	
	if p_is_input:
		container = inputs_container
		
	else:
		container = outputs_container
		
	if container == null:
		return
		
	var slot = container.get_child(p_index)
	
	if slot == null:
		return
		
	slot.free()
		
	update_size()
	
func remove_all_slots():
	remove_all_input_slots()
	remove_all_output_slots()
	
func get_slot_count(p_is_input : bool):
	var container : Container = null
	
	if p_is_input:
		container = inputs_container
		
	else:
		container = outputs_container
		
	if container == null:
		return 0
		
	return container.get_child_count()
	
func get_input_slot_count():
	return get_slot_count(true)
	
func get_output_slot_count():
	return get_slot_count(false)
	
func get_slot_index_from_position(p_is_input : bool, p_position : Vector2):
	var slots = []
	
	if p_is_input:
		slots = get_input_slots()
		
	else:
		slots = get_output_slots()
		
	for i in slots.size():
		var socket_position = get_socket_position(p_is_input, i)

		if socket_position == p_position:
			return i
	
	return -1
	
func get_slot(p_is_input : bool, p_index : int):
	var container : Container = null
	
	if p_is_input:
		container = inputs_container
		
	else:
		container = outputs_container
		
	if container == null:
		return null
		
	return container.get_child(p_index)
	
func get_slot_type(p_is_input : bool, p_index : int):
	var container : Container = null
		
	if p_is_input:
		container = inputs_container
		
	else:
		container = outputs_container
		
	if container == null:
		return -1
		
	var slot : Slot = get_slot(p_is_input, p_index)
	
	if slot == null:
		return -1
		
	return slot.socket_type
	
func get_input_slot(p_index):
	return get_slot(true, p_index)
	
func get_input_slots():
	return inputs_container.get_children()
	
func get_output_slot(p_index):
	return get_slot(false, p_index)
	
func get_output_slots():
	return outputs_container.get_children()
	
func get_socket_position(p_is_input : bool, p_index : int):
	var slot : Slot = get_slot(p_is_input, p_index)
	
	if slot == null:
		return null
		
	var socket = slot.socket
	
	return rect_position + socket.rect_global_position - rect_global_position + socket.rect_size/2
	
# Input slots
func add_input_slot(p_type : int, p_color : Color, p_text : String):
	add_slot(true, p_type, p_color, p_text)
	
func remove_input_slot(p_index : int):
	remove_slot(true, p_index)
	
func remove_all_input_slots():
	if inputs_container == null:
		return
	
	for slot in inputs_container.get_children():
		slot.free()
		
	update_size()
	
func get_input_slot_socket_position(p_index : int):
	return get_socket_position(true, p_index)
	
func get_input_slot_type(p_index : int):
	return get_slot_type(true, p_index)
	
# Output slots
func add_output_slot(p_type : int, p_color : Color, p_text : String):
	add_slot(false, p_type, p_color, p_text)
	
func remove_output_slot(p_index : int):
	remove_slot(false, p_index)
	
func remove_all_output_slots():
	if outputs_container == null:
		return
	
	for slot in outputs_container.get_children():
		slot.free()
		
	update_size()
	
func get_output_slot_socket_position(p_index : int):
	return get_socket_position(false, p_index)
	
func get_output_slot_type(p_index : int):
	return get_slot_type(false, p_index)
	
func on_socket_pressed(p_is_input, p_slot_index):
	var socket_position = get_socket_position(p_is_input, p_slot_index)
	var slot_type = get_slot(p_is_input, p_slot_index).socket_type
	
	if socket_position == null:
		return
	
	emit_signal("socket_drag_started", self, p_is_input, p_slot_index)
