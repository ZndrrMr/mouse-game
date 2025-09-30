extends State
class_name Snake_State_Stun

func update(delta):
	host.stun_frame(delta)
	host.velocity = Vector2.ZERO
