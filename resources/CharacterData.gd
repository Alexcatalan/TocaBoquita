## Definición de un personaje como composición de capas apiladas.
## Crear un personaje nuevo = nuevo .tres CharacterData con sus CharacterLayer.
class_name CharacterData
extends Resource

## Identificador del personaje (ej: "nina", "mascota").
@export var id: String = ""

## Capas que componen el personaje. Se dibujan ordenadas por z_index.
@export var layers: Array[CharacterLayer] = []
