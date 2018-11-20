tool
extends Resource

const State = preload("State.gd")
const Transition = preload("Transition.gd")

export(Vector2) var entry_node_offset = Vector2()

export(int) var start_state_id = -1

export(Array) var states = []
export(Array) var transitions = []

func set_state_as_default(p_state : State):
	if !states.has(p_state):
		start_state_id = -1
		return
	
	if p_state == null:
		start_state_id = -1
		return
	
	for i in states.size():
		if p_state == states[i]:
			start_state_id = i
			break

func add_state(p_position : Vector2, p_script : GDScript) -> State:
	var new_state = State.new().duplicate() as State
	
	new_state.offset = p_position

	if p_script != null:
		new_state.state_script = p_script

		# Filename as state name
		var extension = p_script.resource_path.get_extension()
		var file_name = p_script.resource_path.get_file()
		new_state.label = file_name.rstrip(".%s" % [extension])
		
	states.push_back(new_state)
	
	return new_state
	
func duplicate_state(p_state : State, p_position : Vector2) -> State:
	var new_state = State.new().duplicate() as State
	
	new_state.offset = p_position
	new_state.state_script = p_state.state_script
	new_state.outputs = p_state.outputs
	new_state.properties = p_state.properties.duplicate()
	
	states.push_back(new_state)
	
	return new_state
	
func remove_state(p_state : State):
	if !(p_state is State):
		return ERR_INVALID_PARAMETER
		
	if !(p_state in states):
		return ERR_DOES_NOT_EXIST
		
	# Find index
	var previous_index = -1
		
	for i in states.size():
		if p_state == states[i]:
			previous_index = i
			break
			
	if previous_index == -1:
		return ERR_BUG
		
	states.erase(p_state)
	
	# Update start state id
	if start_state_id > previous_index:
		start_state_id = max(-1, start_state_id - 1)
	
	return OK
	
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
		
	var transition : Transition = Transition.new()
	
	transition.from_state = p_from_state
	transition.from_slot_index = p_from_slot_index
	transition.to_state = p_to_state
	transition.to_slot_index = p_to_slot_index
	
	transitions.push_back(transition)
	
	return transition
	
func remove_transition(p_from_state : State, p_from_slot_index : int, p_to_state : State, p_to_slot_index : int):
	var transition = get_transition(p_from_state, p_from_slot_index, p_to_state, p_to_slot_index)
	
	if transition == null:
		return ERR_DOES_NOT_EXIST
		
	transitions.erase(transition)
	
	return OK
	
func reassign_transition(p_transition, p_from_slot_index : int, p_to_slot_index : int):
	if !transitions.has(p_transition):
		return ERR_DOES_NOT_EXIST
		
	p_transition.from_slot_index = p_from_slot_index
	p_transition.to_slot_index = p_to_slot_index
	
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
	
func update_reroute_points(p_transition : Transition, p_reroute_points : PoolVector2Array):
	p_transition.reroute_points = p_reroute_points