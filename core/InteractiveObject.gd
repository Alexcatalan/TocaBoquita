## Node2D genérico que ejecuta un ObjectData: sprite + Area2D + StateMachine.
## NADA hardcodeado por id. Tap -> avanza estado (textura/color + sonido + squash). Drag si procede.
## Construye sus hijos por código para que el .tscn sea trivial y robusto.
class_name InteractiveObject
extends Node2D

signal state_changed(object_id: String, state_id: String)
signal dropped_on(zone_id: String, object_id: String)  # Fase 2/3 (DropZone)

## Datos del objeto. Asignar ANTES de add_child (o desde el .tscn / SceneEngine).
@export var data: ObjectData

var _sprite: Sprite2D
var _area: Area2D
var _shape: RectangleShape2D
var _machine: StateMachine
var _draggable: Draggable
var _placeholder: Texture2D

func _ready() -> void:
	_build()
	if data:
		_apply_data()

func _build() -> void:
	_placeholder = Placeholder.rounded_rect(Vector2i(170, 170), 40)

	_sprite = Sprite2D.new()
	add_child(_sprite)

	_area = Area2D.new()
	add_child(_area)
	var col := CollisionShape2D.new()
	_shape = RectangleShape2D.new()
	_shape.size = Vector2(180, 180)  # hitbox generosa por defecto (móvil)
	col.shape = _shape
	_area.add_child(col)

	_draggable = Draggable.new()
	add_child(_draggable)
	_draggable.setup(self, _area)
	_draggable.tapped.connect(_on_tapped)

func _apply_data() -> void:
	_draggable.can_drag = data.draggable
	_machine = StateMachine.new()
	_machine.configure(data.states, data.initial_state)
	_apply_state(_machine.current(), false)

func _on_tapped() -> void:
	if _machine == null or _machine.states.is_empty():
		_squash()  # nada que ciclar, pero responde al toque
		return
	_apply_state(_machine.advance(), true)

func _apply_state(state: StateDef, animate: bool) -> void:
	if state == null:
		_sprite.texture = _placeholder
		return
	_sprite.texture = state.texture if state.texture else _placeholder
	_sprite.modulate = state.modulate
	# Ajusta la hitbox al tamaño visible, con mínimo generoso para dedos.
	var tex_size := _sprite.texture.get_size() if _sprite.texture else Vector2(180, 180)
	_shape.size = tex_size.max(Vector2(160, 160))
	if animate:
		_squash()
		AudioManager.play_sfx(state.sound)
	state_changed.emit(data.id, state.id)

# Feedback inmediato: squash & stretch para que el toque "se sienta".
func _squash() -> void:
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale = Vector2(1.12, 0.88)
	t.tween_property(self, "scale", Vector2.ONE, 0.28)
