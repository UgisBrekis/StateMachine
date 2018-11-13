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
	self.title = state.label
	
	if state.state_script == null:
		warning_button.show()
	else:
		warning_button.hide()

	# Create input slot
	add_input_slot(1, Color.white, "Start")

	# Add output slots
	update_outputs()
	update_property_cache()

	# Connect signals
	connect("offset_changed", self, "on_offset_changed")

	state.connect("renamed", self, "on_state_renamed")
	state.connect("state_script_changed", self, "on_state_script_changed")
	state.connect("outputs_changed", self, "on_state_outputs_changed")

func dispose():
	print("Remove this graph editor node")

func on_offset_changed():
	if state == null:
		return

	state.offset = offset

func on_state_renamed():
	if state == null:
		return

	self.title = state.label

func on_state_script_changed():
	if state == null:
		return
		
	if state.state_script == null:
		warning_button.show()
	else:
		warning_button.hide()

	update_property_cache()
	
func on_state_outputs_changed():
	if state == null:
		return
		
	update_outputs()
		
func update_outputs():
	remove_all_output_slots()
	
	for output in state.outputs:
		add_output_slot(2, Color.coral, output)
		
	emit_signal("outputs_updated")
	
func update_property_cache():
	if state.state_script == null:
		return
	
	var instance = state.state_script.new()
	var instance_property_list = []
	
	for property in instance.get_property_list():
		if property.usage & PROPERTY_USAGE_DEFAULT && property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			instance_property_list.push_back(property.duplicate())
			
	# Update cache
	state.property_cache = instance_property_list
	print("Cache: %s" % [state.property_cache])
	
	# Remove redundant properties
	var redundant_keys : PoolStringArray = PoolStringArray()
	
	for key in state.properties.keys():
		var is_redundant : bool = true
		
		for cached_item in state.property_cache:
			if key == cached_item.name:
				is_redundant = false
				break
				
		if is_redundant:
			redundant_keys.push_back(key)
			
	for key in redundant_keys:
		state.properties.erase(key)
	
	# Apply values?
	for cached_item in state.property_cache:
		if !state.properties.has(cached_item.name):
			state.properties[cached_item.name] = null
			
		else:
			if typeof(state.properties[cached_item.name]) != cached_item.type:
				state.properties[cached_item.name] = instance.get(cached_item.name)

	# Clean up
	instance.queue_free()
