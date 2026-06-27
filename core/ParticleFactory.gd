## Pooling de efectos de partículas (corazones, burbujas, estrellas, confeti).
## Autoload. spawn(kind, global_pos) reutiliza emisores; no instancia/libera en cada toque.
## Sin cámara: las coords de mundo == coords de canvas, así que el posicionamiento es directo.
extends Node

const POOL_SIZE := 12

var _pool: Array[CPUParticles2D] = []
var _next := 0
var _dot: Texture2D

func _ready() -> void:
	_dot = Placeholder.circle(24)
	for i in POOL_SIZE:
		var p := CPUParticles2D.new()
		p.one_shot = true
		p.emitting = false
		p.texture = _dot
		p.amount = 14
		p.lifetime = 0.9
		p.explosiveness = 0.85
		p.direction = Vector2(0, -1)
		p.spread = 50.0
		p.gravity = Vector2(0, 220)
		p.initial_velocity_min = 120.0
		p.initial_velocity_max = 240.0
		p.scale_amount_min = 0.6
		p.scale_amount_max = 1.2
		add_child(p)
		_pool.append(p)

## Lanza un burst del efecto `kind` en la posición global dada.
func spawn(kind: String, global_pos: Vector2) -> void:
	if kind == "":
		return
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.global_position = global_pos
	_style(p, kind)
	p.restart()
	p.emitting = true

func _style(p: CPUParticles2D, kind: String) -> void:
	match kind:
		"corazones":
			p.color = Color(1.0, 0.45, 0.6)
			p.gravity = Vector2(0, -60)
		"burbujas":
			p.color = Color(0.6, 0.85, 1.0, 0.8)
			p.gravity = Vector2(0, -120)
		"estrellas":
			p.color = Color(1.0, 0.9, 0.4)
			p.gravity = Vector2(0, 120)
		"confeti":
			p.color = Color(1.0, 1.0, 1.0)
			p.color_ramp = _confetti_ramp()
			p.gravity = Vector2(0, 320)
		_:
			p.color = Color(1, 1, 1)
			p.gravity = Vector2(0, 220)

func _confetti_ramp() -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.5, 0.5))
	g.set_color(1, Color(0.5, 0.7, 1.0))
	g.add_point(0.5, Color(0.6, 1.0, 0.6))
	return g
