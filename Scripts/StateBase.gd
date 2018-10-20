extends Node
class_name StateBase

#enum transitions {}

# Signals
signal transition_requested(p_index, p_args)

func on_start(p_args = []):
	pass
	
func on_stop():
	pass

func invoke_transition(p_index, p_args = []):
	emit_signal("transition_requested", p_index, p_args)
