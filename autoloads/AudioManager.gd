## Música ambiente + SFX con pooling, mute y gate de audio web.
## Autoload (singleton). Los objetos lo llaman por señal indirecta vía este global; no lo conocen al revés.
extends Node

var muted := false
var unlocked := false

var _music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _pool_size := 8
var _next := 0

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	add_child(_music)
	for i in _pool_size:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)

## Llamar desde un gesto del usuario (gate web). En navegador el audio no arranca sin interacción.
func unlock() -> void:
	unlocked = true

func play_sfx(stream: AudioStream) -> void:
	if muted or stream == null:
		return
	var p := _sfx_pool[_next]
	_next = (_next + 1) % _pool_size
	p.stream = stream
	p.play()

func play_music(stream: AudioStream, loop := true) -> void:
	if stream == null:
		_music.stop()
		return
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	_music.stream = stream
	if not muted:
		_music.play()

func set_muted(value: bool) -> void:
	muted = value
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), value)

func toggle_muted() -> bool:
	set_muted(not muted)
	return muted
