## Arranque: muestra el gate de audio ("toca para empezar") y al primer toque
## desbloquea el AudioServer (requisito de los navegadores) y arranca el SceneRouter,
## que carga la última escena guardada (o el hub).
extends Node2D

var _overlay: CanvasLayer

func _ready() -> void:
	_overlay = CanvasLayer.new()
	add_child(_overlay)

	var bg := ColorRect.new()
	bg.color = Color(0.98, 0.91, 0.86)  # pastel cálido
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(bg)

	var btn := Button.new()
	btn.text = "▶  toca para empezar"
	btn.add_theme_font_size_override("font_size", 48)
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	_overlay.add_child(btn)
	btn.pressed.connect(_start)

func _start() -> void:
	AudioManager.unlock()
	_overlay.queue_free()  # quita el gate; el router monta la escena sobre la raíz
	SceneRouter.start()
