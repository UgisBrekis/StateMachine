tool
extends Panel

const GRAPH_SHEET_SIZE = 4096

const GraphEditorScrollContainer = preload("../GraphEditor_ScrollContainer.gd")

const ConnectionsLayer = preload("../GraphEditor_ConnectionsLayer.gd")
const NodesLayer = preload("../GraphEditor_NodesLayer.gd")
const OverlayLayer = preload("../GraphEditor_OverlayLayer.gd")

var scroll_container : GraphEditorScrollContainer = null

var layers_container : Control = null

var connections_layer : ConnectionsLayer = null
var nodes_layer : NodesLayer = null
var overlay_layer : OverlayLayer = null

var popup_menu : PopupMenu = null

func initialize_view():
	# Scroll container
	scroll_container = GraphEditorScrollContainer.new(theme)
	
	# Layers container
	layers_container = Control.new()
	
	# Layers
	connections_layer = ConnectionsLayer.new(theme)
	nodes_layer = NodesLayer.new()
	overlay_layer = OverlayLayer.new(theme)
	
	connections_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	nodes_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	connections_layer.set_anchors_preset(Control.PRESET_WIDE)
	nodes_layer.set_anchors_preset(Control.PRESET_WIDE)
	overlay_layer.set_anchors_preset(Control.PRESET_WIDE)
	
	layers_container.add_child(connections_layer)
	layers_container.add_child(nodes_layer)
	layers_container.add_child(overlay_layer)
	
	layers_container.rect_min_size = Vector2(GRAPH_SHEET_SIZE, GRAPH_SHEET_SIZE)
	layers_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	scroll_container.add_child(layers_container)
	
	add_child(scroll_container)
	
	scroll_container.set_anchors_preset(Control.PRESET_WIDE)
	
	# Popup menu
	popup_menu = PopupMenu.new()
	
	add_child(popup_menu)