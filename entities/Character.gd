## Personaje jugable: niño/a por capas (cuerpo, piel, pelo, cara) dibujadas con Art.
## Arrastrable, con sombra de contacto, respiración idle y wobble al levantarlo.
## El Wardrobe (GameState) recolorea los slots y el personaje se reconstruye solo.
class_name Character
extends Node2D

## Colores/base por slot (opcional). Si null, se usan colores por defecto.
@export var data: CharacterData

## Si true, aplica overrides de apariencia desde GameState y escucha cambios del Wardrobe.
@export var use_game_state: bool = false

const DEF := {
	"piel": Color(1.0, 0.86, 0.74),
	"pelo": Color(0.45, 0.32, 0.26),
	"ropa": Color(0.66, 0.82, 0.95),
}

var _rig: Node2D
var _shadow: Sprite2D
var _area: Area2D
var _draggable: Draggable

func _ready() -> void:
	_shadow = Sprite2D.new()
	_shadow.texture = Art.shadow(150.0)
	_shadow.position = Vector2(0, 116)
	add_child(_shadow)

	_rig = Node2D.new()
	add_child(_rig)
	_build_parts()
	_build_input()
	_start_idle()
	if use_game_state:
		GameState.character_changed.connect(rebuild)

## Reconstruye las capas (tras un cambio en el Wardrobe).
func rebuild() -> void:
	for c in _rig.get_children():
		c.queue_free()
	_build_parts()

func _build_parts() -> void:
	_add_part("kid_body", _slot_color("ropa"), 0)
	_add_part("kid_skin", _slot_color("piel"), 1)
	_add_part("kid_hair", _slot_color("pelo"), 2)
	_add_part("kid_face", Color.WHITE, 3)

func _add_part(shape: String, color: Color, z: int) -> void:
	var s := Sprite2D.new()
	s.texture = Art.make(shape, color)
	s.z_index = z
	_rig.add_child(s)

func _slot_color(slot: String) -> Color:
	if use_game_state and GameState.character_config.has(slot):
		var cfg: Dictionary = GameState.character_config[slot]
		if cfg.has("modulate"):
			var m: Array = cfg["modulate"]
			return Color(m[0], m[1], m[2])
	if data:
		for l in data.layers:
			if l.slot == slot:
				return l.modulate
	return DEF.get(slot, Color.WHITE)

func _build_input() -> void:
	_area = Area2D.new()
	add_child(_area)
	var col := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 70
	shape.height = 230
	col.shape = shape
	col.position = Vector2(0, 20)
	_area.add_child(col)

	_draggable = Draggable.new()
	add_child(_draggable)
	_draggable.setup(self, _area)
	_draggable.drag_started.connect(_wobble)

# Respiración + leve flotación: el personaje "vive".
func _start_idle() -> void:
	var breath := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breath.tween_property(_rig, "scale", Vector2(1.0, 1.03), 1.2)
	breath.tween_property(_rig, "scale", Vector2(1.0, 1.0), 1.2)
	var bob := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(_rig, "position:y", -5.0, 1.2)
	bob.tween_property(_rig, "position:y", 0.0, 1.2)

func _wobble() -> void:
	var t := create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property(_rig, "rotation", 0.07, 0.08)
	t.tween_property(_rig, "rotation", -0.07, 0.12)
	t.tween_property(_rig, "rotation", 0.0, 0.1)
