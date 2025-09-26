extends Node2D

@onready var fog_layer1 = $FogLayer1
@onready var fog_layer2 = $FogLayer2
@onready var fog_layer3 = $FogLayer3
@onready var fog_layer4 = $FogLayer4

func _ready():
	# Spawn fog once when level loads
	fog_layer1.restart()
	fog_layer2.restart()
	fog_layer3.restart()
	fog_layer4.restart()

func set_fog_visibility(visibility: float):
	var base_alpha1 = 0.1 * visibility
	var base_alpha2 = 0.08 * visibility
	var base_alpha3 = 0.05 * visibility
	var base_alpha4 = 0.03 * visibility

	fog_layer1.color.a = base_alpha1
	fog_layer2.color.a = base_alpha2
	fog_layer3.color.a = base_alpha3
	fog_layer4.color.a = base_alpha4