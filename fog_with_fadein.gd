extends Node2D

var fade_duration = 5.0  # 5 seconds fade-in for new particles
var spawn_timer = 0.0
var spawn_interval = 30.0  # Spawn new particles every 30 seconds
var base_alphas = []  # Store base alpha values
var burst_layers = []  # Track burst particle instances

@onready var fog_layer1 = $FogLayer1
@onready var fog_layer2 = $FogLayer2
@onready var fog_layer3 = $FogLayer3
@onready var fog_layer4 = $FogLayer4

func _ready():
	print("Fog script started - initial particles spawn immediately, new ones fade in over ", fade_duration, " seconds")

	# Store base alpha values
	base_alphas = [
		fog_layer1.color.a,
		fog_layer2.color.a,
		fog_layer3.color.a,
		fog_layer4.color.a
	]

	# Start with initial particles fully visible immediately
	fog_layer1.emitting = true
	fog_layer2.emitting = true
	fog_layer3.emitting = true
	fog_layer4.emitting = true

	# Initial particles are fully visible from the start
	fog_layer1.modulate.a = 1.0
	fog_layer2.modulate.a = 1.0
	fog_layer3.modulate.a = 1.0
	fog_layer4.modulate.a = 1.0

func _process(delta):
	spawn_timer += delta

	# Handle fade-in for burst spawns
	for i in range(burst_layers.size() - 1, -1, -1):
		var burst_data = burst_layers[i]
		burst_data.age += delta

		if burst_data.age <= fade_duration:
			var fade_progress = burst_data.age / fade_duration
			# Apply fade to burst particles
			for layer in burst_data.layers:
				if is_instance_valid(layer):
					layer.modulate.a = fade_progress
			print("Burst fade progress: ", fade_progress, " at age: ", burst_data.age)
		else:
			# Remove from tracking once fully faded in
			burst_layers.remove_at(i)

	# Gradually spawn particles every 30 seconds
	if spawn_timer >= spawn_interval:
		print("Spawning new burst particles at time: ", spawn_timer)
		spawn_timer = 0.0
		spawn_gradual_particles()

func spawn_gradual_particles():
	print("Creating new fog burst with fade-in effect")

	# Create new particle emitters for the burst
	var burst_fog1 = CPUParticles2D.new()
	var burst_fog2 = CPUParticles2D.new()
	var burst_fog3 = CPUParticles2D.new()
	var burst_fog4 = CPUParticles2D.new()

	# Copy properties from existing fog layers
	copy_particle_properties(fog_layer1, burst_fog1)
	copy_particle_properties(fog_layer2, burst_fog2)
	copy_particle_properties(fog_layer3, burst_fog3)
	copy_particle_properties(fog_layer4, burst_fog4)

	# Set smaller amounts for burst
	burst_fog1.amount = 3
	burst_fog2.amount = 2
	burst_fog3.amount = 2
	burst_fog4.amount = 1

	# Start transparent
	burst_fog1.modulate.a = 0.0
	burst_fog2.modulate.a = 0.0
	burst_fog3.modulate.a = 0.0
	burst_fog4.modulate.a = 0.0

	# Add to scene
	add_child(burst_fog1)
	add_child(burst_fog2)
	add_child(burst_fog3)
	add_child(burst_fog4)

	# Start emitting
	burst_fog1.emitting = true
	burst_fog2.emitting = true
	burst_fog3.emitting = true
	burst_fog4.emitting = true

	# Track for fade-in
	burst_layers.append({
		"layers": [burst_fog1, burst_fog2, burst_fog3, burst_fog4],
		"age": 0.0
	})

	# Set them to one-shot and clean up after lifetime
	burst_fog1.one_shot = true
	burst_fog2.one_shot = true
	burst_fog3.one_shot = true
	burst_fog4.one_shot = true

	# Remove after their lifetime
	var lifetime = burst_fog1.lifetime
	await get_tree().create_timer(lifetime + fade_duration).timeout
	if is_instance_valid(burst_fog1):
		burst_fog1.queue_free()
	if is_instance_valid(burst_fog2):
		burst_fog2.queue_free()
	if is_instance_valid(burst_fog3):
		burst_fog3.queue_free()
	if is_instance_valid(burst_fog4):
		burst_fog4.queue_free()

func copy_particle_properties(source: CPUParticles2D, target: CPUParticles2D):
	target.z_index = source.z_index
	target.lifetime = source.lifetime
	target.preprocess = 0.0  # Don't preprocess burst particles
	target.texture = source.texture
	target.emission_shape = source.emission_shape
	target.emission_rect_extents = source.emission_rect_extents
	target.direction = source.direction
	target.spread = source.spread
	target.initial_velocity_min = source.initial_velocity_min
	target.initial_velocity_max = source.initial_velocity_max
	target.angular_velocity_min = source.angular_velocity_min
	target.angular_velocity_max = source.angular_velocity_max
	target.gravity = source.gravity
	target.scale_amount_min = source.scale_amount_min
	target.scale_amount_max = source.scale_amount_max
	target.color = source.color

func set_fog_visibility(visibility: float):
	base_alphas[0] = 0.1 * visibility
	base_alphas[1] = 0.08 * visibility
	base_alphas[2] = 0.05 * visibility
	base_alphas[3] = 0.03 * visibility

	fog_layer1.color.a = base_alphas[0]
	fog_layer2.color.a = base_alphas[1]
	fog_layer3.color.a = base_alphas[2]
	fog_layer4.color.a = base_alphas[3]