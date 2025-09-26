extends Node2D

var drift_timer = 0.0
var drift_change_interval = 8.0

@onready var fog_layer1 = $FogLayer1
@onready var fog_layer2 = $FogLayer2
@onready var fog_layer3 = $FogLayer3
@onready var fog_layer4 = $FogLayer4

func _ready():
	fog_layer1.emitting = true
	fog_layer2.emitting = true
	fog_layer3.emitting = true
	fog_layer4.emitting = true

func _process(delta):
	drift_timer += delta

	if drift_timer >= drift_change_interval:
		drift_timer = 0.0
		change_drift_direction()

	apply_subtle_drift(delta)

func change_drift_direction():
	var angle_variation = randf_range(-20, 20)
	var base_direction = Vector2(1, 0)

	var new_direction1 = base_direction.rotated(deg_to_rad(angle_variation))
	var new_direction2 = base_direction.rotated(deg_to_rad(angle_variation + randf_range(-10, 10)))
	var new_direction3 = base_direction.rotated(deg_to_rad(angle_variation + randf_range(-15, 15)))
	var new_direction4 = base_direction.rotated(deg_to_rad(angle_variation + randf_range(-20, 20)))

	fog_layer1.direction = new_direction1
	fog_layer2.direction = new_direction2
	fog_layer3.direction = new_direction3
	fog_layer4.direction = new_direction4

func apply_subtle_drift(delta):
	var time = Time.get_time_dict_from_system()
	var wave_time = time.second + time.minute * 60.0

	var drift_wave = sin(wave_time * 0.2) * 0.1
	var drift_modifier = Vector2(drift_wave, sin(wave_time * 0.15) * 0.05)

	fog_layer1.gravity = Vector2(1 + drift_modifier.x, drift_modifier.y)
	fog_layer2.gravity = Vector2(0.5 + drift_modifier.x * 0.5, drift_modifier.y * 0.5)
	fog_layer3.gravity = Vector2(0.3 + drift_modifier.x * 0.3, drift_modifier.y * 0.3)
	fog_layer4.gravity = Vector2(0.2 + drift_modifier.x * 0.2, drift_modifier.y * 0.2)

func set_fog_visibility(visibility: float):
	var base_alpha1 = 0.1 * visibility
	var base_alpha2 = 0.08 * visibility
	var base_alpha3 = 0.05 * visibility
	var base_alpha4 = 0.03 * visibility

	fog_layer1.color.a = base_alpha1
	fog_layer2.color.a = base_alpha2
	fog_layer3.color.a = base_alpha3
	fog_layer4.color.a = base_alpha4