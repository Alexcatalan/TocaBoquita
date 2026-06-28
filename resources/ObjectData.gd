## Definición de un objeto interactivo. Capa de datos: el motor (InteractiveObject) la ejecuta.
## Para crear un objeto nuevo: nuevo .tres de tipo ObjectData con sus StateDef. Sin tocar GDScript.
class_name ObjectData
extends Resource

## Identificador del objeto (ej: "lampara", "refri"). Usado para persistencia.
@export var id: String = ""

## ¿Se puede arrastrar con el dedo/mouse?
@export var draggable: bool = false

## ¿Se puede llevar a otra escena (inventario)? Fase 5.
@export var portable: bool = false

## Estados por los que cicla al tocarlo. Si está vacío, el objeto solo reacciona con squash.
@export var states: Array[StateDef] = []

## Ids de DropZones que aceptan este objeto al soltarlo encima. Fase 2/3.
@export var drop_targets: Array[String] = []

## Id del estado inicial. Si está vacío, arranca en states[0].
@export var initial_state: String = ""
