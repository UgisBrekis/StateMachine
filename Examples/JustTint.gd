extends StateBase

export(NodePath) var colorRect
export(Color) var tint

var color_rect : ColorRect = null

func on_start(p_args = []):
	color_rect = get_parent().get_node(colorRect)
	color_rect.color = tint