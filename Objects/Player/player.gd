extends CharacterBody2D

# Constants
const SPEED_GROUND = 2160.0
const FRIC_GROUND = 2400.0
const SPEED_AIR = 1800.0
const FRIC_AIR = 800.0

const JUMP_VELOCITY = -200.0
const GRAVITY_SLOW = 600
const GRAVITY_FAST = 1100
const COYOTE_TIME_DUR = 0.1
const JUMP_BUFFER_DUR = 0.1

const MAX_SPEED = 120
const MAX_FALL = 420

const LADDER_SPEED = 90

const MAX_AMMO = 1

# setup variables
var coyote_time_timer: float = 0
var jump_buffer_timer: float = 0
var ladder_cooldown: bool = true

var ammo: int = MAX_AMMO
var ammo_store: int = 1

var speed: float = 0
var friction: float = 0
var gravity: float = 0
@export var direction: int = 1

var player_hidden: bool = false

var grounded: bool = false

var bullet: PackedScene = preload("res://Environment/Bullet/bullet.tscn")

# Input tracking
var input_dir_h : float = 0.0
var input_dir_v : float = 0.0
var jump_hold: bool = false
var jump_press: bool = false
var reload_press: bool = false
var shoot_press: bool = false

# states
enum PlayerStates {
	FREE,
	LADDER,
	RELOAD
}
var state_map = {
	PlayerStates.FREE: Player_State_Free.new().init(self),
	PlayerStates.LADDER: Player_State_Ladder.new().init(self),
	PlayerStates.RELOAD: Player_State_Reload.new().init(self)
}
var state: State = null

func _ready() -> void:
	change_state(PlayerStates.FREE)
	$Music.play()
	
	call_deferred("update_hud")

func update_hud():
	$"../HUD".update_ammo(ammo, ammo_store + ammo)

func _physics_process(delta: float) -> void:
	_get_inputs()
	
	if coyote_time_timer > 0:
		coyote_time_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if input_dir_v == 0:
		ladder_cooldown = true
	
	if state:
		state.update(delta)
	
	grounded = is_on_floor()
	
	move_and_slide()
	animate()
	sound_blend()
	
	var shake_dist = 500
	var dist = (global_position - $"../Snake".global_position).length()
	if dist < shake_dist && $"../Snake".velocity.length() > 0:
		$"../Camera2D".start_shake((shake_dist - dist)/shake_dist * 4, 1/delta)

func change_state(new_state: PlayerStates) -> void:
	state = state_map[new_state]

func _get_inputs():
	input_dir_h = Input.get_axis("Left", "Right")
	input_dir_v = Input.get_axis("Up", "Down")
	jump_hold = Input.is_action_pressed("Jump")
	jump_press = Input.is_action_just_pressed("Jump")
	shoot_press = Input.is_action_just_pressed("Shoot")
	reload_press = Input.is_action_just_pressed("Reload")

func _state_free(delta: float) -> void:
	# JUMP
	if jump_press:
		jump_buffer_timer = JUMP_BUFFER_DUR
	if is_on_floor():
		coyote_time_timer = COYOTE_TIME_DUR
	
	if (jump_buffer_timer > 0) and (coyote_time_timer > 0):
		jump(JUMP_VELOCITY)
	
	# GRAVITY
	if jump_hold and velocity.y < 0:
		gravity = GRAVITY_SLOW
	else:
		gravity = GRAVITY_FAST
		
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = clamp(-MAX_FALL, velocity.y, MAX_FALL)
	else:
		if (!grounded):
			$Footstep.play()
		
	# MOVE
	if (is_on_floor()):
		speed = SPEED_GROUND
		friction = FRIC_GROUND
	else:
		speed = SPEED_AIR
		friction = FRIC_AIR
	
	if input_dir_h != 0:
		velocity.x += input_dir_h * speed * delta
		velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED);
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		if abs(velocity.x) < 1:
			velocity.x = 0
	
	# LADDER
	if input_dir_v != 0 and ladder_cooldown and get_ladder(global_position):
		change_state(PlayerStates.LADDER)
		global_position.x = floor((global_position.x - 16) / 32) * 32 + 32
		velocity = Vector2(0, 0)
	
	# SHOOT
	shoot()
	reload()

func _state_ladder(delta: float) -> void:
	# MOVE
	if input_dir_v != 0:
		velocity.y = LADDER_SPEED * input_dir_v
	else:
		velocity.y = 0
	if !get_ladder(global_position + Vector2(0, input_dir_v) * 16):
		velocity.y = 0
	
	# JUMP OFF
	if jump_press or (is_on_floor() and input_dir_v > 0):
		change_state(PlayerStates.FREE)
		ladder_cooldown = false
		if input_dir_v <= 0 and !is_on_floor():
			jump(JUMP_VELOCITY)

func jump(jump_vel: float) -> void:
	jump_buffer_timer = 0
	coyote_time_timer = 0
	velocity.y = jump_vel
	$Footstep.play()
	

func get_ladder(position: Vector2) -> bool:
	var layer: TileMapLayer = $"../Ladders" as TileMapLayer
	var cell: Vector2i = layer.local_to_map(layer.to_local(position))
	return layer.get_cell_source_id(cell) != -1

func shoot() -> void:
	if shoot_press and ammo > 0:
		ammo -= 1
		
		update_hud()
		
		var b := bullet.instantiate()
		get_tree().root.add_child(b)
		
		b.setup(global_position + $Gun.position, get_global_mouse_position())
		
		$"../Snake".start_chase()
		$"../Camera2D".start_shake(20, 10)
		$ShotgunSFX.play()

func _state_reload() -> void:
	if jump_press:
		change_state(PlayerStates.FREE)
		jump(JUMP_VELOCITY)

func can_reload() -> bool:
	return !(abs(input_dir_h) > 0 or abs(input_dir_v) > 0 or shoot_press or jump_press or !is_on_floor())

func reload() -> void:
	if reload_press and can_reload():
		if ammo < MAX_AMMO and ammo_store > 0:
			change_state(PlayerStates.RELOAD)
			velocity = Vector2.ZERO
			$AnimatedSprite2D.play("Reload")

func is_hidden() -> bool:
	return player_hidden and velocity.length() < 1 and state == state_map[PlayerStates.FREE]

func set_hidden(value: bool) -> void:
	player_hidden = value

func sound_blend() -> void:
	var dist = $"../Snake".global_position - global_position
	
	var blend : float = clamp((dist.length() - 200 )/ 1000, 0.0, 1.0)
	
	$Music.volume_linear = blend * 0.6

func animate() -> void:
	var mouse_direction = sign(get_global_mouse_position().x - global_position.x)
	var anim: AnimatedSprite2D = $AnimatedSprite2D
	var gun: AnimatedSprite2D = $Gun
	
	if is_hidden():
		gun.animation = "Dark"
	else:
		gun.animation = "Light"
	
	if state == state_map[PlayerStates.FREE]:
		gun.visible = true
		
		anim.flip_h = mouse_direction > 0
		gun.position = Vector2(mouse_direction * 9, -3)
		
		var mouse_pos = get_global_mouse_position()
		var angle_to_mouse = global_position.angle_to_point(mouse_pos)
		gun.rotation = angle_to_mouse
		
		if mouse_direction < 0:
			gun.flip_v = true
		else:
			gun.flip_v = false
		
		if is_on_floor():
			if abs(input_dir_h) > 0:
				anim.play("Run")
				if mouse_direction * input_dir_h < 0:
					anim.play_backwards()
			else:
				if is_hidden():
					anim.play("Hidden")
				else:
					anim.play("Idle")
		else:
			if velocity.y <= 0:
				anim.play("Jump")
			else:
				anim.play("Fall")
	elif state == state_map[PlayerStates.LADDER]:
		gun.visible = false
		
		anim.flip_h = false
		if abs(input_dir_v) > 0:
			anim.play("Climb")
			if input_dir_v > 0:
				anim.play_backwards()
		else:
			anim.pause()
	elif state == state_map[PlayerStates.RELOAD]:
		gun.visible = false

func _on_animated_sprite_2d_frame_changed() -> void:
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	if sprite.animation == "Run" and (sprite.frame == 1 or sprite.frame == 5):
		$Footstep.pitch_scale = randf_range(0.9, 1.1)
		$Footstep.play()
	elif sprite.animation == "Climb" and sprite.frame == 1:
		$LadderFootstep.pitch_scale = randf_range(0.9, 1.1)
		$LadderFootstep.play()
	elif sprite.animation == "Reload":
		match sprite.frame:
			5:
				$Reload2.play()
			22:
				$Reload1.play()


func _on_animated_sprite_2d_animation_finished() -> void:
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	if sprite.animation == "Reload":
		ammo += 1
		ammo_store -= 1
		update_hud()
		change_state(PlayerStates.FREE)
		$Reload2.play()
