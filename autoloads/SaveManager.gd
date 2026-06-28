## Guarda/carga el mundo en user://save.json (en web persiste vía IndexedDB).
## Autosave con debounce: escucha GameState.changed y guarda tras una pausa breve.
extends Node

const SAVE_PATH := "user://save.json"

var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = 0.6
	_timer.timeout.connect(save_game)
	add_child(_timer)
	GameState.changed.connect(_on_state_changed)

func _on_state_changed() -> void:
	_timer.start()  # debounce: reinicia en cada cambio

func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("SaveManager: no se pudo abrir %s para escribir" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(GameState.to_dict()))
	f.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var txt := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(txt)
	if typeof(data) == TYPE_DICTIONARY:
		GameState.from_dict(data)
		return true
	return false

func reset() -> void:
	GameState.clear()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
