tool
extends Node
class_name StateMachine

const Graph = preload("Resources/StateMachineGraph.gd")

export(bool) var autostart = true

var graph : Graph = null

var active_state : Graph.State = null
var active_state_instance : StateBase = null

# Signals
signal started
signal stopped
signal state_changed

func _set(property, value):
	if property == "graph":
		graph = value
		return true
		
	if Engine.editor_hint:
		if active_state != null:
			for cached_item in active_state.superstate.property_cache:
				if property == "Selected state/%s" % [cached_item.name]:
					active_state.properties[cached_item.name] = value
					
					graph.property_list_changed_notify()
					return true
	
func _get(property):
	if property == "graph":
		return graph
	
	if Engine.editor_hint:
		if active_state != null:
			for cached_item in active_state.superstate.property_cache:
				if property == "Selected state/%s" % [cached_item.name]:
					return active_state.properties[cached_item.name]
	
func _get_property_list():
	var property_list = []
	
	if !Engine.editor_hint:
		return property_list
	
	if graph == null:
		return property_list
		
	property_list = [{
		"name" : "graph",
		"type" : TYPE_OBJECT,
		"usage" : PROPERTY_USAGE_STORAGE
	}]
	
	if active_state == null:
		return property_list
		
	for cached_item in active_state.superstate.property_cache:
		var property = {
			"name" : "Selected state/%s" % [cached_item.name],
			"type" : cached_item.type,
			"hint" : cached_item.hint,
			"hint_string" : cached_item.hint_string,
			"usage" : PROPERTY_USAGE_EDITOR
		}
		
		property_list.push_back(property)
	
	return property_list

func _ready():
	if Engine.editor_hint:
		return
	
	if autostart:
		start()

func start(p_args = []):
	if graph == null:
		return
		
	var default_state : Graph.State = graph.get_default_state()
		
	if default_state == null:
		return
		
	instantiate_next_state(default_state, p_args)
	
	emit_signal("started")
	
func stop():
	if active_state_instance != null:
		active_state_instance.disconnect("transition_requested", self, "on_transition_requested")
		active_state_instance.on_stop()
		active_state_instance.queue_free()
		
		active_state_instance = null
	
	active_state = null
	
	emit_signal("stopped")
	
func on_transition_requested(p_output, p_args : Array = []):
	# Can only transition if there is active state
	if active_state == null:
		stop()
		return
	
	# Find output index
	var output_index = -1
	
	match typeof(p_output):
		TYPE_INT:
			if p_output in range(active_state.superstate.outputs.size()):
				output_index = p_output
				
		TYPE_STRING:
			for i in active_state.superstate.outputs.size():
				if p_output == active_state.superstate.outputs[i]:
					output_index = i
			
					break
		
	if output_index == -1:
		print("State machine :: Output[ %s ] does not exist" % [p_output])
		stop()
		return
	
	# Stop current active state
	active_state_instance.disconnect("transition_requested", self, "on_transition_requested")
	active_state_instance.on_stop()
	active_state_instance.queue_free()
	
	# Find next state index
	for transition in graph.transitions:
		transition = transition as Graph.Transition
		
		if transition.from_state == active_state && transition.from_slot_index == output_index:
			# Transition found, try to instantiate next state
			instantiate_next_state(transition.to_state, p_args)
			return
		
	# Transition does not exist
	print("State machine couldn't perform a transition")
	stop()
	
func instantiate_next_state(p_state : Graph.State, p_args : Array = []):
	# Check if the script is attached to the next state
	if p_state.superstate.state_script == null:
		stop()
		return
		
	active_state = p_state
	
	active_state_instance = active_state.superstate.state_script.new()
	
	add_child(active_state_instance)
		
	# Apply properties
	active_state_instance.owner = get_parent()
		
	for key in active_state.properties.keys():
		var value = active_state.properties[key]
		
		# Resolve NodePaths
		if typeof(value) == TYPE_NODE_PATH:
			var path : String = str(value)
			
			path = path.insert(0, "../")
			
			value = NodePath(path)
		
		active_state_instance.set(key, value)
		
	active_state_instance.connect("transition_requested", self, "on_transition_requested")
	
	active_state_instance.on_start(p_args)
	
	emit_signal("state_changed")
	
	