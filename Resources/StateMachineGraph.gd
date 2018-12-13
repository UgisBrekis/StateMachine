tool
extends Resource

const Superstate = preload("SuperState.gd")
const State = preload("State.gd")
const Transition = preload("Transition.gd")

var entry_node_offset : Vector2

var _default_state : State
var _default_transition_reroute_points : PoolVector2Array

export(Array) var superstates = []
export(Array) var states = []
export(Array) var transitions = []
	
func get_default_state() -> State:
	return _default_state

func set_default_state(p_state : State):
	if p_state == null:
		_default_state = null
		_default_transition_reroute_points.resize(0)
		
		property_list_changed_notify()
		return
	
	if !states.has(p_state):
		return
	
	_default_state = p_state
	_default_transition_reroute_points.resize(0)
	
	property_list_changed_notify()
	
func add_superstate(p_state_script : GDScript, p_outputs : PoolStringArray = PoolStringArray()) -> Superstate:
	var superstate_resource = Superstate.new()
	var superstate = superstate_resource.duplicate() as Superstate
	
	superstate.state_script = p_state_script
	superstate.outputs = p_outputs
	
	superstates.push_back(superstate)
	
	update_superstates()
	
	property_list_changed_notify()
	
	return superstate
	
func add_state(p_superstate : Superstate, p_offset : Vector2, p_properties : Dictionary) -> State:
	var state_resource = State.new()
	var state = state_resource.duplicate() as State
	
	state.superstate = p_superstate
	state.offset = p_offset
	state.properties = p_properties
	
	state.on_property_cache_changed()

	states.push_back(state)
	
	property_list_changed_notify()
	
	return state
	
func duplicate_state(p_state : State, p_offset : Vector2) -> State:
	var state : State = add_state(p_state.superstate, p_offset, p_state.properties.duplicate())
	
	property_list_changed_notify()
	
	return state
	
func remove_state(p_state : State):
	if !states.has(p_state):
		return ERR_DOES_NOT_EXIST
	
	if _default_state == p_state:
		set_default_state(null)
	
	states.erase(p_state)
	
	if _is_superstate_redundant(p_state.superstate):
		superstates.erase(p_state.superstate)
		
		update_superstates()
		
	property_list_changed_notify()
	
func get_state(p_index : int):
	if states.size() == 0:
		return null
	
	if p_index < 0 || p_index > states.size() - 1:
		return null
		
	return states[p_index]
	
func add_transition(p_from_state : State, p_from_slot_index : int, p_to_state : State, p_to_slot_index : int):
	if p_from_state == p_to_state:
		return null
		
	if !states.has(p_from_state) || !states.has(p_to_state) :
		return null
	
	var transition_resource = Transition.new()
	var transition = transition_resource.duplicate() as Transition
	
	transition.from_state = p_from_state
	transition.from_slot_index = p_from_slot_index
	transition.to_state = p_to_state
	transition.to_slot_index = p_to_slot_index
	
	transitions.push_back(transition)
	
	property_list_changed_notify()
	
	return transition
	
func remove_transition(p_from_state : State, p_from_slot_index : int, p_to_state : State, p_to_slot_index : int):
	var transition = get_transition(p_from_state, p_from_slot_index, p_to_state, p_to_slot_index)
	
	if transition == null:
		return ERR_DOES_NOT_EXIST
		
	transitions.erase(transition)
	
	property_list_changed_notify()
	
	return OK

func get_transition(p_from_state : State, p_from_slot_index : int, p_to_state : State, p_to_slot_index : int):
	for transition in transitions:
		transition = transition as Transition
		if transition.from_state != p_from_state || transition.to_state != p_to_state:
			continue
			
		if transition.from_slot_index == p_from_slot_index && transition.to_slot_index == p_to_slot_index:
			return transition
	
	return null
	
func get_attached_connections(p_state : State):
	var connections = []
	
	for transition in transitions:
		transition = transition as Transition
		
		if transition.from_state == p_state || transition.to_state == p_state:
			connections.push_back(transition)
			
	return connections
	
func get_outgoing_connections(p_from_state : State, p_from_slot_index : int):
	var connections = []
	
	for transition in transitions:
		transition = transition as Transition
		
		if transition.from_state == p_from_state && transition.from_slot_index == p_from_slot_index:
			connections.push_back(transition)
			
	return connections
	
func get_incomming_connections(p_to_state : State, p_to_slot_index : int):
	var connections = []
	
	for transition in transitions:
		transition = transition as Transition
		
		if transition.to_state == p_to_state && transition.to_slot_index == p_to_slot_index:
			connections.push_back(transition)
			
	return connections
	
func get_state_script_list() -> Array:
	var state_script_list : Array = []
	
	for superstate in superstates:
		superstate = superstate as Superstate
		
		if superstate.state_script == null:
			continue
			
		state_script_list.push_back(superstate.state_script)
	
	return state_script_list
	
func update_reroute_points(p_transition : Transition, p_reroute_points : PoolVector2Array):
	p_transition.reroute_points = p_reroute_points
	
	property_list_changed_notify()
	
func update_superstates():
	var state_script_list : Array = get_state_script_list()
	
	for superstate in superstates:
		superstate = superstate as Superstate
		
		superstate.set_graph_state_scripts_list(state_script_list)
		
func _is_superstate_redundant(p_superstate : Superstate) -> bool:
	for state in states:
		state = state as State
		
		if state.superstate == p_superstate:
			return false
		
	return true
	
func _get_property_list():
	var property_list = []
	
	property_list.push_back({
		"name" : "entry_node_offset",
		"type" : TYPE_VECTOR2,
		"usage" : PROPERTY_USAGE_STORAGE
	})
	
	property_list.push_back({
		"name" : "_default_state",
		"type" : TYPE_OBJECT,
		"usage" : PROPERTY_USAGE_STORAGE
	})
	
	property_list.push_back({
		"name" : "_default_transition_reroute_points",
		"type" : TYPE_VECTOR2_ARRAY,
		"usage" : PROPERTY_USAGE_STORAGE
	})
	
	return property_list