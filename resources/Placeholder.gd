## Fábrica de placeholders por código: formas suaves pastel + un beep suave.
## Permite desarrollar TODO sin arte. Reemplazar placeholder -> arte final = poner Texture2D en el .tres.
class_name Placeholder
extends RefCounted

## Rectángulo redondeado BLANCO (se tiñe con modulate). Bordes con suavizado simple.
static func rounded_rect(size: Vector2i = Vector2i(160, 160), radius: int = 36) -> ImageTexture:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in size.y:
		for x in size.x:
			var a := _rounded_alpha(x, y, size, radius)
			if a > 0.0:
				img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

## Círculo BLANCO (se tiñe con modulate).
static func circle(diameter: int = 140) -> ImageTexture:
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var r := diameter * 0.5
	var c := Vector2(r, r)
	for y in diameter:
		for x in diameter:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			var a := clampf(r - d, 0.0, 1.0)  # 1px de suavizado
			if a > 0.0:
				img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

## Beep sintético corto (sine con decay). SFX placeholder para que nada se sienta "muerto".
static func beep(freq: float = 440.0, duration: float = 0.14, volume: float = 0.35) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / rate
		var env := 1.0 - float(i) / count  # decae a 0
		var s := sin(TAU * freq * t) * volume * env
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w

# Cobertura [0..1] de un pixel dentro de un rect de esquinas redondeadas (con 1px de suavizado).
static func _rounded_alpha(x: int, y: int, size: Vector2i, radius: int) -> float:
	var px := x + 0.5
	var py := y + 0.5
	var rad := float(clampi(radius, 0, mini(size.x, size.y) / 2))
	# Centro de la esquina más cercana.
	var cx := clampf(px, rad, size.x - rad)
	var cy := clampf(py, rad, size.y - rad)
	var d := Vector2(px, py).distance_to(Vector2(cx, cy))
	return clampf(rad - d, 0.0, 1.0) if d > 0.0 else 1.0
