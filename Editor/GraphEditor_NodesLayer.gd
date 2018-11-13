tool
extends Control

const GraphEditorNode = preload("GraphEditorNode.gd")
const GraphEditorNodeSlot = preload("GraphEditorNodeSlot.gd")

const GraphEditorEntryNode = preload("GraphEditorEntryNode.gd")
const GraphEditorStateNode = preload("GraphEditorStateNode.gd")

func clear():
	for child in get_children():
		if !(child is GraphEditorNode):
			continue
			
		child.free()

func get_nodes_from_position(p_position : Vector2):
	var nodes = []
	
	for child in get_children():
		if !(child is GraphEditorNode):
			continue
			
		if child.get_rect().has_point(p_position):
			nodes.push_back(child)
	
	return nodes
	
func apply_changes():
	for child in get_children():
		if !(child is GraphEditorStateNode):
			continue
			
		var node = child as GraphEditorStateNode
		
		node.update_property_cache()
		


