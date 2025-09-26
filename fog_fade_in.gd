extends Node2D

var fade_duration = 1.0  # Duration of fade-in effect in seconds
var target_alphas = []  # Store the target alpha values for each layer
var current_fade_time = 0.0
var is_fading_in = true

@onready var fog_layer1 = $FogLayer1
@onready var fog_layer2 = $FogLayer2
@onready var fog_layer3 = $FogLayer3
@onready var fog_layer4 = $FogLayer4

func _ready():
	# Store the target alpha values
	target_alphas = [
		fog_layer1.color.a,
		fog_layer2.color.a,
		fog_layer3.color.a,
		fog_layer4.color.a
	]

	# Start with fully transparent
	fog_layer1.color.a = 0.0
	fog_layer2.color.a = 0.0
	fog_layer3.color.a = 0.0
	fog_layer4.color.a = 0.0

	# Start emitting
	fog_layer1.emitting = true
	fog_layer2.emitting = true
	fog_layer3.emitting = true
	fog_layer4.emitting = true

func _process(delta):
	if is_fading_in:
		current_fade_time += delta
		var fade_progress = min(current_fade_time / fade_duration, 1.0)

		# Apply fade-in to each layer
		fog_layer1.color.a = target_alphas[0] * fade_progress
		fog_layer2.color.a = target_alphas[1] * fade_progress
		fog_layer3.color.a = target_alphas[2] * fade_progress
		fog_layer4.color.a = target_alphas[3] * fade_progress

		# Stop fading when complete
		if fade_progress >= 1.0:
			is_fading_in = false

func set_fog_visibility(visibility: float):
	# Update target alphas when visibility changes
	target_alphas[0] = 0.1 * visibility
	target_alphas[1] = 0.08 * visibility
	target_alphas[2] = 0.05 * visibility
	target_alphas[3] = 0.03 * visibility

	# If not fading in, apply immediately
	if not is_fading_in:
		fog_layer1.color.a = target_alphas[0]
		fog_layer2.color.a = target_alphas[1]
		fog_layer3.color.a = target_alphas[2]
		fog_layer4.color.a = target_alphas[3]