extends Area2D

var speed = 600.0
var damage = 10
var direction = Vector2.ZERO
var lifetime = 2.0

func _ready():
	set_physics_process(true)

func _physics_process(delta):
	position += direction * speed * delta
	lifetime -= delta

	if lifetime <= 0:
		queue_free()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _on_screen_exited():
	queue_free()