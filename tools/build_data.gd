## Herramienta de autoría de contenido. Genera TODOS los .tres (objetos, personaje, escenas).
## Ejecutar con:  godot --headless -s res://tools/build_data.gd
## Los .tres resultantes son editables en el Inspector. Reejecutar regenera el contenido base.
extends SceneTree

# Paleta pastel reutilizable.
const GRAY := Color(0.78, 0.78, 0.84)
const LBLUE := Color(0.70, 0.85, 1.0)
const BLUE := Color(0.50, 0.70, 1.0)
const ORANGE := Color(1.0, 0.62, 0.32)
const GREEN := Color(0.62, 0.86, 0.62)
const YELLOW := Color(1.0, 0.92, 0.50)
const DARKBLUE := Color(0.32, 0.36, 0.60)
const RED := Color(0.95, 0.45, 0.45)
const BROWN := Color(0.80, 0.60, 0.40)
const PINK := Color(1.0, 0.70, 0.80)
const LAVENDER := Color(0.86, 0.82, 0.95)
const CREAM := Color(0.98, 0.94, 0.86)
const MINT := Color(0.88, 0.96, 0.90)

func _initialize() -> void:
	_ensure_dirs()
	_build_objects()
	_build_character()
	_build_scenes()
	print("=== Contenido generado en res://data/ ===")
	quit()

func _ensure_dirs() -> void:
	var d := DirAccess.open("res://")
	for sub in ["data", "data/objects", "data/characters", "data/scenes"]:
		if not d.dir_exists(sub):
			d.make_dir_recursive(sub)

# --- Helpers ---

func st(id: String, color: Color, beep_freq: float = 0.0, particle: String = "", next_state: String = "") -> StateDef:
	var s := StateDef.new()
	s.id = id
	s.modulate = color
	s.particle = particle
	s.next_state = next_state
	if beep_freq > 0.0:
		s.sound = Placeholder.beep(beep_freq, 0.10)
	return s

func save_obj(id: String, states: Array, draggable := false, portable := false, drop_targets: Array = []) -> void:
	var o := ObjectData.new()
	o.id = id
	o.draggable = draggable
	o.portable = portable
	var arr: Array[StateDef] = []
	for s in states:
		arr.append(s)
	o.states = arr
	var dt: Array[String] = []
	for x in drop_targets:
		dt.append(x)
	o.drop_targets = dt
	if not states.is_empty():
		o.initial_state = states[0].id
	ResourceSaver.save(o, "res://data/objects/%s.tres" % id)

func placed(id: String, pos: Vector2, scl := Vector2.ONE) -> PlacedObject:
	var p := PlacedObject.new()
	p.object_data = load("res://data/objects/%s.tres" % id)
	p.position = pos
	p.scale = scl
	return p

func dz(id: String, pos: Vector2, size: Vector2, accepts: Array, particle := "", beep := 0.0, target_id := "", target_state := "") -> DropZoneDef:
	var z := DropZoneDef.new()
	z.id = id
	z.position = pos
	z.size = size
	var a: Array[String] = []
	for x in accepts:
		a.append(x)
	z.accepts = a
	z.particle = particle
	if beep > 0.0:
		z.sound = Placeholder.beep(beep, 0.10)
	z.target_object_id = target_id
	z.target_state = target_state
	return z

func exit(pos: Vector2, size: Vector2, target: String, label: String, color: Color) -> SceneExit:
	var e := SceneExit.new()
	e.area_position = pos
	e.area_size = size
	e.target_scene_id = target
	e.label = label
	e.color = color
	return e

func save_scene(id: String, bg: Color, placed_list: Array, dz_list: Array, exit_list: Array, spawn_player := true, player_pos := Vector2(640, 580)) -> void:
	var sd := SceneData.new()
	sd.id = id
	sd.background_color = bg
	var po: Array[PlacedObject] = []
	for p in placed_list:
		po.append(p)
	sd.placed_objects = po
	var dzs: Array[DropZoneDef] = []
	for z in dz_list:
		dzs.append(z)
	sd.drop_zones = dzs
	var exs: Array[SceneExit] = []
	for e in exit_list:
		exs.append(e)
	sd.exits = exs
	sd.spawn_player = spawn_player
	sd.player_position = player_pos
	ResourceSaver.save(sd, "res://data/scenes/%s.tres" % id)

func layer(slot: String, color: Color, z: int) -> CharacterLayer:
	var l := CharacterLayer.new()
	l.slot = slot
	l.modulate = color
	l.z_index = z
	return l

# --- Objetos ---

func _build_objects() -> void:
	# Cocina
	save_obj("refri", [st("cerrado", GRAY), st("abierto", LBLUE, 300.0)])
	save_obj("estufa", [st("apagada", GRAY), st("encendida", ORANGE, 200.0)])
	save_obj("olla", [st("vacia", GRAY), st("llena", GREEN)])
	save_obj("grifo", [st("cerrado", GRAY), st("abierto", BLUE, 520.0, "burbujas")])
	save_obj("ventana", [st("dia", YELLOW), st("noche", DARKBLUE)])
	save_obj("manzana", [st("roja", RED)], true, true, ["olla"])
	save_obj("pan", [st("pan", BROWN)], true, true, ["olla"])
	save_obj("zanahoria", [st("naranja", ORANGE)], true, true, ["olla"])

	# Dormitorio
	save_obj("cama", [st("hecha", LBLUE), st("dormido", DARKBLUE, 220.0, "corazones")])
	save_obj("lampara", [st("apagada", GRAY), st("encendida", YELLOW, 660.0)])
	save_obj("closet", [st("cerrado", BROWN), st("abierto", CREAM, 300.0)])
	save_obj("oso", [st("oso", BROWN)], true, true, ["cama"])
	save_obj("bloque", [st("bloque", RED)], true, true)
	save_obj("pelota_dorm", [st("pelota", GREEN)], true, true)
	save_obj("reloj", [st("tic", GRAY), st("tac", LBLUE, 440.0)])

	# Baño
	save_obj("tina", [st("vacia", GRAY), st("agua", BLUE, 520.0), st("burbujas", LBLUE, 600.0, "burbujas")])
	save_obj("espejo", [st("normal", LBLUE), st("empanado", GRAY)])
	save_obj("grifo_bano", [st("cerrado", GRAY), st("abierto", BLUE, 520.0, "burbujas")])
	save_obj("pasta", [st("pasta", MINT)], true, true)
	save_obj("cepillo", [st("cepillo", PINK)], true, true)
	save_obj("pato", [st("pato", YELLOW)], true, true, ["tina"])
	save_obj("toalla", [st("colgada", PINK), st("caida", RED)])

	# Parque
	save_obj("columpio", [st("quieto", BROWN), st("meciendose", GREEN, 300.0)])
	save_obj("tobogan", [st("vacio", ORANGE), st("usandose", YELLOW, 400.0, "estrellas")])
	save_obj("charco", [st("quieto", BLUE), st("salpicando", LBLUE, 520.0, "burbujas")])
	save_obj("mascota", [st("feliz", BROWN, 350.0, "corazones")], true, false)
	save_obj("arbol", [st("verano", GREEN), st("otono", ORANGE)])
	save_obj("flor", [st("cerrada", GREEN), st("abierta", PINK, 700.0, "corazones")])
	save_obj("pelota", [st("pelota", RED)], true, true)

	# Fiesta
	save_obj("torta", [st("apagada", CREAM), st("velas", YELLOW, 500.0, "estrellas")])
	save_obj("globo1", [st("inflado", RED), st("estallado", GRAY, 900.0, "confeti")])
	save_obj("globo2", [st("inflado", BLUE), st("estallado", GRAY, 900.0, "confeti")])
	save_obj("regalo1", [st("cerrado", PINK), st("abierto", YELLOW, 500.0, "confeti")])
	save_obj("regalo2", [st("cerrado", GREEN), st("abierto", ORANGE, 500.0, "confeti")])
	save_obj("canon", [st("listo", PINK), st("disparado", YELLOW, 800.0, "confeti")])
	save_obj("gorro", [st("gorro", PINK)], true, true)

# --- Personaje ---

func _build_character() -> void:
	save_character_data("nina", [
		layer("ropa", Color(0.66, 0.82, 0.95), 0),
		layer("piel", Color(1.0, 0.86, 0.74), 1),
		layer("pelo", Color(0.45, 0.32, 0.26), 2),
	])

func save_character_data(id: String, layers_data: Array) -> void:
	var cd := CharacterData.new()
	cd.id = id
	var ls: Array[CharacterLayer] = []
	for l in layers_data:
		ls.append(l)
	cd.layers = ls
	ResourceSaver.save(cd, "res://data/characters/%s.tres" % id)

# --- Escenas ---

func _build_scenes() -> void:
	_scene_hub()
	_scene_cocina()
	_scene_dormitorio()
	_scene_bano()
	_scene_parque()
	_scene_fiesta()

func _scene_hub() -> void:
	var doors := [
		exit(Vector2(260, 260), Vector2(220, 180), "cocina", "Cocina", ORANGE),
		exit(Vector2(640, 260), Vector2(220, 180), "dormitorio", "Dormitorio", LAVENDER),
		exit(Vector2(1020, 260), Vector2(220, 180), "bano", "Baño", LBLUE),
		exit(Vector2(420, 470), Vector2(220, 180), "parque", "Parque", GREEN),
		exit(Vector2(840, 470), Vector2(220, 180), "fiesta", "Fiesta", PINK),
	]
	# El hub es un menú: sin personaje (evita solaparse con las puertas).
	save_scene("hub", Color(0.95, 0.93, 0.98), [], [], doors, false)

func _scene_cocina() -> void:
	var objs := [
		placed("refri", Vector2(180, 360)),
		placed("estufa", Vector2(430, 380)),
		placed("olla", Vector2(430, 280)),
		placed("grifo", Vector2(680, 320)),
		placed("ventana", Vector2(980, 220)),
		placed("manzana", Vector2(820, 470)),
		placed("pan", Vector2(960, 470)),
		placed("zanahoria", Vector2(1100, 470)),
	]
	var zones := [
		dz("olla", Vector2(430, 280), Vector2(200, 200), ["manzana", "pan", "zanahoria"], "estrellas", 500.0, "olla", "llena"),
	]
	save_scene("cocina", CREAM, objs, zones, [], true, Vector2(640, 620))

func _scene_dormitorio() -> void:
	var objs := [
		placed("cama", Vector2(280, 380), Vector2(1.4, 1.0)),
		placed("lampara", Vector2(560, 300)),
		placed("closet", Vector2(820, 340)),
		placed("ventana", Vector2(1050, 240)),
		placed("reloj", Vector2(1050, 460)),
		placed("oso", Vector2(640, 560)),
		placed("bloque", Vector2(820, 580)),
		placed("pelota_dorm", Vector2(980, 580)),
	]
	var zones := [
		dz("cama", Vector2(280, 380), Vector2(280, 200), ["oso"], "corazones", 300.0, "cama", "dormido"),
	]
	save_scene("dormitorio", LAVENDER, objs, zones, [], true, Vector2(640, 640))

func _scene_bano() -> void:
	var objs := [
		placed("tina", Vector2(300, 400), Vector2(1.4, 1.0)),
		placed("espejo", Vector2(640, 250)),
		placed("grifo_bano", Vector2(520, 330)),
		placed("toalla", Vector2(880, 320)),
		placed("pasta", Vector2(760, 540)),
		placed("cepillo", Vector2(900, 540)),
		placed("pato", Vector2(1040, 540)),
	]
	var zones := [
		dz("tina", Vector2(300, 400), Vector2(280, 200), ["pato"], "burbujas", 600.0, "tina", "burbujas"),
	]
	save_scene("bano", Color(0.85, 0.94, 0.98), objs, zones, [], true, Vector2(680, 640))

func _scene_parque() -> void:
	var objs := [
		placed("columpio", Vector2(220, 360)),
		placed("tobogan", Vector2(450, 350)),
		placed("charco", Vector2(700, 520)),
		placed("arbol", Vector2(1050, 300), Vector2(1.3, 1.5)),
		placed("flor", Vector2(900, 560)),
		placed("mascota", Vector2(560, 580)),
		placed("pelota", Vector2(380, 580)),
	]
	save_scene("parque", Color(0.82, 0.95, 0.80), objs, [], [], true, Vector2(700, 640))

func _scene_fiesta() -> void:
	var objs := [
		placed("torta", Vector2(640, 380), Vector2(1.3, 1.3)),
		placed("globo1", Vector2(260, 280)),
		placed("globo2", Vector2(1020, 280)),
		placed("regalo1", Vector2(360, 560)),
		placed("regalo2", Vector2(920, 560)),
		placed("canon", Vector2(640, 600)),
		placed("gorro", Vector2(640, 200)),
	]
	save_scene("fiesta", Color(0.99, 0.90, 0.94), objs, [], [], true, Vector2(640, 660))
