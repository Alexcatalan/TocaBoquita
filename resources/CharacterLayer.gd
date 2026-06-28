## Una capa visual del personaje (piel, pelo, ropa...). El Wardrobe (Fase 4) intercambia capas por slot.
class_name CharacterLayer
extends Resource

## Slot lógico: "piel" | "pelo" | "ropa" | "accesorio" | "expresion".
@export var slot: String = ""

## Sprite de la capa. Si es null, se usa un placeholder de color (segun el slot).
@export var texture: Texture2D

## Tinte. Con placeholders ESTE color define la capa.
@export var modulate: Color = Color.WHITE

## Orden de apilado (mayor = encima).
@export var z_index: int = 0
