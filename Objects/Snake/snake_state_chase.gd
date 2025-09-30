extends State
class_name Snake_State_Chase

func update(delta):
	host.move(210, delta)
	host.chase_to_sniff()
