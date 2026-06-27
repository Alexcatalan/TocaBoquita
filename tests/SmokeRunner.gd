## Smoke test como ESCENA (autoloads activos). Ejecutar con:
##   godot --headless res://tests/SmokeRunner.tscn
## Valida comportamiento real. Sale con codigo !=0 si algo falla.
extends Node

var _failures: int = 0

func _ready() -> void:
	await get_tree().process_frame  # salir del _ready antes de añadir nodos de prueba
	print("=== SMOKE TEST ===")
	_run()
	await _test_router_flow()
	if _failures == 0:
		print("=== OK: todas las verificaciones pasaron ===")
	else:
		print("=== FALLOS: %d ===" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  [OK] ", msg)
	else:
		print("  [FAIL] ", msg)
		_failures += 1

func _run() -> void:
	_test_placeholders()
	_test_object_data()
	_test_state_machine()
	_test_interactive_object()
	_test_character()
	_test_scene_engine()
	_test_save_router()

func _test_placeholders() -> void:
	print("- Placeholder")
	var rr := Placeholder.rounded_rect(Vector2i(64, 64), 16)
	_check(rr != null and rr.get_width() == 64, "rounded_rect 64x64")
	var c := Placeholder.circle(48)
	_check(c != null and c.get_width() == 48, "circle 48")
	var b := Placeholder.beep(440.0, 0.05)
	_check(b != null and b.data.size() > 0, "beep genera datos")

func _test_object_data() -> void:
	print("- lampara.tres")
	var d := load("res://data/objects/lampara.tres") as ObjectData
	_check(d != null, "carga ObjectData desde .tres")
	if d:
		_check(d.id == "lampara", "id == lampara")
		_check(d.states.size() == 2, "tiene 2 estados")

func _test_state_machine() -> void:
	print("- StateMachine")
	var a := StateDef.new(); a.id = "a"
	var b := StateDef.new(); b.id = "b"
	var sm := StateMachine.new()
	sm.configure([a, b] as Array[StateDef], "b")
	_check(sm.current().id == "b", "initial_state respetado")
	_check(sm.advance().id == "a", "advance cicla a->...->a")

func _test_interactive_object() -> void:
	print("- InteractiveObject")
	var d := load("res://data/objects/lampara.tres") as ObjectData
	var io := InteractiveObject.new()
	io.data = d
	add_child(io)
	var seen := {"id": ""}
	io.state_changed.connect(func(_oid, sid): seen.id = sid)
	io._on_tapped()
	_check(seen.id == "encendida", "tap cambia apagada->encendida (got: %s)" % seen.id)
	io.queue_free()

func _test_character() -> void:
	print("- Character")
	var ch := Character.new()
	add_child(ch)
	var sprites := 0
	for c in ch.get_children():
		if c is Sprite2D:
			sprites += 1
	_check(sprites == 3, "personaje placeholder tiene 3 capas (got %d)" % sprites)
	ch.queue_free()

func _test_scene_engine() -> void:
	print("- SceneEngine + Cocina")
	var sd := load("res://data/scenes/cocina.tres") as SceneData
	_check(sd != null, "carga cocina.tres")
	if sd == null:
		return
	_check(sd.placed_objects.size() >= 6, "cocina tiene >=6 objetos (got %d)" % sd.placed_objects.size())
	var engine := SceneEngine.new()
	add_child(engine)
	engine.build(sd)
	var objs := 0
	for c in engine.get_children():
		if c is InteractiveObject:
			objs += 1
	_check(objs == sd.placed_objects.size(), "SceneEngine instancia todos los objetos (got %d)" % objs)
	engine.queue_free()

func _test_save_router() -> void:
	print("- GameState / SaveManager")
	GameState.set_object_state("test_obj", "abierto")
	_check(GameState.get_object_state("test_obj") == "abierto", "GameState guarda estado de objeto")
	SaveManager.save_game()
	_check(FileAccess.file_exists(SaveManager.SAVE_PATH), "SaveManager escribe el archivo")
	GameState.set_object_state("test_obj", "cerrado")
	SaveManager.load_game()
	_check(GameState.get_object_state("test_obj") == "abierto", "SaveManager restaura el estado")
	GameState.clear()

func _test_router_flow() -> void:
	print("- SceneRouter (navegación completa + HUD + jugador)")
	await SceneRouter.start()
	_check(SceneRouter.current_engine != null, "start() construye una escena")
	for id in ["cocina", "dormitorio", "bano", "parque", "fiesta", "hub"]:
		await SceneRouter.go_to(id)
		var eng := SceneRouter.current_engine
		_check(GameState.current_scene_id == id and eng != null and eng.get_child_count() > 0, "navega y construye '%s'" % id)
		if eng and eng.data.spawn_player:
			_check(eng.get_player() != null, "jugador presente en '%s'" % id)
