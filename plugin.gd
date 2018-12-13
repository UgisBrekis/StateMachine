tool
extends EditorPlugin

const Editor = preload("Editor/Editor.gd")

var editor : Editor = null

func _enter_tree():
	editor = Editor.new(get_editor_interface(), get_undo_redo())
	
	add_control_to_bottom_panel(editor, "State Machine")
	
	editor.connect("attention_request", self, "on_editor_attention_request")

func _exit_tree():
	editor.disconnect("attention_request", self, "on_editor_attention_request")
	
	remove_control_from_bottom_panel(editor)
	
	editor.free()
	
func save_external_data():
	if editor == null:
		return
		
	if editor.is_queued_for_deletion():
		return
	
	editor.apply_changes()
	
func on_editor_attention_request():
	if editor == null:
		return
		
	if editor.is_queued_for_deletion():
		return
		
	make_bottom_panel_item_visible(editor)