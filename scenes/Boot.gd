## Arranque: muestra el gate de audio ("toca para empezar") y al primer toque
## desbloquea el AudioServer (requisito de los navegadores) y carga la escena de prueba.
extends Node2D

const NEXT_SCENE := "res://scenes/TestScene.tscn"

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var bg := ColorRect.new()
	bg.color = Color(0.98, 0.91, 0.86)  # pastel cálido
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bg)

	var btn := Button.new()
	btn.text = "▶  toca para empezar"
	btn.add_theme_font_size_override("font_size", 48)
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	layer.add_child(btn)
	btn.pressed.connect(_start)

func _start() -> void:
	AudioManager.unlock()
	get_tree().change_scene_to_file(NEXT_SCENE)
