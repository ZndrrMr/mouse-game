extends Node2D

var respawn_timer = 0.0
var respawn_interval = 600.0  # 10 minutes

@onready var fog_layer1 = $FogLayer1
@onready var fog_layer2 = $FogLayer2
@onready var fog_layer3 = $FogLayer3
@onready var fog_layer4 = $FogLayer4

func _ready():
	# Fog is already pre-spawned due to preprocess
	fog_layer1.emitting = true
	fog_layer2.emitting = true
	fog_layer3.emitting = true
	fog_layer4.emitting = true

func _process(delta):
	respawn_timer += delta

	# Spawn new particles every 10 minutes
	if respawn_timer >= respawn_interval:
		respawn_timer = 0.0
		spawn_new_particles()

func spawn_new_particles():
	# Add one new particle to each layer
	fog_layer1.amount += 1
	fog_layer2.amount += 1
	fog_layer3.amount += 1
	fog_layer4.amount += 1

	# Restart to apply new amount
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