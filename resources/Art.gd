## Arte procedural: dibuja cada objeto como composición de primitivas suavizadas (antialias por
## supersampling + downscale Lanczos), con volumen suave. Devuelve Texture2D, cacheado por (forma,color).
##
## Es la capa de "arte placeholder de alta calidad": data-driven via `shape` + `modulate` en StateDef.
## Para arte final, basta asignar `texture` en el .tres (Art deja de usarse para ese estado).
class_name Art
extends RefCounted

const SIZE := 240
const SS := 2
const W := SIZE * SS

static var _cache: Dictionary = {}

static func make(shape: String, color: Color) -> Texture2D:
	var key := shape + "|" + color.to_html()
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(W, W, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw(img, shape, color)
	img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	_shade(img)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

## Sombra de contacto suave (elipse) para apoyar objetos/personaje en el suelo.
static func shadow(width := 180.0) -> Texture2D:
	var key := "shadow|%d" % int(width)
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(W, W, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_ellipse(img, SIZE / 2.0, SIZE / 2.0, width * 0.5, width * 0.16, Color(0, 0, 0, 0.22))
	img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

# ============================ Primitivas ============================

static func _p(img: Image, x: int, y: int, col: Color, cov: float) -> void:
	if cov <= 0.0 or x < 0 or y < 0 or x >= W or y >= W:
		return
	var a := cov * col.a
	if a <= 0.0:
		return
	var d := img.get_pixel(x, y)
	var ia := 1.0 - a
	img.set_pixel(x, y, Color(d.r * ia + col.r * a, d.g * ia + col.g * a, d.b * ia + col.b * a, d.a * ia + a))

static func _rr(img: Image, cx: float, cy: float, w: float, h: float, rad: float, col: Color) -> void:
	cx *= SS; cy *= SS; w *= SS; h *= SS; rad *= SS
	var hw := w * 0.5
	var hh := h * 0.5
	rad = minf(rad, minf(hw, hh))
	for y: int in range(int(cy - hh - 2), int(cy + hh + 2)):
		for x: int in range(int(cx - hw - 2), int(cx + hw + 2)):
			var qx := absf(x + 0.5 - cx) - (hw - rad)
			var qy := absf(y + 0.5 - cy) - (hh - rad)
			var d := Vector2(maxf(qx, 0.0), maxf(qy, 0.0)).length() + minf(maxf(qx, qy), 0.0) - rad
			_p(img, x, y, col, clampf(0.5 - d, 0.0, 1.0))

static func _circle(img: Image, cx: float, cy: float, r: float, col: Color) -> void:
	_ellipse(img, cx, cy, r, r, col)

static func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	cx *= SS; cy *= SS; rx *= SS; ry *= SS
	var edge := minf(rx, ry)
	for y: int in range(int(cy - ry - 2), int(cy + ry + 2)):
		for x: int in range(int(cx - rx - 2), int(cx + rx + 2)):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			var f := sqrt(dx * dx + dy * dy)
			_p(img, x, y, col, clampf((1.0 - f) * edge, 0.0, 1.0))

static func _seg(img: Image, ax: float, ay: float, bx: float, by: float, thick: float, col: Color) -> void:
	ax *= SS; ay *= SS; bx *= SS; by *= SS; thick *= SS
	var abx := bx - ax
	var aby := by - ay
	var l2 := abx * abx + aby * aby
	var t := thick * 0.5
	for y: int in range(int(minf(ay, by) - thick - 2), int(maxf(ay, by) + thick + 2)):
		for x: int in range(int(minf(ax, bx) - thick - 2), int(maxf(ax, bx) + thick + 2)):
			var px := x + 0.5 - ax
			var py := y + 0.5 - ay
			var tt := 0.0 if l2 == 0.0 else clampf((px * abx + py * aby) / l2, 0.0, 1.0)
			var dxx := px - abx * tt
			var dyy := py - aby * tt
			var d := sqrt(dxx * dxx + dyy * dyy) - t
			_p(img, x, y, col, clampf(0.5 - d, 0.0, 1.0))

static func _tri(img: Image, ax: float, ay: float, bx: float, by: float, cx: float, cy: float, col: Color) -> void:
	ax *= SS; ay *= SS; bx *= SS; by *= SS; cx *= SS; cy *= SS
	for y: int in range(int(minf(ay, minf(by, cy)) - 1), int(maxf(ay, maxf(by, cy)) + 2)):
		for x: int in range(int(minf(ax, minf(bx, cx)) - 1), int(maxf(ax, maxf(bx, cx)) + 2)):
			var cov := 0.0
			for sx: float in [0.25, 0.75]:
				for sy: float in [0.25, 0.75]:
					if _in_tri(x + sx, y + sy, ax, ay, bx, by, cx, cy):
						cov += 0.25
			_p(img, x, y, col, cov)

static func _in_tri(px: float, py: float, ax: float, ay: float, bx: float, by: float, cx: float, cy: float) -> bool:
	var d1 := (px - bx) * (ay - by) - (ax - bx) * (py - by)
	var d2 := (px - cx) * (by - cy) - (bx - cx) * (py - cy)
	var d3 := (px - ax) * (cy - ay) - (cx - ax) * (py - ay)
	var has_neg := d1 < 0.0 or d2 < 0.0 or d3 < 0.0
	var has_pos := d1 > 0.0 or d2 > 0.0 or d3 > 0.0
	return not (has_neg and has_pos)

# Volumen suave: gradiente vertical sutil donde hay opacidad.
static func _shade(img: Image) -> void:
	for y: int in SIZE:
		var f := lerpf(1.08, 0.9, float(y) / SIZE)
		for x: int in SIZE:
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				img.set_pixel(x, y, Color(minf(c.r * f, 1.0), minf(c.g * f, 1.0), minf(c.b * f, 1.0), c.a))

static func _face(img: Image, cx: float, cy: float, s: float, col_eye := Color(0.2, 0.18, 0.2)) -> void:
	_circle(img, cx - 11 * s, cy, 5 * s, Color.WHITE)
	_circle(img, cx + 11 * s, cy, 5 * s, Color.WHITE)
	_circle(img, cx - 11 * s, cy, 3 * s, col_eye)
	_circle(img, cx + 11 * s, cy, 3 * s, col_eye)
	_circle(img, cx - 20 * s, cy + 9 * s, 5 * s, Color(1, 0.6, 0.6, 0.5))
	_circle(img, cx + 20 * s, cy + 9 * s, 5 * s, Color(1, 0.6, 0.6, 0.5))
	# sonrisa
	for i: int in 9:
		var a := PI * (0.15 + 0.7 * i / 8.0)
		_circle(img, cx - cos(a) * 12 * s, cy + 8 * s + sin(a) * 6 * s, 1.6 * s, col_eye)

# ============================ Formas ============================

static func _draw(img: Image, shape: String, c: Color) -> void:
	match shape:
		"fridge": _fridge(img, c, false)
		"fridge_open": _fridge(img, c, true)
		"stove": _stove(img, c, false)
		"stove_on": _stove(img, c, true)
		"pot": _pot(img, c, false)
		"pot_full": _pot(img, c, true)
		"faucet": _faucet(img, c, false)
		"faucet_on": _faucet(img, c, true)
		"window_day": _window(img, c, false)
		"window_night": _window(img, c, true)
		"apple": _apple(img, c)
		"bread": _bread(img, c)
		"carrot": _carrot(img, c)
		"bed": _bed(img, c, false)
		"bed_sleep": _bed(img, c, true)
		"lamp": _lamp(img, c, false)
		"lamp_on": _lamp(img, c, true)
		"closet": _closet(img, c, false)
		"closet_open": _closet(img, c, true)
		"clock": _clock(img, c)
		"teddy": _teddy(img, c)
		"block": _block(img, c)
		"ball": _ball(img, c)
		"tub": _tub(img, c, 0)
		"tub_water": _tub(img, c, 1)
		"tub_bubbles": _tub(img, c, 2)
		"mirror": _mirror(img, c, false)
		"mirror_fog": _mirror(img, c, true)
		"toothbrush": _toothbrush(img, c)
		"toothpaste": _toothpaste(img, c)
		"duck": _duck(img, c)
		"towel": _towel(img, c)
		"swing": _swing(img, c)
		"slide": _slide(img, c)
		"puddle": _puddle(img, c, false)
		"puddle_splash": _puddle(img, c, true)
		"pet": _pet(img, c)
		"tree": _tree(img, c)
		"flower": _flower(img, c, false)
		"flower_open": _flower(img, c, true)
		"cake": _cake(img, c, false)
		"cake_lit": _cake(img, c, true)
		"balloon": _balloon(img, c)
		"balloon_pop": _balloon_pop(img, c)
		"gift": _gift(img, c, false)
		"gift_open": _gift(img, c, true)
		"cannon": _cannon(img, c, false)
		"cannon_fire": _cannon(img, c, true)
		"hat": _hat(img, c)
		"door": _door(img, c)
		"palm": _palm(img, c)
		"umbrella": _umbrella(img, c)
		"sandcastle": _sandcastle(img, c)
		"wave": _wave(img, c, false)
		"wave_splash": _wave(img, c, true)
		"bucket": _bucket(img, c)
		"starfish": _starfish(img, c)
		"crab": _crab(img, c)
		"sun": _sun(img, c)
		"kid_body": _kid_body(img, c)
		"kid_skin": _kid_skin(img, c)
		"kid_hair": _kid_hair(img, c)
		"kid_face": _kid_face(img, c)
		_: _blob(img, c)

static func _blob(img: Image, c: Color) -> void:
	_rr(img, 120, 122, 150, 150, 42, c)

static func _door(img: Image, c: Color) -> void:
	_rr(img, 120, 126, 156, 188, 26, c.darkened(0.12))
	_rr(img, 120, 126, 140, 172, 20, c)
	_rr(img, 120, 86, 104, 58, 14, c.lightened(0.08))
	_rr(img, 120, 168, 104, 64, 14, c.lightened(0.08))
	_circle(img, 168, 132, 7, c.darkened(0.3))

static func _fridge(img: Image, c: Color, open: bool) -> void:
	_rr(img, 120, 120, 118, 184, 22, c)
	if open:
		_rr(img, 120, 120, 92, 158, 14, c.darkened(0.16))
		_seg(img, 80, 96, 160, 96, 4, c.darkened(0.3))
		_seg(img, 80, 132, 160, 132, 4, c.darkened(0.3))
		_seg(img, 80, 168, 160, 168, 4, c.darkened(0.3))
		_rr(img, 110, 114, 28, 16, 4, Color(0.95, 0.5, 0.5))
		_rr(img, 130, 150, 30, 16, 4, Color(0.6, 0.8, 0.5))
	else:
		_seg(img, 66, 92, 174, 92, 4, c.darkened(0.16))
		_rr(img, 152, 70, 8, 26, 4, c.darkened(0.4))
		_rr(img, 152, 140, 8, 40, 4, c.darkened(0.4))

static func _stove(img: Image, c: Color, on: bool) -> void:
	_rr(img, 120, 142, 150, 112, 16, c)
	_rr(img, 120, 78, 150, 42, 12, c.darkened(0.08))
	_circle(img, 80, 78, 7, c.darkened(0.3))
	_circle(img, 120, 78, 7, c.darkened(0.3))
	_circle(img, 160, 78, 7, c.darkened(0.3))
	_circle(img, 85, 150, 28, c.darkened(0.18))
	_circle(img, 160, 150, 28, c.darkened(0.18))
	if on:
		_circle(img, 85, 150, 21, Color(1, 0.55, 0.2))
		_circle(img, 85, 150, 12, Color(1, 0.85, 0.3))
		_circle(img, 160, 150, 21, Color(1, 0.55, 0.2))
		_circle(img, 160, 150, 12, Color(1, 0.85, 0.3))
	else:
		_circle(img, 85, 150, 14, c.darkened(0.3))
		_circle(img, 160, 150, 14, c.darkened(0.3))

static func _pot(img: Image, c: Color, full: bool) -> void:
	_circle(img, 48, 120, 13, c.darkened(0.1))
	_circle(img, 192, 120, 13, c.darkened(0.1))
	_circle(img, 48, 120, 7, Color(0, 0, 0, 0))
	_circle(img, 192, 120, 7, Color(0, 0, 0, 0))
	_rr(img, 120, 150, 122, 84, 18, c)
	_rr(img, 120, 108, 142, 18, 9, c.lightened(0.12))
	if full:
		_ellipse(img, 120, 110, 58, 11, Color(0.62, 0.85, 0.5))
		_circle(img, 95, 80, 5, Color(1, 1, 1, 0.5))
		_circle(img, 120, 70, 6, Color(1, 1, 1, 0.45))
		_circle(img, 145, 82, 5, Color(1, 1, 1, 0.5))

static func _faucet(img: Image, c: Color, on: bool) -> void:
	_rr(img, 120, 172, 86, 30, 10, c)
	_seg(img, 118, 172, 118, 92, 13, c)
	_seg(img, 116, 92, 162, 92, 13, c)
	_seg(img, 162, 92, 162, 112, 13, c)
	_rr(img, 92, 80, 34, 11, 5, c.darkened(0.2))
	if on:
		_seg(img, 162, 114, 162, 184, 8, Color(0.5, 0.78, 1.0, 0.85))
		_circle(img, 162, 188, 7, Color(0.5, 0.78, 1.0, 0.7))

static func _window(img: Image, c: Color, night: bool) -> void:
	_rr(img, 120, 118, 158, 158, 18, Color(0.72, 0.56, 0.42))
	_rr(img, 120, 118, 138, 138, 8, c)
	if night:
		_circle(img, 158, 80, 17, Color(0.96, 0.95, 0.8))
		_circle(img, 150, 76, 17, c)
		_circle(img, 90, 90, 2.5, Color.WHITE)
		_circle(img, 100, 150, 2.5, Color.WHITE)
		_circle(img, 150, 150, 2.5, Color.WHITE)
	else:
		_circle(img, 158, 78, 18, Color(1, 0.85, 0.3))
		_ellipse(img, 95, 150, 30, 12, Color(1, 1, 1, 0.7))
	_seg(img, 120, 50, 120, 186, 7, Color(0.72, 0.56, 0.42))
	_seg(img, 52, 118, 188, 118, 7, Color(0.72, 0.56, 0.42))

static func _apple(img: Image, c: Color) -> void:
	_circle(img, 100, 132, 50, c)
	_circle(img, 140, 132, 50, c)
	_circle(img, 120, 142, 56, c)
	_seg(img, 120, 86, 126, 58, 6, Color(0.5, 0.35, 0.2))
	_ellipse(img, 142, 64, 18, 9, Color(0.5, 0.8, 0.4))
	_ellipse(img, 100, 116, 14, 20, Color(1, 1, 1, 0.25))

static func _bread(img: Image, c: Color) -> void:
	_ellipse(img, 120, 138, 82, 54, c)
	_ellipse(img, 120, 112, 80, 42, c.lightened(0.06))
	_seg(img, 92, 104, 108, 130, 4, c.darkened(0.18))
	_seg(img, 120, 100, 136, 126, 4, c.darkened(0.18))
	_seg(img, 148, 104, 164, 130, 4, c.darkened(0.18))

static func _carrot(img: Image, c: Color) -> void:
	_tri(img, 120, 212, 86, 112, 154, 112, c)
	_ellipse(img, 120, 114, 34, 14, c)
	_tri(img, 120, 104, 104, 60, 118, 100, Color(0.45, 0.75, 0.4))
	_tri(img, 120, 104, 120, 54, 132, 100, Color(0.5, 0.8, 0.45))
	_tri(img, 120, 104, 140, 64, 126, 100, Color(0.45, 0.75, 0.4))
	_seg(img, 104, 150, 112, 152, 3, c.darkened(0.2))
	_seg(img, 128, 168, 136, 170, 3, c.darkened(0.2))

static func _bed(img: Image, c: Color, sleep: bool) -> void:
	_rr(img, 120, 158, 176, 64, 12, c.darkened(0.08))
	_rr(img, 38, 120, 22, 86, 10, c.darkened(0.18))
	_rr(img, 120, 128, 158, 40, 12, c)
	_rr(img, 72, 120, 52, 30, 12, Color(0.99, 0.98, 0.95))
	_rr(img, 144, 134, 92, 36, 12, c.darkened(0.14))
	if sleep:
		_seg(img, 150, 70, 168, 70, 4, c.darkened(0.3))
		_seg(img, 168, 70, 150, 88, 4, c.darkened(0.3))
		_seg(img, 150, 88, 168, 88, 4, c.darkened(0.3))
		_seg(img, 174, 54, 186, 54, 3, c.darkened(0.3))
		_seg(img, 186, 54, 174, 66, 3, c.darkened(0.3))
		_seg(img, 174, 66, 186, 66, 3, c.darkened(0.3))

static func _lamp(img: Image, c: Color, on: bool) -> void:
	_ellipse(img, 120, 196, 38, 11, c.darkened(0.22))
	_seg(img, 120, 192, 120, 116, 7, c.darkened(0.12))
	if on:
		_circle(img, 120, 116, 46, Color(1, 0.95, 0.6, 0.45))
	_tri(img, 92, 116, 148, 116, 120, 74, c)
	_rr(img, 120, 116, 60, 10, 5, c.lightened(0.12) if on else c.darkened(0.05))

static func _closet(img: Image, c: Color, open: bool) -> void:
	_rr(img, 120, 120, 132, 186, 14, c)
	if open:
		_rr(img, 120, 120, 110, 162, 8, c.darkened(0.22))
		_seg(img, 74, 78, 166, 78, 4, c.lightened(0.2))
		_rr(img, 96, 110, 22, 50, 6, Color(0.9, 0.5, 0.55))
		_rr(img, 124, 116, 22, 56, 6, Color(0.5, 0.7, 0.9))
		_rr(img, 150, 110, 20, 48, 6, Color(0.6, 0.8, 0.5))
	else:
		_seg(img, 120, 38, 120, 202, 4, c.darkened(0.22))
		_circle(img, 106, 122, 6, c.darkened(0.35))
		_circle(img, 134, 122, 6, c.darkened(0.35))
	_rr(img, 92, 208, 14, 16, 4, c.darkened(0.2))
	_rr(img, 148, 208, 14, 16, 4, c.darkened(0.2))

static func _clock(img: Image, c: Color) -> void:
	_circle(img, 120, 120, 72, c.darkened(0.18))
	_circle(img, 120, 120, 63, c)
	for i: int in 12:
		var a := TAU * i / 12.0
		_circle(img, 120 + cos(a) * 54, 120 + sin(a) * 54, 3, c.darkened(0.35))
	_seg(img, 120, 120, 120, 84, 6, c.darkened(0.5))
	_seg(img, 120, 120, 150, 132, 5, c.darkened(0.5))
	_circle(img, 120, 120, 6, c.darkened(0.5))

static func _teddy(img: Image, c: Color) -> void:
	_circle(img, 82, 76, 22, c)
	_circle(img, 158, 76, 22, c)
	_circle(img, 82, 76, 11, c.darkened(0.18))
	_circle(img, 158, 76, 11, c.darkened(0.18))
	_circle(img, 120, 168, 56, c)
	_circle(img, 120, 96, 48, c)
	_ellipse(img, 120, 110, 26, 20, c.lightened(0.12))
	_circle(img, 120, 104, 6, c.darkened(0.5))
	_circle(img, 104, 90, 5, Color.WHITE)
	_circle(img, 136, 90, 5, Color.WHITE)
	_circle(img, 104, 90, 3, c.darkened(0.5))
	_circle(img, 136, 90, 3, c.darkened(0.5))

static func _block(img: Image, c: Color) -> void:
	_rr(img, 120, 130, 126, 126, 20, c)
	_rr(img, 120, 100, 110, 50, 16, c.lightened(0.08))
	_face(img, 120, 128, 1.0)
	_circle(img, 120, 78, 12, Color(1, 0.9, 0.4))

static func _ball(img: Image, c: Color) -> void:
	_circle(img, 120, 132, 62, c)
	_seg(img, 60, 132, 180, 132, 4, c.darkened(0.2))
	_ellipse(img, 120, 132, 30, 62, c.darkened(0.0))
	_seg(img, 120, 70, 120, 194, 4, c.darkened(0.2))
	_ellipse(img, 100, 110, 16, 20, Color(1, 1, 1, 0.25))

static func _tub(img: Image, c: Color, level: int) -> void:
	_circle(img, 58, 196, 10, c.darkened(0.2))
	_circle(img, 182, 196, 10, c.darkened(0.2))
	_rr(img, 120, 150, 172, 92, 42, c)
	_rr(img, 120, 150, 150, 70, 32, c.darkened(0.06))
	if level >= 1:
		_rr(img, 120, 152, 146, 56, 28, Color(0.5, 0.76, 1.0, 0.9))
	if level == 2:
		_circle(img, 80, 130, 12, Color(1, 1, 1, 0.85))
		_circle(img, 110, 122, 16, Color(1, 1, 1, 0.8))
		_circle(img, 145, 128, 13, Color(1, 1, 1, 0.85))
		_circle(img, 170, 134, 9, Color(1, 1, 1, 0.8))
	_rr(img, 120, 102, 60, 12, 6, c.lightened(0.1))

static func _mirror(img: Image, c: Color, fog: bool) -> void:
	_rr(img, 120, 118, 120, 168, 18, Color(0.78, 0.6, 0.42))
	_rr(img, 120, 118, 100, 148, 10, c)
	_seg(img, 95, 70, 75, 150, 8, Color(1, 1, 1, 0.3))
	_seg(img, 120, 60, 96, 160, 6, Color(1, 1, 1, 0.25))
	if fog:
		_rr(img, 120, 118, 100, 148, 10, Color(0.86, 0.9, 0.92, 0.6))

static func _toothbrush(img: Image, c: Color) -> void:
	_rr(img, 120, 150, 18, 116, 9, c)
	_rr(img, 120, 80, 32, 26, 8, c.lightened(0.12))
	_seg(img, 108, 70, 108, 60, 5, Color(0.6, 0.85, 1.0))
	_seg(img, 120, 68, 120, 56, 5, Color(0.6, 0.85, 1.0))
	_seg(img, 132, 70, 132, 60, 5, Color(0.6, 0.85, 1.0))

static func _toothpaste(img: Image, c: Color) -> void:
	_rr(img, 120, 144, 48, 116, 16, c)
	_rr(img, 120, 78, 26, 26, 6, Color(0.4, 0.7, 0.9))
	_ellipse(img, 120, 62, 15, 9, Color(0.5, 0.8, 0.92))
	_seg(img, 104, 150, 136, 150, 4, c.darkened(0.12))

static func _duck(img: Image, c: Color) -> void:
	_ellipse(img, 118, 150, 72, 48, c)
	_tri(img, 64, 132, 64, 166, 40, 150, c)
	_circle(img, 162, 110, 35, c)
	_tri(img, 186, 106, 214, 114, 186, 124, Color(1, 0.6, 0.2))
	_circle(img, 168, 100, 5, Color(0.2, 0.18, 0.2))
	_ellipse(img, 120, 152, 32, 18, c.darkened(0.08))

static func _towel(img: Image, c: Color) -> void:
	_rr(img, 120, 124, 112, 156, 12, c)
	_seg(img, 70, 170, 170, 170, 6, c.lightened(0.15))
	_seg(img, 70, 186, 170, 186, 6, c.lightened(0.15))
	_seg(img, 80, 48, 160, 48, 5, c.darkened(0.2))

static func _swing(img: Image, c: Color) -> void:
	_seg(img, 56, 58, 184, 58, 9, c.darkened(0.15))
	_seg(img, 60, 58, 40, 198, 9, c)
	_seg(img, 180, 58, 200, 198, 9, c)
	_seg(img, 98, 60, 98, 150, 4, c.darkened(0.4))
	_seg(img, 142, 60, 142, 150, 4, c.darkened(0.4))
	_rr(img, 120, 156, 70, 14, 6, c.lightened(0.12))

static func _slide(img: Image, c: Color) -> void:
	_seg(img, 64, 92, 64, 200, 8, c.darkened(0.15))
	_seg(img, 88, 92, 88, 200, 8, c.darkened(0.15))
	_seg(img, 64, 120, 88, 120, 5, c.darkened(0.15))
	_seg(img, 64, 150, 88, 150, 5, c.darkened(0.15))
	_seg(img, 64, 180, 88, 180, 5, c.darkened(0.15))
	_seg(img, 76, 88, 168, 110, 12, c)
	_seg(img, 168, 110, 180, 196, 12, c)
	_rr(img, 76, 86, 28, 10, 5, c.lightened(0.1))

static func _puddle(img: Image, c: Color, splash: bool) -> void:
	_ellipse(img, 120, 152, 92, 40, c)
	_ellipse(img, 120, 150, 60, 24, c.lightened(0.12))
	if splash:
		_circle(img, 70, 96, 8, Color(0.6, 0.85, 1.0))
		_circle(img, 120, 80, 10, Color(0.6, 0.85, 1.0))
		_circle(img, 170, 98, 8, Color(0.6, 0.85, 1.0))
		_circle(img, 95, 110, 5, Color(0.7, 0.9, 1.0))
		_circle(img, 150, 112, 5, Color(0.7, 0.9, 1.0))

static func _pet(img: Image, c: Color) -> void:
	_ellipse(img, 130, 152, 66, 44, c)
	_seg(img, 188, 140, 210, 112, 11, c)
	_circle(img, 74, 120, 38, c)
	_ellipse(img, 56, 98, 15, 26, c.darkened(0.14))
	_ellipse(img, 92, 98, 15, 26, c.darkened(0.14))
	_circle(img, 50, 128, 8, Color(0.2, 0.16, 0.16))
	_circle(img, 70, 110, 5, Color(0.2, 0.16, 0.16))
	_circle(img, 90, 112, 5, Color(0.2, 0.16, 0.16))
	_ellipse(img, 110, 196, 14, 8, c.darkened(0.1))
	_ellipse(img, 150, 196, 14, 8, c.darkened(0.1))

static func _tree(img: Image, c: Color) -> void:
	_rr(img, 120, 178, 28, 92, 8, Color(0.55, 0.4, 0.28))
	_circle(img, 120, 96, 56, c)
	_circle(img, 82, 122, 40, c)
	_circle(img, 158, 122, 40, c)
	_circle(img, 100, 84, 12, c.lightened(0.1))

static func _flower(img: Image, c: Color, open: bool) -> void:
	_seg(img, 120, 204, 120, 118, 8, Color(0.42, 0.72, 0.42))
	_ellipse(img, 146, 162, 22, 11, Color(0.45, 0.75, 0.45))
	if open:
		for i: int in 6:
			var a := TAU * i / 6.0
			_circle(img, 120 + cos(a) * 32, 104 + sin(a) * 32, 20, c)
		_circle(img, 120, 104, 22, Color(1, 0.85, 0.35))
	else:
		_ellipse(img, 120, 106, 22, 32, c)
		_ellipse(img, 120, 96, 12, 16, c.lightened(0.1))

static func _cake(img: Image, c: Color, lit: bool) -> void:
	_ellipse(img, 120, 198, 92, 16, Color(0.9, 0.9, 0.95))
	_rr(img, 120, 162, 144, 52, 12, c)
	_rr(img, 120, 120, 112, 48, 12, c.lightened(0.07))
	for i: int in 6:
		_circle(img, 76 + i * 18, 98, 9, Color(0.99, 0.98, 0.95))
	_seg(img, 90, 96, 90, 66, 5, Color(0.95, 0.8, 0.85))
	_seg(img, 120, 96, 120, 64, 5, Color(0.8, 0.9, 0.95))
	_seg(img, 150, 96, 150, 66, 5, Color(0.95, 0.9, 0.7))
	if lit:
		_ellipse(img, 90, 56, 6, 11, Color(1, 0.6, 0.2))
		_ellipse(img, 120, 54, 6, 11, Color(1, 0.6, 0.2))
		_ellipse(img, 150, 56, 6, 11, Color(1, 0.6, 0.2))
		_circle(img, 90, 58, 3, Color(1, 0.95, 0.6))
		_circle(img, 120, 56, 3, Color(1, 0.95, 0.6))
		_circle(img, 150, 58, 3, Color(1, 0.95, 0.6))

static func _balloon(img: Image, c: Color) -> void:
	_ellipse(img, 120, 110, 56, 66, c)
	_tri(img, 110, 172, 130, 172, 120, 184, c.darkened(0.1))
	_seg(img, 120, 184, 128, 224, 3, Color(0.4, 0.4, 0.45))
	_ellipse(img, 100, 88, 14, 20, Color(1, 1, 1, 0.3))

static func _balloon_pop(img: Image, c: Color) -> void:
	for i: int in 9:
		var a := TAU * i / 9.0
		_tri(img, 120, 120, 120 + cos(a) * 70, 120 + sin(a) * 70, 120 + cos(a + 0.3) * 40, 120 + sin(a + 0.3) * 40, c)
	_circle(img, 120, 120, 16, c.lightened(0.1))

static func _gift(img: Image, c: Color, open: bool) -> void:
	_rr(img, 120, 156, 122, 100, 10, c)
	_rr(img, 120, 156, 20, 100, 4, c.darkened(0.22))
	_rr(img, 120, 156, 122, 20, 4, c.darkened(0.22))
	if open:
		_rr(img, 120, 96, 134, 26, 8, c.lightened(0.08))
		_circle(img, 100, 70, 6, Color(1, 0.9, 0.5))
		_circle(img, 140, 66, 5, Color(0.7, 0.9, 1.0))
		_circle(img, 120, 60, 6, Color(0.9, 0.7, 1.0))
	else:
		_rr(img, 120, 100, 138, 26, 8, c.lightened(0.05))
		_circle(img, 106, 86, 12, c.darkened(0.15))
		_circle(img, 134, 86, 12, c.darkened(0.15))

static func _cannon(img: Image, c: Color, fire: bool) -> void:
	_tri(img, 92, 206, 148, 206, 122, 116, c)
	_rr(img, 120, 206, 64, 16, 6, c.darkened(0.15))
	if fire:
		_circle(img, 110, 80, 7, Color(0.95, 0.4, 0.5))
		_circle(img, 130, 70, 7, Color(0.4, 0.7, 1.0))
		_circle(img, 122, 56, 6, Color(0.6, 0.9, 0.5))
		_circle(img, 100, 64, 5, Color(1, 0.85, 0.4))
		_circle(img, 142, 84, 5, Color(0.9, 0.6, 1.0))

static func _hat(img: Image, c: Color) -> void:
	_tri(img, 120, 54, 80, 188, 160, 188, c)
	_seg(img, 100, 130, 140, 130, 6, c.lightened(0.18))
	_seg(img, 92, 162, 148, 162, 6, c.lightened(0.18))
	_circle(img, 120, 50, 13, Color(1, 1, 1))
	_ellipse(img, 120, 190, 44, 10, c.darkened(0.12))

# ---- Playa ----

static func _palm(img: Image, c: Color) -> void:
	_seg(img, 118, 214, 112, 150, 16, Color(0.62, 0.46, 0.3))
	_seg(img, 112, 150, 128, 92, 16, Color(0.62, 0.46, 0.3))
	for k: int in 5:
		var a := PI + 0.55 + k * (PI - 1.1) / 4.0
		_ellipse(img, 128 + cos(a) * 44, 90 + sin(a) * 30, 40, 15, c)
	_circle(img, 116, 104, 9, Color(0.5, 0.36, 0.24))
	_circle(img, 136, 106, 9, Color(0.5, 0.36, 0.24))

static func _umbrella(img: Image, c: Color) -> void:
	_seg(img, 120, 214, 120, 96, 7, Color(0.7, 0.7, 0.75))
	for k: int in 6:
		var x0 := 50.0 + k * 23.0
		var x1 := x0 + 23.0
		var col := c if k % 2 == 0 else Color(0.98, 0.98, 1.0)
		_tri(img, 120, 78, x0, 118 - sin(PI * (x0 - 50) / 140.0) * 8.0, x1, 118 - sin(PI * (x1 - 50) / 140.0) * 8.0, col)
	_circle(img, 120, 76, 6, c.darkened(0.2))

static func _sandcastle(img: Image, c: Color) -> void:
	_rr(img, 120, 176, 156, 64, 8, c)
	_rr(img, 78, 134, 38, 92, 6, c)
	_rr(img, 162, 134, 38, 92, 6, c)
	_rr(img, 120, 122, 46, 104, 6, c.lightened(0.04))
	for tx: int in [62, 78, 94]:
		_rr(img, tx, 86, 10, 14, 2, c)
	for tx2: int in [146, 162, 178]:
		_rr(img, tx2, 86, 10, 14, 2, c)
	_rr(img, 120, 188, 26, 40, 6, c.darkened(0.22))
	_seg(img, 120, 70, 120, 44, 4, Color(0.6, 0.6, 0.65))
	_tri(img, 120, 46, 148, 54, 120, 62, Color(0.95, 0.4, 0.45))

static func _wave(img: Image, c: Color, splash: bool) -> void:
	_ellipse(img, 120, 158, 98, 42, c)
	_ellipse(img, 120, 138, 88, 24, c.lightened(0.12))
	_ellipse(img, 86, 132, 26, 10, Color(1, 1, 1, 0.85))
	_ellipse(img, 150, 136, 22, 9, Color(1, 1, 1, 0.8))
	if splash:
		_circle(img, 78, 92, 8, Color(0.8, 0.92, 1.0))
		_circle(img, 120, 80, 10, Color(0.8, 0.92, 1.0))
		_circle(img, 162, 94, 8, Color(0.8, 0.92, 1.0))

static func _bucket(img: Image, c: Color) -> void:
	_tri(img, 76, 116, 164, 116, 150, 198, c)
	_tri(img, 76, 116, 150, 198, 90, 198, c)
	_rr(img, 120, 112, 100, 18, 9, c.lightened(0.12))
	for k: int in 14:
		var a := PI * (0.05 + 0.9 * k / 13.0)
		_circle(img, 120 - cos(a) * 52, 112 - sin(a) * 40, 3, c.darkened(0.2))

static func _starfish(img: Image, c: Color) -> void:
	var pts := []
	for k: int in 10:
		var a := -PI / 2.0 + TAU * k / 10.0
		var r := 70.0 if k % 2 == 0 else 30.0
		pts.append(Vector2(120 + cos(a) * r, 122 + sin(a) * r))
	for k: int in 10:
		_tri(img, 120, 122, pts[k].x, pts[k].y, pts[(k + 1) % 10].x, pts[(k + 1) % 10].y, c)
	for k: int in 5:
		var a2 := -PI / 2.0 + TAU * k / 5.0
		_circle(img, 120 + cos(a2) * 36, 122 + sin(a2) * 36, 4, c.darkened(0.18))

static func _crab(img: Image, c: Color) -> void:
	_ellipse(img, 120, 142, 64, 42, c)
	for sx: int in [-1, 1]:
		_seg(img, 120 + sx * 30, 110, 120 + sx * 42, 86, 4, c.darkened(0.1))
		_circle(img, 120 + sx * 42, 82, 9, Color.WHITE)
		_circle(img, 120 + sx * 42, 82, 5, Color(0.2, 0.18, 0.2))
		_circle(img, 120 + sx * 78, 150, 18, c)
		_circle(img, 120 + sx * 86, 138, 9, c)
		_seg(img, 120 + sx * 58, 150, 120 + sx * 78, 150, 7, c)
		for k: int in 3:
			_seg(img, 120 + sx * 40, 160 + k * 8, 120 + sx * 66, 168 + k * 10, 4, c.darkened(0.1))
	_circle(img, 108, 140, 4, Color(0.2, 0.18, 0.2))
	_circle(img, 132, 140, 4, Color(0.2, 0.18, 0.2))

static func _sun(img: Image, c: Color) -> void:
	for k: int in 12:
		var a := TAU * k / 12.0
		_seg(img, 120 + cos(a) * 62, 120 + sin(a) * 62, 120 + cos(a) * 88, 120 + sin(a) * 88, 7, c)
	_circle(img, 120, 120, 58, c)
	_circle(img, 100, 104, 14, c.lightened(0.12))

# ---- Personaje (capas alineadas en el mismo lienzo 240; se apilan por z) ----

static func _kid_body(img: Image, c: Color) -> void:
	_rr(img, 105, 210, 26, 46, 12, c.darkened(0.08))   # pierna izq
	_rr(img, 135, 210, 26, 46, 12, c.darkened(0.08))   # pierna der
	_ellipse(img, 104, 236, 18, 9, Color(0.34, 0.31, 0.37))  # zapato
	_ellipse(img, 136, 236, 18, 9, Color(0.34, 0.31, 0.37))
	_seg(img, 84, 138, 66, 186, 21, c)                 # brazo izq
	_seg(img, 156, 138, 174, 186, 21, c)               # brazo der
	_rr(img, 120, 158, 92, 98, 36, c)                  # torso
	_rr(img, 120, 122, 58, 14, 7, c.lightened(0.1))    # cuello de la ropa

static func _kid_skin(img: Image, c: Color) -> void:
	_circle(img, 64, 188, 13, c)                        # mano izq
	_circle(img, 176, 188, 13, c)                       # mano der
	_rr(img, 120, 126, 26, 22, 8, c)                    # cuello
	_circle(img, 76, 96, 10, c)                         # oreja izq
	_circle(img, 164, 96, 10, c)                        # oreja der
	_circle(img, 120, 94, 46, c)                        # cabeza

static func _kid_hair(img: Image, c: Color) -> void:
	_ellipse(img, 120, 58, 56, 34, c)
	_ellipse(img, 72, 78, 14, 24, c)
	_ellipse(img, 168, 78, 14, 24, c)
	_circle(img, 96, 84, 13, c)                         # flequillo
	_circle(img, 120, 86, 14, c)
	_circle(img, 144, 84, 13, c)
	_circle(img, 120, 36, 11, c)                        # mechón

static func _kid_face(img: Image, _c: Color) -> void:
	var dark := Color(0.26, 0.2, 0.22)
	_circle(img, 103, 99, 9, Color.WHITE)
	_circle(img, 137, 99, 9, Color.WHITE)
	_circle(img, 105, 101, 5, dark)
	_circle(img, 139, 101, 5, dark)
	_circle(img, 103, 98, 2, Color.WHITE)
	_circle(img, 137, 98, 2, Color.WHITE)
	_circle(img, 88, 114, 8, Color(1, 0.6, 0.62, 0.45))   # cachetes
	_circle(img, 152, 114, 8, Color(1, 0.6, 0.62, 0.45))
	for i: int in 9:                                       # sonrisa
		var t := i / 8.0
		_circle(img, lerpf(106, 134, t), 116 + sin(PI * t) * 8.0, 2.2, dark)
