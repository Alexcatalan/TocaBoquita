## Un objeto colocado en una escena: qué objeto y dónde. Lo usa SceneEngine (Fase 2).
class_name PlacedObject
extends Resource

## Definición del objeto a instanciar.
@export var object_data: ObjectData

## Posición en la escena.
@export var position: Vector2 = Vector2.ZERO

## Escala (reutilizar un mismo ObjectData a distinto tamaño).
@export var scale: Vector2 = Vector2.ONE
