extends State
class_name Snake_State_Kill

func update(delta):
	host.move(240, delta)
	host.kill_update()
