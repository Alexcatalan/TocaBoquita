## Area2D que acepta objetos arrastrados según un DropZoneDef.
## Solo DETECTA y describe qué acepta; la reacción la resuelve SceneEngine (data-driven).
class_name DropZone
extends Area2D

var def: DropZoneDef

func setup(d: DropZoneDef) -> void:
	def = d
	position = d.position
	monitorable = true
	monitoring = false  # no necesita detectar por sí misma; el objeto consulta solapamiento
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = d.size
	col.shape = rect
	add_child(col)

func accepts(object_id: String) -> bool:
	return object_id in def.accepts
