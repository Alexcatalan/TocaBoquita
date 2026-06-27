## Un estado visual/sonoro de un objeto interactivo.
## Es CONTENIDO puro: el motor no sabe qué significa "encendida", solo aplica lo que aquí se declara.
class_name StateDef
extends Resource

## Identificador del estado (ej: "apagada", "encendida"). Único dentro del objeto.
@export var id: String = ""

## Sprite a mostrar en este estado. Si es null, se usa un placeholder de color.
@export var texture: Texture2D

## Tinte aplicado al sprite. Con placeholders (texture == null) ESTE color ES el objeto.
## Reemplazar placeholder -> arte final = poner la `texture`, sin tocar lógica.
@export var modulate: Color = Color.WHITE

## Nombre de animación a reproducir al ENTRAR a este estado (AnimationPlayer). Opcional.
@export var animation: String = ""

## SFX que suena al entrar a este estado. Opcional.
@export var sound: AudioStream

## Id de efecto de partícula a emitir al entrar ("corazones", "burbujas"...). Fase 5. Opcional.
@export var particle: String = ""

## A qué estado salta el siguiente tap. Si está vacío, cicla al siguiente del Array.
@export var next_state: String = ""
