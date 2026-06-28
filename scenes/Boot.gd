## Arranque: pantalla "toca para empezar" (gate de audio del navegador). Al primer toque
## desbloquea el AudioServer y arranca el SceneRouter (carga la última escena o el hub).
extends Node2D

var _overlay: CanvasLayer

func _ready() -> void:
	_overlay = CanvasLayer.new()
	add_child(_overlay)

	var bg := ColorRect.new()
	bg.color = Color(0.99, 0.92, 0.88)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(bg)

	var title := Label.new()
	title.text = "TocaBoquita"
	title.add_theme_font_size_override("font_size", 92)
	title.add_theme_color_override("font_color", Color(0.45, 0.4, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(240, 150)
	title.size = Vector2(800, 120)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(title)

	var sub := Label.new()
	sub.text = "un mundo para jugar"
	sub.add_theme_font_size_override("font_size", 34)
	sub.add_theme_color_override("font_color", Color(0.62, 0.57, 0.64))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(240, 270)
	sub.size = Vector2(800, 50)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(sub)

	# Píldora "toca para empezar" con pulso.
	var pill := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.55, 0.78, 0.62)
	sb.set_corner_radius_all(46)
	sb.shadow_color = Color(0, 0, 0, 0.12)
	sb.shadow_size = 10
	pill.add_theme_stylebox_override("panel", sb)
	pill.position = Vector2(420, 430)
	pill.size = Vector2(440, 96)
	pill.pivot_offset = Vector2(220, 48)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(pill)

	var play := Label.new()
	play.text = "toca para empezar"
	play.add_theme_font_size_override("font_size", 36)
	play.add_theme_color_override("font_color", Color.WHITE)
	play.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	play.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	play.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(play)

	var pulse := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(pill, "scale", Vector2(1.05, 1.05), 0.7)
	pulse.tween_property(pill, "scale", Vector2(1.0, 1.0), 0.7)

	# Capa transparente que captura el toque en cualquier parte.
	var catch := Button.new()
	catch.flat = true
	catch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	catch.focus_mode = Control.FOCUS_NONE
	_overlay.add_child(catch)
	catch.pressed.connect(_start)

func _start() -> void:
	AudioManager.unlock()
	_overlay.queue_free()
	SceneRouter.start()
