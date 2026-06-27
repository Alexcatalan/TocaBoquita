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

func st(id: String, shape: String, color: Color, beep_freq: float = 0.0, particle: String = "", next_state: String = "") -> StateDef:
	var s := StateDef.new()
	s.id = id
	s.shape = shape
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
	# Colores naturales de cada objeto.
	var white_f := Color(0.96, 0.97, 1.0)
	var metal := Color(0.64, 0.66, 0.72)
	var steel := Color(0.82, 0.84, 0.9)
	var sky := Color(0.58, 0.8, 1.0)
	var nightsky := Color(0.26, 0.3, 0.5)
	var lampc := Color(1.0, 0.86, 0.5)
	var teddyc := Color(0.80, 0.6, 0.42)
	var clockc := Color(0.97, 0.95, 0.9)
	var petc := Color(0.86, 0.7, 0.5)

	# Cocina
	save_obj("refri", [st("cerrado", "fridge", white_f), st("abierto", "fridge_open", white_f, 300.0)])
	save_obj("estufa", [st("apagada", "stove", steel), st("encendida", "stove_on", steel, 200.0)])
	save_obj("olla", [st("vacia", "pot", metal), st("llena", "pot_full", metal)])
	save_obj("grifo", [st("cerrado", "faucet", steel), st("abierto", "faucet_on", steel, 520.0)])
	save_obj("ventana", [st("dia", "window_day", sky), st("noche", "window_night", nightsky)])
	save_obj("manzana", [st("roja", "apple", RED)], true, true, ["olla"])
	save_obj("pan", [st("pan", "bread", BROWN)], true, true, ["olla"])
	save_obj("zanahoria", [st("naranja", "carrot", ORANGE)], true, true, ["olla"])

	# Dormitorio
	save_obj("cama", [st("hecha", "bed", LBLUE), st("dormido", "bed_sleep", LBLUE, 220.0, "corazones")])
	save_obj("lampara", [st("apagada", "lamp", lampc), st("encendida", "lamp_on", lampc, 660.0, "estrellas")])
	save_obj("closet", [st("cerrado", "closet", BROWN), st("abierto", "closet_open", BROWN, 300.0)])
	save_obj("oso", [st("oso", "teddy", teddyc)], true, true, ["cama"])
	save_obj("bloque", [st("bloque", "block", RED)], true, true)
	save_obj("pelota_dorm", [st("pelota", "ball", GREEN)], true, true)
	save_obj("reloj", [st("tic", "clock", clockc), st("tac", "clock", clockc, 440.0)])

	# Baño
	save_obj("tina", [st("vacia", "tub", white_f), st("agua", "tub_water", white_f, 520.0), st("burbujas", "tub_bubbles", white_f, 600.0, "burbujas")])
	save_obj("espejo", [st("normal", "mirror", LBLUE), st("empanado", "mirror_fog", LBLUE)])
	save_obj("grifo_bano", [st("cerrado", "faucet", steel), st("abierto", "faucet_on", steel, 520.0)])
	save_obj("pasta", [st("pasta", "toothpaste", MINT)], true, true)
	save_obj("cepillo", [st("cepillo", "toothbrush", PINK)], true, true)
	save_obj("pato", [st("pato", "duck", YELLOW)], true, true, ["tina"])
	save_obj("toalla", [st("colgada", "towel", PINK), st("caida", "towel", RED)])

	# Parque
	save_obj("columpio", [st("quieto", "swing", BROWN), st("meciendose", "swing", BROWN, 300.0)])
	save_obj("tobogan", [st("vacio", "slide", ORANGE), st("usandose", "slide", ORANGE, 400.0, "estrellas")])
	save_obj("charco", [st("quieto", "puddle", BLUE), st("salpicando", "puddle_splash", BLUE, 520.0, "burbujas")])
	save_obj("mascota", [st("feliz", "pet", petc, 350.0, "corazones")], true, false)
	save_obj("arbol", [st("verano", "tree", GREEN), st("otono", "tree", ORANGE)])
	save_obj("flor", [st("cerrada", "flower", GREEN), st("abierta", "flower_open", PINK, 700.0, "corazones")])
	save_obj("pelota", [st("pelota", "ball", RED)], true, true)

	# Fiesta
	save_obj("torta", [st("apagada", "cake", Color(1.0, 0.88, 0.78)), st("velas", "cake_lit", Color(1.0, 0.88, 0.78), 500.0, "estrellas")])
	save_obj("globo1", [st("inflado", "balloon", RED), st("estallado", "balloon_pop", RED, 900.0, "confeti")])
	save_obj("globo2", [st("inflado", "balloon", BLUE), st("estallado", "balloon_pop", BLUE, 900.0, "confeti")])
	save_obj("regalo1", [st("cerrado", "gift", PINK), st("abierto", "gift_open", PINK, 500.0, "confeti")])
	save_obj("regalo2", [st("cerrado", "gift", GREEN), st("abierto", "gift_open", GREEN, 500.0, "confeti")])
	save_obj("canon", [st("listo", "cannon", PINK), st("disparado", "cannon_fire", PINK, 800.0, "confeti")])
	save_obj("gorro", [st("gorro", "hat", PINK)], true, true)

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
