## Componente de entrada táctil/mouse para un Node2D.
## Distingue TAP de DRAG por umbral y emite señales. Reutilizable por objetos y personajes.
## Funciona en desktop y móvil gracias a emulate_touch<->mouse (ver project.godot).
class_name Draggable
extends Node

signal tapped
signal drag_started
signal dragged(global_pos: Vector2)
signal dropped(global_pos: Vector2)

## Si es false, solo emite `tapped` (objetos fijos que ciclan estados).
@export var can_drag: bool = true
## Distancia en px para considerar que es arrastre y no tap.
@export var drag_threshold: float = 12.0

var _target: Node2D
var _area: Area2D
var _pressing := false
var _dragging := false
var _press_pos := Vector2.ZERO
var _offset := Vector2.ZERO
var _orig_z := 0

## Conecta el componente: `target` es lo que se mueve; `area` recibe el primer toque.
func setup(target: Node2D, area: Area2D) -> void:
	_target = target
	_area = area
	_orig_z = target.z_index
	_area.input_event.connect(_on_area_input)

func _on_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_pressing = true
		_dragging = false
		_press_pos = _target.get_global_mouse_position()
		_offset = _target.global_position - _press_pos

func _input(event: InputEvent) -> void:
	if not _pressing:
		return
	if event is InputEventMouseMotion:
		var mpos := _target.get_global_mouse_position()
		if not _dragging and can_drag and mpos.distance_to(_press_pos) > drag_threshold:
			_dragging = true
			_target.z_index = 100
			drag_started.emit()
		if _dragging:
			_target.global_position = mpos + _offset
			dragged.emit(_target.global_position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_pressing = false
		if _dragging:
			_dragging = false
			_target.z_index = _orig_z
			dropped.emit(_target.global_position)
		else:
			tapped.emit()
