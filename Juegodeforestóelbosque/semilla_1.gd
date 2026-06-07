extends Area2D

var arrastrando = false
var colocada = false
var regada = false
var offset = Vector2.ZERO

var imagen_semilla = preload("res://sprites/semilla1.png")
var imagen_semilla_puesta = preload("res://sprites/semilla_puesta.png")
var imagen_arbol = preload("res://sprites/arbol.png")

func _ready():
	$Sprite2D.texture = imagen_semilla
	z_index = 10
	monitoring = true
	monitorable = true

func _input_event(viewport, event, shape_idx):
	if colocada:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			arrastrando = true
			offset = global_position - get_global_mouse_position()
			z_index = 50

func _process(delta):
	if arrastrando and not colocada:
		global_position = get_global_mouse_position() + offset
		revisar_hueco()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			arrastrando = false
			z_index = 10

func revisar_hueco():
	for area in get_overlapping_areas():
		if area.is_in_group("hueco_bueno"):
			plantar(area)
			return

func plantar(hueco):
	arrastrando = false
	colocada = true
	
	global_position = hueco.global_position
	
	$Sprite2D.position = Vector2(360.0,1094.0)
	$Sprite2D.scale = Vector2(0, 0)
	$Sprite2D.texture = imagen_semilla_puesta
	
	add_to_group("semilla_colocada")
	z_index = 20
	
	
	
