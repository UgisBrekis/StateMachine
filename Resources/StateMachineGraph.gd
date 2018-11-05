tool
extends Resource

const State = preload("State.gd")
const Transition = preload("Transition.gd")

export(Vector2) var entry_node_offset = Vector2()

export(int) var start_state_id = -1

export(Array) var states = []
export(Array) var transitions = []

var selected_state : State = null

func add_state(p_state : State):
	if !(p_state is State):
		return ERR_INVALID_PARAMETER
		
	if p_state in states:
		return ERR_ALREADY_EXISTS
		
	states.push_back(p_state)
	
	return OK
	
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
	
	# Assign updated state indexes
	for transition in transitions:
		if transition.from_state_index > previous_index:
			transition.from_state_index -= 1
			
		if transition.to_state_index > previous_index:
			transition.to_state_index -= 1
	
	return OK
	
func get_state(p_index : int):
	if states.size() == 0:
		return null
	
	if p_index < 0 || p_index > states.size() - 1:
		return null
		
	return states[p_index]
	
func add_transition(p_from_state_index : int, p_from_slot_index : int, p_to_state_index : int, p_to_slot_index : int):
	if p_from_state_index == p_to_state_index:
		return ERR_INVALID_PARAMETER
		
	if p_from_state_index < 0 || p_to_state_index < 0:
		return ERR_INVALID_PARAMETER
		
	if p_from_state_index > states.size() - 1 || p_to_state_index > states.size() - 1:
		return ERR_INVALID_PARAMETER
		
	if get_transition(p_from_state_index, p_from_slot_index, p_to_state_index, p_to_slot_index) != null:
		return ERR_ALREADY_EXISTS
		
	var transition : Transition = Transition.new()
	
	transition.from_state_index = p_from_state_index
	transition.from_slot_index = p_from_slot_index
	transition.to_state_index = p_to_state_index
	transition.to_slot_index = p_to_slot_index
	
	transitions.push_back(transition)
	property_list_changed_notify()
	
	return OK
	
func remove_transition(p_from_state_index : int, p_from_slot_index : int, p_to_state_index : int, p_to_slot_index : int):
	var transition = get_transition(p_from_state_index, p_from_slot_index, p_to_state_index, p_to_slot_index)
	if transition == null:
		return ERR_DOES_NOT_EXIST
		
	transitions.erase(transition)
	property_list_changed_notify()
	
	return OK
	
func reassign_transition(p_transition, p_from_slot_index : int, p_to_slot_index : int):
	if !transitions.has(p_transition):
		return ERR_DOES_NOT_EXIST
		
	p_transition.from_slot_index = p_from_slot_index
	p_transition.to_slot_index = p_to_slot_index
	
	return OK
	
func get_transition(p_from_state_index : int, p_from_slot_index : int, p_to_state_index : int, p_to_slot_index : int):
	for transition in transitions:
		if transition.from_state_index != p_from_state_index || transition.to_state_index != p_to_state_index:
			continue
			
		if transition.from_slot_index == p_from_slot_index && transition.to_slot_index == p_to_slot_index:
			return transition
	
	return null
	
func get_attached_connections(p_state_index : int):
	var connections = []
	
	for transition in transitions:
		if transition.from_state_index == p_state_index || transition.to_state_index == p_state_index:
			connections.push_back(transition)
			
	return connections
	
func get_outgoing_connections(p_from_state_index : int, p_from_slot_index : int):
	var connections = []
	
	for transition in transitions:
		if transition.from_state_index == p_from_state_index && transition.from_slot_index == p_from_slot_index:
			connections.push_back(transition)
			
	return connections
	
func get_incomming_connections(p_to_state_index : int, p_to_slot_index : int):
	var connections = []
	
	for transition in transitions:
		if transition.to_state_index == p_to_state_index && transition.to_slot_index == p_to_slot_index:
			connections.push_back(transition)
			
	return connections