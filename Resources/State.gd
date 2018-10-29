tool
extends Resource

export(String) var name = "New state" setget set_state_name
export(GDScript) var state_script = null setget set_state_script

var offset = Vector2()
var properties = {}

var property_cache = []

# Signals
signal renamed
signal state_script_changed

func _get(property):
	match property:
		"offset":
			return offset
			
		"properties":
			return properties
	
func _set(property, value):
	match property:
		"offset":
			offset = value
			return true
			
		"properties":
			properties = value
			return true
	
func _get_property_list():
	var property_list = []
	
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

func set_state_name(p_name):
	name = p_name
	
	emit_signal("renamed")

func set_state_script(p_script):
	state_script = p_script
	
	emit_signal("state_script_changed")
	