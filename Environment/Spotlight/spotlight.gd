extends Node2D

enum SpotlightStates {
	ON,
	FLICKER
}

var state: SpotlightStates = SpotlightStates.FLICKER
var countdown: float = 0.0

const ON_COUNTDOWN_TIME_MIN: float = 5.0
const ON_COUNTDOWN_TIME_MAX: float = 20.0

const FLICKER_COUNTDOWN_TIME_MIN: float = 0.3
const FLICKER_COUNTDOWN_TIME_MAX: float = 0.6

func _process(delta: float) -> void:
	countdown -= delta
	
	if countdown <= 0.0:
		match state:
			SpotlightStates.ON:
				flicker()
				
			SpotlightStates.FLICKER:
				countdown = randf_range(ON_COUNTDOWN_TIME_MIN, ON_COUNTDOWN_TIME_MAX)
				state = SpotlightStates.ON
				$Lights.visible = true
				
	elif state == SpotlightStates.FLICKER:
		if int(countdown * 100) % 10 < 5:
			$Lights.visible = false
		else:
			$Lights.visible = true

func flicker() -> void:
	countdown = randf_range(FLICKER_COUNTDOWN_TIME_MIN, FLICKER_COUNTDOWN_TIME_MAX)
	state = SpotlightStates.FLICKER
