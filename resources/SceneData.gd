## Definición completa de un escenario. SceneEngine (Fase 2) lo lee y construye la escena en runtime.
## Para agregar una escena: nuevo .tres SceneData con fondo, objetos colocados y salidas.
class_name SceneData
extends Resource

## Identificador del escenario (ej: "cocina", "hub").
@export var id: String = ""

## Fondo. Si es null, se usa un color plano (background_color).
@export var background: Texture2D

## Color de fondo cuando no hay textura (placeholder pastel). Se usa como "pared".
@export var background_color: Color = Color(0.96, 0.93, 0.88)

## Color del "piso" (banda inferior). Alpha 0 = derivar del fondo.
@export var floor_color: Color = Color(0, 0, 0, 0)

## Música ambiente del escenario.
@export var ambient_music: AudioStream

## Objetos colocados (objeto + posición).
@export var placed_objects: Array[PlacedObject] = []

## Zonas que aceptan objetos arrastrados (drag & drop).
@export var drop_zones: Array[DropZoneDef] = []

## Zonas de salida a otras escenas.
@export var exits: Array[SceneExit] = []

## ¿Aparece el personaje jugable en esta escena?
@export var spawn_player: bool = true

## Posición inicial del personaje jugable.
@export var player_position: Vector2 = Vector2(640, 540)
