tool
extends ScrollContainer

var grid_cell_size = 40
var grid_big_cell_color : Color = Color.black
var grid_line_thickness = 1

signal state_scripts_dropped(p_state_scripts)

func _init(p_theme : Theme):
	theme = p_theme
	
	grid_cell_size = theme.get_constant("graph_editor_grid_cell_size", "Editor")
	grid_big_cell_color = theme.get_color("dark_color_3", "Editor")
	grid_line_thickness = theme.get_constant("graph_editor_grid_line_thickness", "Editor")
	
func _draw():
	var h_lines : int = rect_size.y / grid_cell_size
	var v_lines : int = rect_size.x / grid_cell_size
	
	var offset : Vector2 = Vector2()
	
	offset.x = scroll_horizontal % grid_cell_size
	offset.y = scroll_vertical % grid_cell_size
	
	for i in (h_lines + 1):
		var line_offset = grid_cell_size * (i + 1) - offset.y
		
		var from = Vector2(0, line_offset)
		var to = Vector2(rect_size.x, line_offset)
		
		draw_line(from, to, grid_big_cell_color, grid_line_thickness)
		
	for i in (v_lines + 1):
		var line_offset = grid_cell_size * (i + 1) - offset.x
		
		var from = Vector2(line_offset, 0)
		var to = Vector2(line_offset, rect_size.y)
		
		draw_line(from, to, grid_big_cell_color, grid_line_thickness)

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
	
	
