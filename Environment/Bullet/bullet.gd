extends Area2D

@export var direction: int

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("break_wall"):
		body.break_wall()
	if body.has_method("stun"):
		body.stun()

func _on_animated_sprite_2d_animation_finished() -> void:
	queue_free()

func setup(from: Vector2, to: Vector2):
	global_position = from
	look_at(to)
	
	var direction_vector = (to - from).normalized()
	global_position += direction_vector * 24
	if direction_vector.x < 0:
		$AnimatedSprite2D.flip_v = true
	
	$AnimatedSprite2D.play("Blast")
	
	$CPUParticles2D.rotation = 0
	$CPUParticles2D.angle_min = -rotation_degrees - 20
	$CPUParticles2D.angle_max = -rotation_degrees + 20
	$CPUParticles2D.restart()
	$CPUParticles2D.emitting = true
