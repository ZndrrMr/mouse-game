extends Label

func _process(delta: float) -> void:
	text = "Delta: " + str("%.2f" % delta) + "\nFPS: " + str(Engine.get_frames_per_second())
