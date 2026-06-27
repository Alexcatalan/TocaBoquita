## Personaje compuesto por Sprite2D apilados según CharacterData.layers (z_index por capa).
## Arrastrable. El Wardrobe (Fase 4) intercambiará capas por slot.
class_name Character
extends Node2D

## Datos del personaje. Si es null, se construye un placeholder por defecto.
@export var data: CharacterData

var _area: Area2D
var _draggable: Draggable

func _ready() -> void:
	_build_layers()
	_build_input()

func _build_layers() -> void:
	var layers: Array = data.layers.duplicate() if data else _default_layers()
	layers.sort_custom(func(a, b): return a.z_index < b.z_index)
	for layer in layers:
		var s := Sprite2D.new()
		s.texture = layer.texture if layer.texture else _placeholder_for(layer.slot)
		s.modulate = layer.modulate
		s.z_index = layer.z_index
		s.position = _slot_offset(layer.slot)
		add_child(s)

func _build_input() -> void:
	_area = Area2D.new()
	add_child(_area)
	var col := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 90
	shape.height = 320
	col.shape = shape
	col.position = Vector2(0, -40)
	_area.add_child(col)

	_draggable = Draggable.new()
	add_child(_draggable)
	_draggable.setup(self, _area)

# --- Placeholders por defecto: una "niña" simple (cuerpo + cabeza). ---

func _default_layers() -> Array:
	var body := CharacterLayer.new()
	body.slot = "ropa"
	body.modulate = Color(0.66, 0.82, 0.95)  # azul pastel
	body.z_index = 0
	var head := CharacterLayer.new()
	head.slot = "piel"
	head.modulate = Color(1.0, 0.86, 0.74)  # piel pastel
	head.z_index = 1
	var hair := CharacterLayer.new()
	hair.slot = "pelo"
	hair.modulate = Color(0.45, 0.32, 0.26)  # café
	hair.z_index = 2
	return [body, head, hair]

func _placeholder_for(slot: String) -> Texture2D:
	match slot:
		"piel":
			return Placeholder.circle(150)
		"pelo":
			return Placeholder.rounded_rect(Vector2i(170, 110), 55)
		_:
			return Placeholder.rounded_rect(Vector2i(150, 200), 60)

func _slot_offset(slot: String) -> Vector2:
	match slot:
		"piel":
			return Vector2(0, -150)
		"pelo":
			return Vector2(0, -200)
		_:
			return Vector2(0, 0)
