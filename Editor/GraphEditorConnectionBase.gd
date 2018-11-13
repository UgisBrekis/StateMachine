tool
extends Line2D

const Rerouter = preload("GraphEditorRerouter.gd")

const LineTextureMode = Line2D.LINE_TEXTURE_TILE
const LineColor = Color.whitesmoke

var curve : Curve2D = null

# Properties
var reroute_default_texture : Texture = null
var reroute_highlight_texture : Texture = null

var curvature : float = 20 setget set_curvature
var display_scale : float = 1.0
var snap_distance : int = -1 setget set_snap_distance

var from_position : Vector2 = Vector2() setget set_from_position
var to_position : Vector2 = Vector2() setget set_to_position

var reroute_points : PoolVector2Array = PoolVector2Array()

signal reroute_points_changed(p_connection)

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
	
func set_snap_distance(p_snap_distance : int):
	snap_distance = p_snap_distance
	
	for rerouter in get_children():
		rerouter.snap_distance = snap_distance
	
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
	
	#var handle_length = min(from_position.distance_to(to_position) * 0.5, curvature)
		
	curve.add_point(from_position)
	#curve.add_point(from_position + Vector2(20, 0), Vector2(), Vector2(handle_length, 0))
	
	for point in reroute_points:
		curve.add_point(point * display_scale)
	
	#curve.add_point(to_position + Vector2(-20, 0), Vector2(-handle_length, 0))
	curve.add_point(to_position)
	
	var first : Vector2 = curve.get_point_position(0)
	var last : Vector2 = curve.get_point_position(curve.get_point_count() - 1)
	var previous : Vector2 = curve.get_point_position(curve.get_point_count() - 2)
	var next : Vector2 = curve.get_point_position(1)
	
	var handle_out : float = min(first.distance_to(next) * 0.5, curvature)
	var handle_in : float = min(last.distance_to(previous) * 0.5, curvature)
	
	curve.set_point_out(0, Vector2(handle_out, 0))
	curve.set_point_in(curve.get_point_count() - 1, Vector2(-handle_in, 0))
	
	if curve.get_point_count() > 2:
		for i in range(1, curve.get_point_count() - 1):
			var current : Vector2 = curve.get_point_position(i)
			previous = curve.get_point_position(i - 1)
			next = curve.get_point_position(i + 1)
			
			var handle : Vector2 = (next - previous).normalized()
			handle.y = 0
			
			curve.set_point_in(i, -handle * min(current.distance_to(previous) * 0.5, curvature))
			curve.set_point_out(i, handle * min(current.distance_to(next) * 0.5, curvature))
	
	points = curve.get_baked_points()
	
func add_reroute_point(p_position : Vector2):
	var index = 0
	
	for i in reroute_points.size():
		if curve.get_closest_offset(p_position) < curve.get_closest_offset(reroute_points[i] * display_scale):
			break
			
		index = i + 1
		
	reroute_points.insert(index, p_position / display_scale)
		
	var rerouter = Rerouter.new(width, reroute_default_texture, reroute_highlight_texture, display_scale, reroute_points[index])
	add_child(rerouter)
	move_child(rerouter, index)
	
	rerouter.connect("offset_changed", self, "on_rerouter_offset_changed")
	rerouter.connect("remove_requested", self, "on_rerouter_remove_requested")
	
	update_shape()
	
func remove_reroute_point(p_index : int):
	var rerouter : Rerouter = get_child(p_index)
	rerouter.queue_free()
	
	reroute_points.remove(p_index)
	
	update_shape()
	
	emit_signal("reroute_points_changed", self)
	
func on_rerouter_offset_changed(p_id : int, p_offset : Vector2):
	var rerouter = get_child(p_id) as Rerouter
	
	reroute_points[p_id] = (rerouter.rect_position + rerouter.rect_size / 2) / display_scale
	
	emit_signal("reroute_points_changed", self)
	
	update_shape()
	
func on_rerouter_remove_requested(p_id):
	get_child(p_id).queue_free()
	
	reroute_points.remove(p_id)
	
	emit_signal("reroute_points_changed", self)
	
	update_shape()
