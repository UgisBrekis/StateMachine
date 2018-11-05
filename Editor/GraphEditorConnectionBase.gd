tool
extends Line2D

const LineTextureMode = Line2D.LINE_TEXTURE_TILE
const LineColor = Color.whitesmoke

var curve : Curve2D = null

# Properties
var curvature : float = 20 setget set_curvature

var from_position : Vector2 = Vector2() setget set_from_position
var to_position : Vector2 = Vector2() setget set_to_position

var reroute_points : PoolVector2Array = PoolVector2Array()

func _init():
	create_texture()
	texture_mode = LineTextureMode
	default_color = LineColor
	
	curve = Curve2D.new()
	curve.bake_interval = 8

func create_texture():
	var image = Image.new()
	image.create(6, 6, false, Image.FORMAT_LA8)

	image.lock()

	for x in 6:
		image.set_pixel(x, 1, Color.darkgray)
		image.set_pixel(x, 2, Color.white)
		image.set_pixel(x, 3, Color.white)
		image.set_pixel(x, 4, Color.darkgray)

	image.unlock()

	var image_texture = ImageTexture.new()
	image_texture.create_from_image(image)

	texture = image_texture
	
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
	
	var handle_length = min(from_position.distance_to(to_position) * 0.5, curvature)
		
	curve.add_point(from_position)
	#curve.add_point(from_position + Vector2(20, 0), Vector2(), Vector2(handle_length, 0))
	
	for point in reroute_points:
		curve.add_point(point)
	
	#curve.add_point(to_position + Vector2(-20, 0), Vector2(-handle_length, 0))
	curve.add_point(to_position)
	
	points = curve.get_baked_points()
