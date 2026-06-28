## Música ambiental procedural: genera un loop suave y calmado por escena (sin assets, sin inflar .tres).
## Loop sin clicks: la duración es múltiplo entero de los "beats" y de la rejilla de frecuencias.
class_name MusicGen
extends RefCounted

const RATE := 22050
const DUR := 8.0  # segundos por loop

static var _cache: Dictionary = {}

# Pentatónica suave (Hz) por escena; cada escena tiene su "tono".
const ROOTS := {
	"hub": 261.63, "cocina": 293.66, "dormitorio": 220.0,
	"bano": 246.94, "parque": 329.63, "fiesta": 349.23, "playa": 392.0,
}
const SCALE := [1.0, 1.125, 1.25, 1.5, 1.6875]  # ratios pentatónicos

static func for_scene(id: String) -> AudioStreamWAV:
	if _cache.has(id):
		return _cache[id]
	var root: float = ROOTS.get(id, 261.63)
	var n := int(RATE * DUR)
	var data := PackedByteArray()
	data.resize(n * 2)
	var beats := 8  # notas del arpegio por loop
	for i in n:
		var t := float(i) / RATE
		# Pad suave: raíz + quinta + octava, con trémolo lento.
		var trem := 0.85 + 0.15 * sin(TAU * 0.125 * t)
		var pad := sin(TAU * root * t) + 0.5 * sin(TAU * root * 1.5 * t) + 0.4 * sin(TAU * root * 2.0 * t)
		# Arpegio calmado sobre la pentatónica.
		var beat := int(t / DUR * beats) % beats
		var note: float = root * float(SCALE[beat % SCALE.size()]) * 2.0
		var bt := fmod(t / DUR * beats, 1.0)
		var note_env := sin(PI * bt) * sin(PI * bt)  # campana por nota
		var arp := sin(TAU * note * t) * note_env
		var s := pad * 0.07 * trem + arp * 0.05
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	w.data = data
	_cache[id] = w
	return w
