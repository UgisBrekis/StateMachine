tool
extends "GraphEditorNode.gd"

const State = preload("../Resources/State.gd")
const StateBase = preload("../Scripts/StateBase.gd")

var state : State = null

# Signals
signal outputs_updated

func _init(p_theme : Theme):
	theme = p_theme
	initialize_view()

func initialize(p_state : State):
	state = p_state

	# Apply properties
	display_scale = theme.get_constant("scale", "Editor")
	self.offset = state.offset
	self.title = state.superstate.name
	
	if state.superstate.state_script == null:
		warning_button.show()
	else:
		warning_button.hide()

	# Create input slot
	add_input_slot(1, Color.white, "Start")

	# Add output slots
	update_outputs()

	# Connect signals
	connect("offset_changed", self, "on_offset_changed")
	
	state.superstate.connect("renamed", self, "on_state_renamed")
	state.superstate.connect("state_script_changed", self, "on_state_script_changed")
	state.superstate.connect("outputs_changed", self, "on_state_outputs_changed")

func dispose():
	print("Remove this graph editor node")

func on_offset_changed():
	if state == null:
		return

	state.offset = offset

func on_state_renamed():
	if state == null:
		return

	self.title = state.superstate.name

func on_state_script_changed():
	if state == null:
		return
		
	if state.superstate.state_script == null:
		warning_button.show()
	else:
		warning_button.hide()
	
func on_state_outputs_changed():
	if state == null:
		return
		
	update_outputs()
		
func update_outputs():
	remove_all_output_slots()
	
	for output in state.superstate.outputs:
		add_output_slot(2, Color.coral, output)
		
	emit_signal("outputs_updated")
