extends State
class_name Snake_State_Smell

func update(delta):
	host.sniff(delta)
	#host.velocity = Vector2.ZERO
