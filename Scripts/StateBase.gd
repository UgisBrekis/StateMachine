extends Node
class_name StateBase

# Signals
signal transition_requested(p_output, p_args)

func on_start(p_args = []):
	pass
	
func on_stop():
	pass

func invoke_transition(p_output, p_args = []):
	emit_signal("transition_requested", p_output, p_args)
