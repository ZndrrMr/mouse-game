extends Area2D

var fade_speed = 10.0

func _ready():
	modulate.a = 1.0

func _process(delta):
	modulate.a -= fade_speed * delta
	if modulate.a <= 0:
		queue_free()

func _on_timer_timeout():
	queue_free()