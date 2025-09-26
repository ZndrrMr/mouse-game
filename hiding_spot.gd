extends Area2D

@export var is_player_hidden: bool = false

func _ready():
	print("Hiding spot initialized")

	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Check if the entered body is the player
	if body.is_in_group("player"):
		is_player_hidden = true
		print("Player entered hiding spot - now invincible")

func _on_body_exited(body):
	# Check if the exited body is the player
	if body.is_in_group("player"):
		is_player_hidden = false
		print("Player left hiding spot - no longer invincible")