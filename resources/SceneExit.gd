## Una zona de salida que lleva a otra escena. La usa SceneEngine + SceneRouter (Fases 2/3).
class_name SceneExit
extends Resource

## Centro de la zona de salida.
@export var area_position: Vector2 = Vector2.ZERO

## Tamaño del área (hitbox generosa para móvil).
@export var area_size: Vector2 = Vector2(160, 160)

## Id de la escena destino (SceneData.id).
@export var target_scene_id: String = ""
