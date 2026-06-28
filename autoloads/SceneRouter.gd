## Navegación entre escenas con fundido. Carga SceneData por convención (res://data/scenes/<id>.tres),
## construye un SceneEngine y mantiene un HUD persistente. Autoload.
extends Node

const SCENES_DIR := "res://data/scenes/%s.tres"

signal scene_changed(scene_id: String)

var current_engine: SceneEngine

var _root: Window
var _hud: HUD
var _fade: ColorRect
var _transitioning := false

func _ready() -> void:
	_root = get_tree().root

## Arranca el juego: carga el guardado, crea HUD y va a la última escena (o al hub).
func start() -> void:
	_setup_fade()
	if _hud == null:
		_hud = HUD.new()
		_root.add_child(_hud)
	SaveManager.load_game()
	var start_id := GameState.current_scene_id if GameState.current_scene_id != "" else "hub"
	await go_to(start_id)

func go_to(scene_id: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	await _fade_to(1.0)

	if current_engine and is_instance_valid(current_engine):
		current_engine.queue_free()
		current_engine = null

	var sd := load(SCENES_DIR % scene_id) as SceneData
	if sd == null:
		push_error("SceneRouter: no existe la escena '%s'" % scene_id)
		_transitioning = false
		await _fade_to(0.0)
		return

	current_engine = SceneEngine.new()
	_root.add_child(current_engine)
	current_engine.build(sd)  # construir ya en el árbol (no dentro de _ready)
	GameState.set_current_scene(scene_id)
	# Música: asset de la escena si existe; si no, loop ambiental procedural por escena.
	AudioManager.play_music(sd.ambient_music if sd.ambient_music else MusicGen.for_scene(scene_id))
	if _hud:
		_hud.refresh()

	await _fade_to(0.0)
	_transitioning = false
	scene_changed.emit(scene_id)

# --- Fundido ---

func _setup_fade() -> void:
	if _fade != null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 100
	_root.add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)

func _fade_to(alpha: float) -> void:
	if _fade == null:
		return
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP if alpha > 0.5 else Control.MOUSE_FILTER_IGNORE
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, 0.25)
	await t.finished
