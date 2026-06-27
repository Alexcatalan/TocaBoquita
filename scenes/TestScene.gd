## Escena de prueba de la FASE 1:
##  - 1 InteractiveObject (lámpara) que cicla estados al tocarlo (color + sonido + squash).
##  - 1 personaje arrastrable.
##  - HUD mínimo con botón de mute.
##
## La lámpara intenta cargarse desde un .tres (data-driven). Si no existe / falla,
## se construye en código como fallback. En la Fase 2 TODO vendrá de SceneData .tres.
extends Node2D

func _ready() -> void:
	_build_background()
	_build_lamp()
	_build_character()
	_build_hud()

func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0.93, 0.96, 0.93)  # verde menta pastel
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # no robar los toques a los Area2D
	layer.add_child(bg)

func _build_lamp() -> void:
	var data := load("res://data/objects/lampara.tres") as ObjectData
	if data == null:
		data = _lamp_data_fallback()
	var io := InteractiveObject.new()
	io.data = data
	io.position = Vector2(420, 400)
	add_child(io)

func _lamp_data_fallback() -> ObjectData:
	var off := StateDef.new()
	off.id = "apagada"
	off.modulate = Color(0.78, 0.78, 0.84)  # gris pastel
	var on := StateDef.new()
	on.id = "encendida"
	on.modulate = Color(1.0, 0.91, 0.45)  # amarillo cálido
	on.sound = Placeholder.beep(660.0)
	var d := ObjectData.new()
	d.id = "lampara"
	d.draggable = false
	d.states = [off, on]
	return d

func _build_character() -> void:
	var c := Character.new()
	c.position = Vector2(880, 480)
	add_child(c)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var mute := Button.new()
	mute.text = "🔊"
	mute.add_theme_font_size_override("font_size", 36)
	mute.focus_mode = Control.FOCUS_NONE
	mute.position = Vector2(1180, 20)
	mute.size = Vector2(80, 80)
	layer.add_child(mute)
	mute.pressed.connect(func():
		mute.text = "🔇" if AudioManager.toggle_muted() else "🔊"
	)
