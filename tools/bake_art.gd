## Hornea TODAS las texturas de Art a PNG en res://assets/generated/ para runtime instantáneo.
## Ejecutar:  godot --headless -s res://tools/bake_art.gd   (luego: godot --headless --import)
## Enumera las combinaciones (forma,color,contorno) que el juego usa realmente.
extends SceneTree

# Debe coincidir con ui/Wardrobe.gd
const PALETTE := {
	"kid_skin": [Color(1.0, 0.86, 0.74), Color(0.95, 0.78, 0.62), Color(0.74, 0.56, 0.43), Color(0.55, 0.40, 0.30)],
	"kid_hair": [Color(0.45, 0.32, 0.26), Color(0.15, 0.12, 0.10), Color(0.95, 0.80, 0.45), Color(0.85, 0.35, 0.45)],
	"kid_body": [Color(0.66, 0.82, 0.95), Color(0.95, 0.70, 0.78), Color(0.75, 0.92, 0.75), Color(0.95, 0.85, 0.55)],
}
const GLASSES := [Color(0.2, 0.2, 0.25), Color(0.9, 0.4, 0.5), Color(0.4, 0.6, 0.95)]

func _initialize() -> void:
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("assets/generated"):
		dir.make_dir_recursive("assets/generated")

	var combos: Dictionary = {}  # path -> [shape, color, outline]
	var add := func(shape: String, color: Color, outline: bool):
		combos[Art.baked_path(shape, color, outline)] = [shape, color, outline]

	# Objetos (estados) y sus formas/colores.
	for f in DirAccess.get_files_at("res://data/objects"):
		if not f.ends_with(".tres"):
			continue
		var od := load("res://data/objects/" + f) as ObjectData
		if od == null:
			continue
		for s in od.states:
			add.call(s.shape, s.modulate, true)

	# Puertas (colores de salida del hub).
	for f in DirAccess.get_files_at("res://data/scenes"):
		if not f.ends_with(".tres"):
			continue
		var sd := load("res://data/scenes/" + f) as SceneData
		if sd == null:
			continue
		for ex in sd.exits:
			add.call("door", ex.color, true)

	# Personaje: capas con la paleta del wardrobe (con contorno) + cara/gafas (sin).
	for part in PALETTE:
		for c in PALETTE[part]:
			add.call(part, c, true)
	add.call("kid_face", Color.WHITE, false)
	for c in GLASSES:
		add.call("kid_glasses", c, false)

	for path in combos:
		var v: Array = combos[path]
		var img := Art.generate_image(v[0], v[1], v[2])
		var err := img.save_png(path)
		if err != OK:
			push_error("No se pudo guardar %s" % path)

	print("=== horneadas %d texturas en %s ===" % [combos.size(), Art.BAKED_DIR])
	quit()
