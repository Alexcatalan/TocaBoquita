## Selector de apariencia del personaje. Escribe en GameState.character_config (por slot).
## El Character escucha GameState.character_changed y se reconstruye solo (desacoplado).
class_name Wardrobe
extends Control

# Paleta pastel por slot: el niño toca un color y la capa cambia. Con arte final,
# aquí se ofrecerían texturas en vez de colores (mismo flujo).
const PALETTE := {
	"piel": [Color(1.0, 0.86, 0.74), Color(0.95, 0.78, 0.62), Color(0.74, 0.56, 0.43), Color(0.55, 0.40, 0.30)],
	"pelo": [Color(0.45, 0.32, 0.26), Color(0.15, 0.12, 0.10), Color(0.95, 0.80, 0.45), Color(0.85, 0.35, 0.45)],
	"ropa": [Color(0.66, 0.82, 0.95), Color(0.95, 0.70, 0.78), Color(0.75, 0.92, 0.75), Color(0.95, 0.85, 0.55)],
}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(600, 520)
	panel.position = Vector2(-300, -260)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	for slot in PALETTE.keys():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var label := Label.new()
		label.text = String(slot)
		label.custom_minimum_size = Vector2(110, 0)
		label.add_theme_font_size_override("font_size", 26)
		row.add_child(label)
		for color in PALETTE[slot]:
			row.add_child(_swatch(slot, color))
		vbox.add_child(row)

	# Accesorio: gafas (ninguno + colores).
	var grow := HBoxContainer.new()
	grow.add_theme_constant_override("separation", 12)
	var glabel := Label.new()
	glabel.text = "gafas"
	glabel.custom_minimum_size = Vector2(110, 0)
	glabel.add_theme_font_size_override("font_size", 26)
	grow.add_child(glabel)
	grow.add_child(_accessory_none())
	for color in [Color(0.2, 0.2, 0.25), Color(0.9, 0.4, 0.5), Color(0.4, 0.6, 0.95)]:
		grow.add_child(_accessory(color))
	vbox.add_child(grow)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	var reset := Button.new()
	reset.text = "Reiniciar"
	reset.add_theme_font_size_override("font_size", 26)
	reset.focus_mode = Control.FOCUS_NONE
	reset.pressed.connect(_on_reset)
	buttons.add_child(reset)
	var close := Button.new()
	close.text = "Listo"
	close.add_theme_font_size_override("font_size", 28)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(hide)
	buttons.add_child(close)
	vbox.add_child(buttons)

func _accessory(color: Color) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(80, 80)
	b.focus_mode = Control.FOCUS_NONE
	b.modulate = color
	b.pressed.connect(func():
		GameState.set_character_slot("accesorio", {"on": true, "modulate": [color.r, color.g, color.b]})
	)
	return b

func _accessory_none() -> Button:
	var b := Button.new()
	b.text = "—"
	b.custom_minimum_size = Vector2(80, 80)
	b.add_theme_font_size_override("font_size", 28)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): GameState.set_character_slot("accesorio", {"on": false}))
	return b

# Reinicia el guardado y vuelve al hub con la apariencia por defecto.
func _on_reset() -> void:
	SaveManager.reset()
	hide()
	SceneRouter.go_to("hub")

func _swatch(slot: String, color: Color) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(80, 80)
	b.focus_mode = Control.FOCUS_NONE
	b.modulate = color
	b.pressed.connect(func():
		GameState.set_character_slot(slot, {"modulate": [color.r, color.g, color.b]})
	)
	return b
