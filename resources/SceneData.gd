## Definición completa de un escenario. SceneEngine (Fase 2) lo lee y construye la escena en runtime.
## Para agregar una escena: nuevo .tres SceneData con fondo, objetos colocados y salidas.
class_name SceneData
extends Resource

## Identificador del escenario (ej: "cocina", "hub").
@export var id: String = ""

## Fondo. Si es null, se usa un color plano (background_color).
@export var background: Texture2D

## Color de fondo cuando no hay textura (placeholder pastel).
@export var background_color: Color = Color(0.96, 0.93, 0.88)

## Música ambiente del escenario.
@export var ambient_music: AudioStream

## Objetos colocados (objeto + posición).
@export var placed_objects: Array[PlacedObject] = []

## Zonas de salida a otras escenas.
@export var exits: Array[SceneExit] = []
