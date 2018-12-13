tool
extends Resource

export(String) var name = "New State" setget set_name
export(GDScript) var state_script = null setget set_state_script
export(PoolStringArray) var outputs = PoolStringArray() setget set_outputs

var property_cache = []

var _graph_state_scripts : Array

# Signals
signal renamed
signal state_script_changed
signal outputs_changed
signal property_cache_changed

func set_name(p_name : String):
	name = p_name
	
	emit_signal("renamed")

func set_state_script(p_script : GDScript):
	if p_script != null:
		for graph_state_script in _graph_state_scripts:
			if graph_state_script == p_script:
				return
	
	state_script = p_script
	
	update_property_cache()
	
	emit_signal("state_script_changed")
	
func set_outputs(p_outputs : PoolStringArray):
	outputs = p_outputs
	
	emit_signal("outputs_changed")
	
func set_graph_state_scripts_list(p_array : Array):
	_graph_state_scripts = p_array
	
func update_property_cache():
	property_cache.clear()
	
	if state_script == null:
		emit_signal("property_cache_changed")
		return
		
	var instance = state_script.new()
	
	for property in instance.get_property_list():
		if property.usage & PROPERTY_USAGE_DEFAULT && property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			property_cache.push_back({
				"name" : property.name,
				"type" : property.type,
				"hint" : property.hint,
				"hint_string" : property.hint_string,
				"default_value" : instance.get(property.name)
			})

	# Clean up
	instance.queue_free()
	
	emit_signal("property_cache_changed")
	