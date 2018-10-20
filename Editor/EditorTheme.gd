extends Reference

static func create_editor_theme(p_theme : Theme):
	var scale = p_theme.get_constant("scale", "Editor")
	
	var dark_theme = p_theme.get_constant("dark_theme", "Editor")
	
	var accent_color = p_theme.get_color("accent_color", "Editor")
	var highlight_color = p_theme.get_color("highlight_color", "Editor")
	var base_color = p_theme.get_color("base_color", "Editor")
	var dark_color_1 = p_theme.get_color("dark_color_1", "Editor")
	var dark_color_2 = p_theme.get_color("dark_color_2", "Editor")
	var dark_color_3 = p_theme.get_color("dark_color_3", "Editor")
	var contrast_color_1 = p_theme.get_color("contrast_color_1", "Editor")
	var contrast_color_2 = p_theme.get_color("contrast_color_2", "Editor")
	
	# Graph editor
	# Grid constants
	p_theme.set_constant("graph_editor_grid_cell_size", "Editor", 20 * scale)
	p_theme.set_constant("graph_editor_grid_line_thickness", "Editor", 1 * scale)
	
	# Snap to node sockets within this distance
	p_theme.set_constant("graph_editor_socket_snap_distance", "Editor", 10 * scale)
	
	# Graph Editor Node
	# Body
	p_theme.set_constant("state_node_content_margin_left", "Editor", 4 * scale)
	p_theme.set_constant("state_node_content_margin_top", "Editor", 8 * scale)
	p_theme.set_constant("state_node_content_margin_bottom", "Editor", 16 * scale)
	p_theme.set_constant("state_node_content_margin_right", "Editor", 4 * scale)
	
	p_theme.set_constant("state_node_slot_separation", "Editor", 8 * scale)
	
	var sb = StyleBoxFlat.new()
	
	if dark_theme:
		sb.bg_color = Color(0, 0, 0, 0.75)
		
	else:
		sb.bg_color = Color(0.75, 0.75, 0.75, 0.75)
	
	sb.border_color = dark_color_3
	
	sb.border_width_left = 1 * scale
	sb.border_width_top = 1 * scale
	sb.border_width_right = 1 * scale
	sb.border_width_bottom = 1 * scale
	
	p_theme.set_stylebox("state_node", "Editor", sb)
	
	# Header
	sb = StyleBoxFlat.new()
	sb.bg_color = base_color
	
	sb.content_margin_bottom = 2 * scale
	sb.content_margin_left = 4 * scale
	sb.content_margin_right = 4 * scale
	sb.content_margin_top = 2 * scale
	
	p_theme.set_stylebox("state_node_header", "Editor", sb)
	
	# Slot
	sb = StyleBoxEmpty.new()
	
	sb.content_margin_bottom = 2 * scale
	sb.content_margin_top = 2 * scale
	
	p_theme.set_stylebox("state_node_slot", "Editor", sb)
	
	# Focus
	sb = StyleBoxFlat.new()
	sb.draw_center = false
	
	sb.border_color = accent_color
	
	sb.border_width_left = 1 * scale
	sb.border_width_top = 1 * scale
	sb.border_width_right = 1 * scale
	sb.border_width_bottom = 1 * scale
	
	sb.expand_margin_bottom = 2 * scale
	sb.expand_margin_left = 2 * scale
	sb.expand_margin_right = 2 * scale
	sb.expand_margin_top = 2 * scale
	
	p_theme.set_stylebox("state_node_focus", "Editor", sb)
	
	# Connection
	var connection_width = 4.0 * scale
	p_theme.set_constant("graph_editor_connection_width", "Editor", 4 * scale)
