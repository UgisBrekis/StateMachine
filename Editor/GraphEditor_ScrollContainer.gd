tool
extends "Views/ScrollContainerView.gd"

signal left_click_down
signal right_click_down
signal state_scripts_dropped(p_state_scripts)

func _init(p_theme : Theme):
	initialize_view(p_theme)
	
func can_drop_data(position, data):
	if typeof(data) == TYPE_DICTIONARY && data.has("files"):
		return true
		
	return false
	
func drop_data(position, data):
	var state_scripts = []
	
	for path in data.files:
		var file = load(path)
		
		if !(file is GDScript):
			continue
			
		if file.get_base_script() != StateBase:
			continue
			
		state_scripts.push_back(file)
		
	if state_scripts.size() == 0:
		return
		
	emit_signal("state_scripts_dropped", state_scripts)
	
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				BUTTON_LEFT:
					emit_signal("left_click_down")
				
				BUTTON_RIGHT:
					emit_signal("right_click_down")
	
	
