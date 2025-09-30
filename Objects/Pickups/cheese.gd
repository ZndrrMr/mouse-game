extends Area2D

var anchor: Vector2 = Vector2(0, 0)
var t := 0.0

func _ready() -> void:
	anchor = global_position

func _process(delta: float) -> void:
	t += delta
	global_position.y = anchor.y + 8* sin(t)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("_get_inputs"):
		$"../../..".get_cheese()
		
		var sfx := $AudioStreamPlayer
		sfx.play()
		sfx.finished.connect(func(): queue_free())
		sfx.reparent(get_parent())
		queue_free()
