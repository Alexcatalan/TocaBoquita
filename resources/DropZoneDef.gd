## Definición de una zona que acepta objetos arrastrados y dispara una reacción.
## 100% data-driven: el motor (SceneEngine) la lee; no hay reacciones hardcodeadas.
class_name DropZoneDef
extends Resource

## Id de la zona (debe coincidir con ObjectData.drop_targets para documentar la intención).
@export var id: String = ""

## Centro y tamaño del área (hitbox generosa).
@export var position: Vector2 = Vector2.ZERO
@export var size: Vector2 = Vector2(240, 240)

## Ids de objetos que esta zona acepta.
@export var accepts: Array[String] = []

## SFX y partícula al recibir un objeto aceptado.
@export var sound: AudioStream
@export var particle: String = ""

## El objeto vuelve a su posición original (juego infinito, estilo Toca Boca).
@export var return_to_origin: bool = true

## El objeto desaparece al soltarlo (ej: comérselo). Tiene prioridad sobre return_to_origin.
@export var consume: bool = false

## Opcional: afecta a OTRO objeto de la escena (ej: soltar comida en la olla -> olla "llena").
@export var target_object_id: String = ""
@export var target_state: String = ""
