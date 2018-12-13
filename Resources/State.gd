tool
extends Resource

const SuperState = preload("SuperState.gd")

var superstate : SuperState setget set_superstate, get_superstate
var offset : Vector2 setget set_offset, get_offset
var properties : Dictionary = {} setget set_properties, get_properties

func set_superstate(p_superstate : SuperState):
	superstate = p_superstate
	
	if superstate == null:
		return
	
	superstate.connect("property_cache_changed", self, "on_property_cache_changed")
	
func get_superstate() -> SuperState:
	return superstate
	
func set_offset(p_offset : Vector2):
	offset = p_offset
	
func get_offset() -> Vector2:
	return offset
	
func set_properties(p_properties : Dictionary):
	properties = p_properties
	
func get_properties() -> Dictionary:
	return properties
	
func on_property_cache_changed():
	_update_properties_from_cache(superstate.property_cache)
	
func _update_properties_from_cache(p_property_cache : Array):	
	var redundant_keys : PoolStringArray = PoolStringArray()
	
	# Collect redundant keys and erase them
	for key in properties.keys():
		var is_redundant : bool = true
		
		for cached_item in p_property_cache:
			if key == cached_item.name:
				is_redundant = false
				
				break
				
		if is_redundant:
			redundant_keys.push_back(key)
	
	for key in redundant_keys:
		properties.erase(key)
	
	# Apply default values
	for cached_item in p_property_cache:
		if !(properties.has(cached_item.name)):
			properties[cached_item.name] = cached_item.default_value
			
		else:
			if typeof(properties[cached_item.name]) != cached_item.type:
				properties[cached_item.name] = cached_item.default_value

func _get_property_list():
	var property_list = []
	
	property_list.push_back({
		"name" : "superstate",
		"type" : TYPE_OBJECT,
		"usage" : PROPERTY_USAGE_STORAGE
	})
	
	property_list.push_back({
		"name" : "offset",
		"type" : TYPE_VECTOR2,
		"usage" : PROPERTY_USAGE_STORAGE
	})
	
	property_list.push_back({
		"name" : "properties",
		"type" : TYPE_DICTIONARY,
		"usage" : PROPERTY_USAGE_STORAGE
	})
	
	return property_list
