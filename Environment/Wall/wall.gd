extends StaticBody2D

func break_wall():
	var snake = $"../../Snake"
	if !snake.empty_tiles.has(snake.global_to_tile(global_position)):
		snake.empty_tiles.append(snake.global_to_tile(global_position))
		#snake.flood_fill_towards(snake.long_target)
		
		
	var sfx := $AudioStreamPlayer
	sfx.play()
	sfx.finished.connect(func(): queue_free())
	sfx.reparent(get_parent())
	queue_free()
