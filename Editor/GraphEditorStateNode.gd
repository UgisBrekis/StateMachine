tool
extends "GraphEditorNode.gd"

const State = preload("../Resources/State.gd")
const StateBase = preload("../Scripts/StateBase.gd")

var state : State = null

# Signals
signal outputs_updated

func _init(p_theme : Theme):
	theme = p_theme
	initialize_view()

func initialize(p_state : State):
	state = p_state

	# Apply properties
	display_scale = theme.get_constant("scale", "Editor")
	self.offset = state.offset
	self.title = state.name

	# Create input slot
	add_input_slot(1, Color.white, "Start")

	# Add output slots
	update_outputs()

	# Connect signals
	connect("offset_changed", self, "on_offset_changed")

	state.connect("renamed", self, "on_state_renamed")
	state.connect("state_script_changed", self, "on_state_script_changed")

func dispose():
	print("Remove this graph editor node")

func on_offset_changed():
	if state == null:
		return

	state.offset = offset

	state.property_list_changed_notify()

func on_state_renamed():
	if state == null:
		return

	self.title = state.name

func on_state_script_changed():
	if state == null:
		return

	update_outputs()

func update_outputs():
	remove_all_output_slots()

	if state.state_script == null:
		emit_signal("outputs_updated")
		return
	
	var instance = state.state_script.new()
	var instance_property_list = []
	
	for property in instance.get_property_list():
		if property.usage & PROPERTY_USAGE_DEFAULT && property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			instance_property_list.push_back(property.duplicate())
	
	# Update
	for instance_property in instance_property_list:
		var property_index = -1

		for i in state.properties.size():
			if state.properties[i].name == instance_property.name:
				property_index = i

		if property_index == -1:
			# Create property
			instance_property["value"] = null

		else:
			# Update property
			if state.properties[property_index].type != instance_property.type:
				instance_property["value"] = instance.get(instance_property.name)

			else:
				instance_property["value"] = state.properties[property_index].value

	state.properties = instance_property_list

	if "transitions" in instance:
		if typeof(instance.transitions) != TYPE_DICTIONARY:
			return

		for key in instance.transitions:
			add_output_slot(2, Color.coral, key)

	# Clean up
	instance.queue_free()

	property_list_changed_notify()
	emit_signal("outputs_updated")
