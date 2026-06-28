## Mundo persistente en runtime: estados de objetos, inventario, apariencia y escena actual.
## Autoload. Es la "fuente de verdad"; SaveManager lo serializa. Nadie guarda directo en disco salvo SaveManager.
extends Node

## Se emite ante cualquier cambio guardable (dispara autosave en SaveManager).
signal changed
## Se emite cuando cambia la apariencia del personaje (lo escucha Character para reconstruirse).
signal character_changed

var object_states: Dictionary = {}     # object_id -> state_id
var inventory: Array = []              # [{ "id": String, "state": String }, ...]
var character_config: Dictionary = {}  # slot -> { "modulate": [r,g,b], "texture": path }
var current_scene_id: String = ""

func set_object_state(id: String, state_id: String) -> void:
	if id == "":
		return
	object_states[id] = state_id
	changed.emit()

func get_object_state(id: String, default_value: String = "") -> String:
	return object_states.get(id, default_value)

func add_to_inventory(entry: Dictionary) -> void:
	inventory.append(entry)
	changed.emit()

func remove_from_inventory(index: int) -> Dictionary:
	if index < 0 or index >= inventory.size():
		return {}
	var e: Dictionary = inventory[index]
	inventory.remove_at(index)
	changed.emit()
	return e

func set_character_slot(slot: String, config: Dictionary) -> void:
	character_config[slot] = config
	character_changed.emit()
	changed.emit()

func set_current_scene(id: String) -> void:
	current_scene_id = id
	changed.emit()

func clear() -> void:
	object_states.clear()
	inventory.clear()
	character_config.clear()
	current_scene_id = ""

func to_dict() -> Dictionary:
	return {
		"object_states": object_states,
		"inventory": inventory,
		"character_config": character_config,
		"current_scene_id": current_scene_id,
	}

func from_dict(d: Dictionary) -> void:
	object_states = d.get("object_states", {})
	inventory = d.get("inventory", [])
	character_config = d.get("character_config", {})
	current_scene_id = d.get("current_scene_id", "")
