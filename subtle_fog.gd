extends Node2D

var spawn_timer = 0.0
var spawn_interval = 30.0  # Spawn new particles every 30 seconds
var fade_in_particles = []

@onready var fog_layer1 = $FogLayer1
@onready var fog_layer2 = $FogLayer2
@onready var fog_layer3 = $FogLayer3
@onready var fog_layer4 = $FogLayer4

func _ready():
	# Start with lower emission rates for gradual spawning
	fog_layer1.emitting = true
	fog_layer2.emitting = true
	fog_layer3.emitting = true
	fog_layer4.emitting = true

func _process(delta):
	spawn_timer += delta

	# Gradually spawn particles every 30 seconds
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_gradual_particles()

	# Handle fade-in for newly spawned particles
	handle_particle_fade_in(delta)

func spawn_gradual_particles():
	# Create fade-in effect by manipulating scale over time
	var tween = get_tree().create_tween()

	# Temporarily increase emission for a brief burst
	var original_amounts = [fog_layer1.amount, fog_layer2.amount, fog_layer3.amount, fog_layer4.amount]

	# Add a few particles with gradual appearance
	fog_layer1.amount += 3
	fog_layer2.amount += 2
	fog_layer3.amount += 2
	fog_layer4.amount += 1

	# Brief emission burst then return to normal
	tween.tween_callback(reset_emission_amounts.bind(original_amounts)).set_delay(2.0)

func reset_emission_amounts(original_amounts: Array):
	fog_layer1.amount = original_amounts[0]
	fog_layer2.amount = original_amounts[1]
	fog_layer3.amount = original_amounts[2]
	fog_layer4.amount = original_amounts[3]

func handle_particle_fade_in(delta):
	# This creates the illusion of gradual spawning by controlling opacity
	pass

func set_fog_visibility(visibility: float):
	var base_alpha1 = 0.1 * visibility
	var base_alpha2 = 0.08 * visibility
	var base_alpha3 = 0.05 * visibility
	var base_alpha4 = 0.03 * visibility

	fog_layer1.color.a = base_alpha1
	fog_layer2.color.a = base_alpha2
	fog_layer3.color.a = base_alpha3
	fog_layer4.color.a = base_alpha4