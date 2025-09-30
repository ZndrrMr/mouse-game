extends Control

@export var icon_texture: Texture2D

@onready var icon = $TextureRect
@onready var label = $Label

func _ready():
	if icon_texture:
		icon.texture = icon_texture

func update_display(value: String):
	label.text = value
