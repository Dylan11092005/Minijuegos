extends Area2D

var arrastrando = false
var posicion_inicial

func _ready():
	posicion_inicial = global_position

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			arrastrando = event.pressed

func _process(delta):
	if arrastrando:
		global_position = get_global_mouse_position()
		revisar_semillas()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			arrastrando = false
			global_position = posicion_inicial

func revisar_semillas():
	for area in get_overlapping_areas():
		if area.is_in_group("semilla_colocada"):
			area.regar()
