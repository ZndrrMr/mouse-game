extends Area2D

func _on_body_entered(body):
	if body.name == "CharacterBody2D" or body.is_in_group("player"):
		queue_free()