extends Node2D

@export var max_errors := 3

const PANEL_RESULTADO_SCENE = preload("res://ui_global/ResultadoJuego.tscn")

var total_items := 0
var placed_items := 0
var errors := 0
var game_active := false

var panel_resultado: CanvasLayer

@onready var targets = get_node_or_null("Targets")
@onready var items = get_node_or_null("Items")
@onready var errors_label = get_node_or_null("CanvasLayer/ErrorsLabel")
@onready var back_button = get_node_or_null("CanvasLayer/BackButton")


func _ready():
	game_active = true
	errors = 0
	placed_items = 0

	panel_resultado = PANEL_RESULTADO_SCENE.instantiate()
	add_child(panel_resultado)

	if items == null:
		print("No se encontró el nodo Items")
		return

	if targets == null:
		print("No se encontró el nodo Targets")
		return

	total_items = items.get_child_count()

	for item in items.get_children():
		if item is DraggableItem:
			item.dropped.connect(_on_item_dropped)

	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	else:
		print("No se encontró CanvasLayer/BackButton")

	_update_errors_label()


func _on_item_dropped(item: DraggableItem):
	if not game_active:
		return

	var correct_target := _get_correct_target(item)

	if correct_target != null:
		correct_target.occupied = true
		correct_target.show_placed_item()

		item.remove_from_game()

		placed_items += 1

		if placed_items >= total_items:
			_win()
	else:
		errors += 1
		_update_errors_label()

		item.return_to_start()

		if errors >= max_errors:
			_lose()


func _get_correct_target(item: DraggableItem) -> TargetSlot:
	var overlapping_areas = item.get_overlapping_areas()

	for area in overlapping_areas:
		if area is TargetSlot:
			var target := area as TargetSlot

			if target.occupied:
				continue

			if target.slot_id == item.item_id:
				return target

	return null


func _update_errors_label():
	if errors_label != null:
		errors_label.text = "Errores: " + str(errors) + "/" + str(max_errors)


func _win():
	game_active = false

	if items != null:
		for item in items.get_children():
			if item is DraggableItem:
				item.locked = true

	panel_resultado.mostrar_ganaste()


func _lose():
	game_active = false

	if items != null:
		for item in items.get_children():
			if item is DraggableItem:
				item.locked = true

	panel_resultado.mostrar_perdiste()


func _on_back_pressed():
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
