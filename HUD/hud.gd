extends CanvasLayer

@onready var ammo_display = $Ammo
@onready var cheese_display = $Cheese

func update_display(display: Control, part: int, whole: int) -> void:
	display.update_display(str(part) + " / " + str(whole))

func update_ammo(part: int, whole: int) -> void:
	update_display(ammo_display, part, whole)

func update_cheese(part: int, whole: int) -> void:
	update_display(cheese_display, part, whole)
