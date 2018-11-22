tool
extends Resource

const State = preload("State.gd")

var from_state : State = null
var to_state : State = null

var from_slot_index : int = -1
var to_slot_index : int = -1

var reroute_points : PoolVector2Array = PoolVector2Array()

func _get(property):
	if property == "from_state":
		return from_state
		
	elif property == "to_state":
		return to_state
		
	elif property == "from_slot_index":
		return from_slot_index
		
	elif property == "to_slot_index":
		return to_slot_index
		
	elif property == "reroute_points":
		return reroute_points
		
func _set(property, value):
	if property == "from_state":
		from_state = value
		return true
		
	elif property == "to_state":
		to_state = value
		return true
		
	elif property == "from_slot_index":
		from_slot_index = value
		return true
		
	elif property == "to_slot_index":
		to_slot_index = value
		return true
		
	elif property == "reroute_points":
		reroute_points = value
		return true
		
	return false
	
func _get_property_list():
	var property_list = []
	
	property_list.push_back({
		"name" : "from_state",
		"type" : TYPE_OBJECT,
		"usage" : PROPERTY_USAGE_STORAGE
	})
	
	property_list.push_back({
		"name" : "from_slot_index",
		"type" : TYPE_INT,
		"usage" : PROPERTY_USAGE_STORAGE
	})
	
	property_list.push_back({
		"name" : "to_state",
		"type" : TYPE_OBJECT,
		"usage" : PROPERTY_USAGE_STORAGE
	})
	
	property_list.push_back({
		"name" : "to_slot_index",
		"type" : TYPE_INT,
		"usage" : PROPERTY_USAGE_STORAGE
	})
	
	property_list.push_back({
		"name" : "reroute_points",
		"type" : TYPE_VECTOR2_ARRAY,
		"usage" : PROPERTY_USAGE_STORAGE
	})
	
	return property_list