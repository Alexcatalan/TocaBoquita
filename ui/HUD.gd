## HUD persistente: mute, volver al hub, abrir wardrobe e inventario portable.
## Desacoplado: lee SceneRouter/GameState; los objetos no lo conocen.
class_name HUD
extends CanvasLayer

const OBJECTS_DIR := "res://data/objects/%s.tres"

var _inventory_box: HBoxContainer
var _inventory_panel: Panel
var _wardrobe: Wardrobe

func _ready() -> void:
	layer = 50
	_build_top_buttons()
	_build_inventory()
	_wardrobe = Wardrobe.new()
	add_child(_wardrobe)
	_wardrobe.hide()
	GameState.changed.connect(refresh)
	refresh()

func _build_top_buttons() -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	bar.position = Vector2(-360, 20)
	add_child(bar)

	var home := _make_button("Casa")
	home.pressed.connect(func(): SceneRouter.go_to("hub"))
	bar.add_child(home)

	var wardrobe_btn := _make_button("Ropa")
	wardrobe_btn.pressed.connect(func(): _wardrobe.visible = not _wardrobe.visible)
	bar.add_child(wardrobe_btn)

	var mute := _make_button("Sonido")
	mute.pressed.connect(func(): mute.text = "Silencio" if AudioManager.toggle_muted() else "Sonido")
	bar.add_child(mute)

func _make_button(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", 26)
	b.custom_minimum_size = Vector2(108, 72)
	b.focus_mode = Control.FOCUS_NONE
	return b

func _build_inventory() -> void:
	# Marco-guía de la "mochila": coincide con SceneEngine.INVENTORY_RECT.
	_inventory_panel = Panel.new()
	_inventory_panel.position = SceneEngine.INVENTORY_RECT.position
	_inventory_panel.size = SceneEngine.INVENTORY_RECT.size
	_inventory_panel.modulate = Color(1, 1, 1, 0.5)
	_inventory_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_inventory_panel)

	_inventory_box = HBoxContainer.new()
	_inventory_box.add_theme_constant_override("separation", 8)
	_inventory_box.position = SceneEngine.INVENTORY_RECT.position + Vector2(12, 12)
	add_child(_inventory_box)

## Reconstruye el inventario visible. Llamado en cada cambio y al cambiar de escena.
func refresh() -> void:
	if _inventory_box == null:
		return
	for c in _inventory_box.get_children():
		c.queue_free()
	for i in GameState.inventory.size():
		var entry: Dictionary = GameState.inventory[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(90, 90)
		btn.focus_mode = Control.FOCUS_NONE
		btn.modulate = _color_for(entry.get("id", ""))
		var index := i
		btn.pressed.connect(func(): _take_out(index))
		_inventory_box.add_child(btn)

func _color_for(id: String) -> Color:
	var od := load(OBJECTS_DIR % id) as ObjectData
	if od and not od.states.is_empty():
		return od.states[0].modulate
	return Color.WHITE

# Saca un objeto del inventario y lo coloca en la escena actual.
func _take_out(index: int) -> void:
	var entry := GameState.remove_from_inventory(index)
	if entry.is_empty():
		return
	if SceneRouter.current_engine:
		SceneRouter.current_engine.spawn_from_catalog(entry.get("id", ""), entry.get("state", ""), Vector2(640, 360))
