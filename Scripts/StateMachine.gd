tool
extends Node
class_name StateMachine

const StateMachineGraph = preload("../Resources/StateMachineGraph.gd")

export(bool) var autostart = true

var _active_state_id : int = -1
var _active_state : StateBase = null

var active_state : StateBase = null setget , get_active_state

var graph = null

# Signals
signal started
signal stopped
signal state_changed

func _set(property, value):
	if property == "graph":
		graph = value
		return true
		
	if graph != null:
		if graph.selected_state != null:
			for i in graph.selected_state.properties.size():
				if property == "State properties/%s" % [graph.selected_state.properties[i].name]:
					graph.selected_state.properties[i].value = value
					return true
	
func _get(property):
	if property == "graph":
		return graph
	
	if graph != null:
		if graph.selected_state != null:
			for i in graph.selected_state.properties.size():
				if property == "State properties/%s" % [graph.selected_state.properties[i].name]:
					return graph.selected_state.properties[i].value
	
func _get_property_list():
	var property_list = []
	
	if graph == null:
		return property_list
		
	property_list = [{
		"name" : "graph",
		"type" : TYPE_OBJECT,
		"usage" : PROPERTY_USAGE_STORAGE
	}]
	
	if graph.selected_state == null:
		return property_list
		
	for i in graph.selected_state.properties.size():
		var property = {}
		
		for key in graph.selected_state.properties[i].keys():
			if key == "name":
				property.name = "State properties/%s" % [graph.selected_state.properties[i].name]
				continue
				
			if key == "usage":
				property.usage = PROPERTY_USAGE_EDITOR
				
			property[key] = graph.selected_state.properties[i][key]
		
		property_list.push_back(property)
	
	return property_list

func _ready():
	if Engine.editor_hint:
		return
	
	if autostart:
		start()

func get_active_state():
	return _active_state
	
func start(p_args = []):
	if graph == null:
		return
		
	if graph.start_state_id == -1:
		return
		
	instantiate_next_state(graph.start_state_id, p_args)
	
	emit_signal("started")
	
func stop():
	emit_signal("stopped")
	
func on_transition_requested(p_index, p_args = []):
	# Can only transition if there is active state
	if _active_state == null:
		return
	
	# Stop current active state
	_active_state.disconnect("transition_requested", self, "on_transition_requested")
	_active_state.on_stop()
	_active_state.queue_free()
	
	# Find next state index
	for transition in graph.transitions:
		if transition.from_state_index != _active_state_id:
			continue
			
		if transition.from_slot_index != p_index:
			continue
			
		# Transition found, try to instantiate next state
		instantiate_next_state(transition.to_state_index, p_args)
		
		return
		
	# Transition does not exist
	stop()
	
func instantiate_next_state(p_index, p_args = []):
	# TO-DO -> validation
	
	# Assign active state id
	_active_state_id = p_index
	
	# Check if the script is attached to the next state
	var next_state = graph.states[_active_state_id]
	
	if next_state.state_script == null:
		_active_state_id = -1
		stop()
		return
		
	_active_state = next_state.state_script.new()
	
	add_child(_active_state)
		
	# Apply properties
	_active_state.owner = get_parent()
		
	for property in graph.states[_active_state_id].properties:
		_active_state.set(property.name, property.value)
		
	_active_state.connect("transition_requested", self, "on_transition_requested")
	
	_active_state.on_start(p_args)
	
	