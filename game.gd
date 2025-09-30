extends Node2D

var cheese_total: int
var cheese_caught: int

func _ready() -> void:
	for cheese in $Pickups/Cheeses.get_children():
		cheese_total += 1
	$HUD.update_cheese(cheese_caught, cheese_total)

func get_cheese() -> void:
	cheese_caught += 1
	$Player.ammo_store += 1
	$Player.update_hud()
	$HUD.update_cheese(cheese_caught, cheese_total)
	
	if cheese_caught == cheese_total:
		$WinArea.enable()
