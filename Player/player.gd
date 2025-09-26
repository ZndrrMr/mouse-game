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

const MAX_SPEED = 90
const MAX_FALL = 420

# setup variables
var coyote_time_timer: float = 0
var jump_buffer_timer: float = 0
var wall_hang_timer: float = 0

var speed: float = 0
var friction: float = 0
var gravity: float = 0
@export var direction: int = 1

# Input tracking
var input_dir : float = 0.0
var jump_hold: bool = false
var jump_press: bool = false
var shoot_press: bool = false
var down_hold: bool = false
var up_hold: bool = false

# states
enum PlayerStates {
	FREE,
	LADDER
}
var state_map = {
	PlayerStates.FREE: Player_State_Free.new().init(self),
	PlayerStates.LADDER: Player_State_Ladder.new().init(self)
}
var state: State = null

func _ready() -> void:
	change_state(PlayerStates.FREE)

func _physics_process(delta: float) -> void:
	if coyote_time_timer > 0:
		coyote_time_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	_get_inputs()
	
	if state:
		state.update(delta)
	
	move_and_slide()

func change_state(new_state: PlayerStates) -> void:
	state = state_map[new_state]

func _get_inputs():
	input_dir = Input.get_axis("Left", "Right")
	down_hold = Input.is_action_pressed("Down")
	up_hold = Input.is_action_pressed("Up")
	jump_hold = Input.is_action_pressed("Jump")
	jump_press = Input.is_action_just_pressed("Jump")
	shoot_press = Input.is_action_just_pressed("Shoot")

func _state_free(delta: float) -> void:
	# JUMP
	if jump_press:
		jump_buffer_timer = JUMP_BUFFER_DUR
	if is_on_floor():
		coyote_time_timer = COYOTE_TIME_DUR
	
	if (jump_buffer_timer > 0) and (coyote_time_timer > 0):
		jump_buffer_timer = 0
		coyote_time_timer = 0
		velocity.y = JUMP_VELOCITY
	
	# GRAVITY
	if jump_hold and velocity.y < 0:
		gravity = GRAVITY_SLOW
	else:
		gravity = GRAVITY_FAST
		
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = clamp(-MAX_FALL, velocity.y, MAX_FALL)
		
	# MOVE
	if (is_on_floor()):
		speed = SPEED_GROUND
		friction = FRIC_GROUND
	else:
		speed = SPEED_AIR
		friction = FRIC_AIR
	
	if input_dir != 0:
		velocity.x += input_dir * speed * delta
		velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED);
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		if abs(velocity.x) < 1:
			velocity.x = 0
