extends ColorRect

enum FogState {
	OPEN,
	CLOSE,
	CONST
}

const RADIUSF_OPEN: = 0.285
const RADIUSOFF_OPEN: = 0.05

var progress: float
const DURATION: float = 1

var state: FogState = FogState.OPEN

func _process(delta: float) -> void:
	match state:
		FogState.OPEN:
			update_shader(delta, false)
		FogState.CLOSE:
			update_shader(delta, true)
	
	if progress >= 1.0:
		progress = 0.0
		state = FogState.CONST

func update_shader(delta: float, invert: bool) -> void:
	progress += delta * DURATION
	var final_prog = progress
	if invert:
		final_prog = 1 - final_prog
	
	final_prog = smoothstep(0.0, 1.0, final_prog)
	material.set_shader_parameter("radiusf", lerp(0.0, RADIUSF_OPEN, final_prog))
	material.set_shader_parameter("radius_offset", lerp(0.0, RADIUSOFF_OPEN, final_prog))

func open() -> void:
	state = FogState.OPEN
	progress = 0.0

func close() -> void:
	state = FogState.CLOSE
	progress = 0.0
