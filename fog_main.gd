extends CanvasLayer

@onready var fog_ref := $SubViewport/ColorRect

var state

func open() -> void:
	fog_ref.open()

func close() -> void:
	fog_ref.close()
