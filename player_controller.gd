extends CharacterBody2D

const SPEED = 300.0
const RECOIL_FORCE = 200.0
const SHOOT_COOLDOWN = 1.0
const PELLET_COUNT = 8
const SPREAD_ANGLE = 30.0

var bullet_scene = preload("res://bullet.tscn")
var can_shoot = true
var shoot_timer = 0.0
var recoil_velocity = Vector2.ZERO

func _ready():
	set_physics_process(true)
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_select") and can_shoot:
		shoot_shotgun()

func _physics_process(delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if direction:
		velocity = direction * SPEED + recoil_velocity
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * delta) + recoil_velocity

	recoil_velocity = recoil_velocity.move_toward(Vector2.ZERO, 800 * delta)

	move_and_slide()

	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true

func shoot_shotgun():
	can_shoot = false
	shoot_timer = SHOOT_COOLDOWN

	var mouse_pos = get_global_mouse_position()
	var shoot_direction = (mouse_pos - global_position).normalized()

	recoil_velocity = -shoot_direction * RECOIL_FORCE

	for i in range(PELLET_COUNT):
		var bullet = bullet_scene.instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = global_position

		var spread = randf_range(-SPREAD_ANGLE, SPREAD_ANGLE)
		var radians = deg_to_rad(spread)

		var pellet_direction = shoot_direction.rotated(radians)
		bullet.direction = pellet_direction

		var speed_variation = randf_range(0.8, 1.2)
		bullet.speed = bullet.speed * speed_variation

	create_muzzle_flash(shoot_direction)

func create_muzzle_flash(direction):
	var flash = PointLight2D.new()
	add_child(flash)
	flash.position = direction * 20
	flash.energy = 3.0
	flash.texture_scale = 0.5
	flash.color = Color(1, 0.9, 0.6)

	var gradient_texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.add_point(0.5, Color(1, 1, 1, 0.5))
	gradient.add_point(1.0, Color(1, 1, 1, 0))
	gradient_texture.gradient = gradient
	gradient_texture.fill = GradientTexture2D.FILL_RADIAL
	gradient_texture.fill_from = Vector2(0.5, 0.5)
	gradient_texture.width = 128
	gradient_texture.height = 128
	flash.texture = gradient_texture

	var tween = get_tree().create_tween()
	tween.tween_property(flash, "energy", 0.0, 0.1)
	tween.tween_callback(flash.queue_free)