tool
extends Line2D

const LineTexture = preload("Textures/Transition.png")
const LineTextureMode = Line2D.LINE_TEXTURE_TILE
const LineColor = Color.whitesmoke

var curve : Curve2D = null

# Properties
var curvature : float = 0.5 setget set_curvature

var from_position : Vector2 = Vector2() setget set_from_position
var to_position : Vector2 = Vector2() setget set_to_position

func _enter_tree():
	texture = LineTexture
	texture_mode = LineTextureMode
	default_color = LineColor
	
	curve = Curve2D.new()
	curve.bake_interval = 8
	
func set_curvature(p_curvature : float):
	curvature = p_curvature
	
	update_shape()
	
func set_from_position(p_position : Vector2):
	from_position = p_position
	
	update_shape()
	
func set_to_position(p_position : Vector2):
	to_position = p_position
	
	update_shape()
	
func update_shape():
	if curve == null:
		return
		
	curve.clear_points()
	
	var handle_length = from_position.distance_to(to_position) * curvature
		
	curve.add_point(from_position, Vector2(), Vector2(handle_length, 0))
	curve.add_point(to_position, Vector2(-handle_length, 0))
	
	points = curve.get_baked_points()
