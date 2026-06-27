## Construye una escena COMPLETA desde un SceneData: fondo, objetos, drop zones, salidas y jugador.
## Es 100% genérico: ningún `if id == "..."`. Para agregar una escena se crea un SceneData .tres.
## Integra persistencia (GameState) y navegación (SceneRouter) por composición/señales.
class_name SceneEngine
extends Node2D

## Región de pantalla (coords de diseño 1280x720) que actúa como "mochila": soltar un
## objeto portable aquí lo guarda en el inventario. La dibuja el HUD en el mismo rect.
const INVENTORY_RECT := Rect2(24, 24, 320, 120)
const OBJECTS_DIR := "res://data/objects/%s.tres"

signal object_interacted(object_id: String, state_id: String)

var data: SceneData

var _objects: Dictionary = {}  # object_id -> InteractiveObject
var _player: Character

func _ready() -> void:
	if data:
		build(data)

func build(sd: SceneData) -> void:
	data = sd
	_clear()
	_build_background()
	_build_objects()
	_build_drop_zones()
	_build_exits()
	if sd.spawn_player:
		_build_player()

func get_object(id: String) -> InteractiveObject:
	return _objects.get(id)

func get_player() -> Character:
	return _player

# --- Construcción ---

func _clear() -> void:
	for c in get_children():
		c.queue_free()
	_objects.clear()
	_player = null

func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	if data.background:
		var s := TextureRect.new()
		s.texture = data.background
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(s)
		return

	var wall_col := data.background_color
	var floor_col := data.floor_color if data.floor_color.a > 0.0 else wall_col.darkened(0.12)

	# Pared con degradado vertical suave.
	var wall := TextureRect.new()
	wall.texture = _v_gradient(wall_col.lightened(0.06), wall_col)
	wall.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wall.stretch_mode = TextureRect.STRETCH_SCALE
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wall)

	# Luz suave radial arriba-centro.
	var glow := TextureRect.new()
	glow.texture = _radial(Color(1, 1, 1, 0.22))
	glow.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	glow.size = Vector2(900, 520)
	glow.position = Vector2(190, -120)
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(glow)

	# Piso (banda inferior) + línea de horizonte.
	var ground := ColorRect.new()
	ground.color = floor_col
	ground.anchor_top = 0.66
	ground.anchor_right = 1.0
	ground.anchor_bottom = 1.0
	ground.offset_left = 0
	ground.offset_right = 0
	ground.offset_bottom = 0
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ground)

	var horizon := ColorRect.new()
	horizon.color = Color(1, 1, 1, 0.12)
	horizon.anchor_top = 0.66
	horizon.anchor_right = 1.0
	horizon.offset_top = -3
	horizon.offset_bottom = 0
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(horizon)

func _v_gradient(top: Color, bottom: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, top)
	g.set_color(1, bottom)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 8
	t.height = 256
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	return t

func _radial(center: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, center)
	g.set_color(1, Color(center.r, center.g, center.b, 0.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 256
	t.height = 256
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t

func _build_objects() -> void:
	for po in data.placed_objects:
		if po == null or po.object_data == null:
			continue
		_spawn_placed(po.object_data, po.position, po.scale)

func _spawn_placed(od: ObjectData, pos: Vector2, scl: Vector2) -> InteractiveObject:
	var io := InteractiveObject.new()
	io.data = od
	io.position = pos
	io.scale = scl
	add_child(io)
	_objects[od.id] = io
	# Restaurar estado guardado.
	var saved := GameState.get_object_state(od.id)
	if saved != "":
		io.force_state(saved)
	# Persistir y propagar interacciones.
	io.state_changed.connect(_on_object_state_changed)
	io.dropped_on_zone.connect(_on_dropped_on_zone)
	if od.portable:
		io.dropped.connect(_on_portable_dropped)
	return io

func _build_drop_zones() -> void:
	for dz in data.drop_zones:
		if dz == null:
			continue
		var zone := DropZone.new()
		zone.setup(dz)
		add_child(zone)

func _build_exits() -> void:
	for ex in data.exits:
		if ex == null:
			continue
		var exit := Area2D.new()
		exit.position = ex.area_position
		var col := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = ex.area_size
		col.shape = rect
		exit.add_child(col)
		# Puerta visible (arte procedural) + etiqueta.
		var door := Sprite2D.new()
		door.texture = Art.make("door", ex.color)
		door.scale = ex.area_size / 200.0
		exit.add_child(door)
		if ex.label != "":
			var lbl := Label.new()
			lbl.text = ex.label
			lbl.add_theme_font_size_override("font_size", 30)
			lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.25))
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.size = ex.area_size
			lbl.position = -ex.area_size * 0.5
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			exit.add_child(lbl)
		# Una salida es tappable: al tocarla, viaja a la escena destino.
		var target := ex.target_scene_id
		exit.input_event.connect(func(_vp, event, _idx):
			if event is InputEventMouseButton and event.pressed:
				SceneRouter.go_to(target)
		)
		add_child(exit)

func _build_player() -> void:
	_player = Character.new()
	_player.position = data.player_position
	_player.use_game_state = true
	add_child(_player)

# --- Reacciones ---

func _on_object_state_changed(object_id: String, state_id: String) -> void:
	GameState.set_object_state(object_id, state_id)
	object_interacted.emit(object_id, state_id)

func _on_dropped_on_zone(zone: DropZone, obj: InteractiveObject) -> void:
	var d := zone.def
	AudioManager.play_sfx(d.sound)
	if d.particle != "":
		ParticleFactory.spawn(d.particle, obj.global_position)
	# Afecta a otro objeto (ej: olla -> "llena").
	if d.target_object_id != "" and _objects.has(d.target_object_id):
		_objects[d.target_object_id].force_state(d.target_state)
	# Destino del objeto soltado.
	if d.consume:
		obj.return_to_origin()  # vuelve para poder repetir el juego (infinito)
	elif d.return_to_origin:
		obj.return_to_origin()

func _on_portable_dropped(obj: InteractiveObject, global_pos: Vector2) -> void:
	if INVENTORY_RECT.has_point(global_pos):
		GameState.add_to_inventory({"id": obj.data.id, "state": GameState.get_object_state(obj.data.id)})
		AudioManager.play_sfx(Placeholder.beep(880.0, 0.08))
		_objects.erase(obj.data.id)
		obj.queue_free()

## Crea en la escena un objeto desde el catálogo por id (lo usa el inventario al sacar algo).
func spawn_from_catalog(id: String, state_id: String, pos: Vector2) -> void:
	var od := load(OBJECTS_DIR % id) as ObjectData
	if od == null:
		push_warning("SceneEngine: no existe el objeto '%s' en el catálogo" % id)
		return
	var io := _spawn_placed(od, pos, Vector2.ONE)
	if state_id != "":
		io.force_state(state_id)
