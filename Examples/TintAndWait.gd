extends StateBase

enum transitions {
	OnClicked
}

export(NodePath) var tween
export(NodePath) var colorRect
export(Color) var tint

var color_rect : ColorRect = null
var tween_node : Tween = null

func on_start(p_args = []):
	tween_node = get_parent().get_node(tween) as Tween
	color_rect = get_parent().get_node(colorRect) as ColorRect
	
	# Default color from which tween is gonna interpolate
	var from_color = Color.black
	
	# If previous state invoked transition with color argument, use that color
	if p_args.size() == 1:
		from_color = p_args[0]
		
	tween_node.interpolate_property(color_rect, "color", from_color, tint, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween_node.start()
	
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			invoke_transition(OnClicked, [color_rect.color])