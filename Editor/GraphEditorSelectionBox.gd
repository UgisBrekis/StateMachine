tool
extends Control

var from_position : Vector2 = Vector2() setget set_from_position
var to_position : Vector2 = Vector2() setget set_to_position

var bounds : PoolVector2Array = PoolVector2Array()

func _init():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	hide()

func set_from_position(p_position):
	from_position = p_position
	
	update_rect()
	
func set_to_position(p_position):
	to_position = p_position
	
	update_rect()
	
func update_rect():
	rect_position = Vector2(min(from_position.x, to_position.x), min(from_position.y, to_position.y))
	rect_size = Vector2(max(from_position.x, to_position.x), max(from_position.y, to_position.y)) - rect_position
	
	bounds.resize(0)
	
	bounds.push_back(Vector2())
	bounds.push_back(Vector2(rect_size.x, 0))
	bounds.push_back(rect_size)
	bounds.push_back(Vector2(0, rect_size.y))
	
func _draw():
	draw_rect(Rect2(Vector2(), rect_size), Color(1, 1, 1, 0.1))
	draw_rect(Rect2(Vector2(), rect_size), Color(1, 1, 1, 0.3), false)
	draw_rect(Rect2(Vector2(-1, -1), rect_size + Vector2(1, 1)), Color(0, 0, 0, 0.3), false)