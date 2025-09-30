extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("set_hidden"):
		body.set_hidden(true)


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("set_hidden"):
		body.set_hidden(false)
