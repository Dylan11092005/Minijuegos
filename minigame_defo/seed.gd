extends Area2D

var is_active = false
var start_position = Vector2.ZERO
var offset = Vector2.ZERO

# Más grande = más fácil sembrar en huecos buenos
@export var distancia_para_sembrar := 90.0

# Más grande = más fácil que detecte el hueco malo al soltar
# No afecta al pasar encima, solo al soltar
@export var distancia_para_hueco_malo := 55.0


func _ready():
	start_position = global_position
	z_index = 50
	monitoring = true
	monitorable = true


func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_active:
			is_active = true
			offset = global_position - get_global_mouse_position()
			z_index = 80


func _process(_delta):
	if is_active:
		global_position = get_global_mouse_position() + offset


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and is_active:
			revisar_donde_solto_semilla()
			desactivar_semilla()

		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and is_active:
			desactivar_semilla()


func revisar_donde_solto_semilla():
	# Primero revisa si la semilla está tocando un hueco malo al soltar
	var areas = get_overlapping_areas()

	for area in areas:
		if area.is_in_group("holes"):
			if area.current_state == area.State.INVALID:
				print("Semilla puesta en hueco malo por contacto")
				get_tree().call_group("game_manager", "recibir_dano_por_hueco_malo")
				return

	# Si no lo detectó por contacto, revisa por distancia
	var holes = get_tree().get_nodes_in_group("holes")

	var hueco_malo_cercano = null
	var distancia_malo_menor := 999999.0

	var hueco_bueno_cercano = null
	var distancia_bueno_menor := 999999.0

	for hole in holes:
		var distancia = global_position.distance_to(hole.global_position)

		if hole.current_state == hole.State.INVALID:
			if distancia < distancia_malo_menor:
				distancia_malo_menor = distancia
				hueco_malo_cercano = hole
		elif hole.current_state == hole.State.EMPTY:
			if distancia < distancia_bueno_menor:
				distancia_bueno_menor = distancia
				hueco_bueno_cercano = hole

	# Si soltaste cerca de un hueco malo, quita vida
	if hueco_malo_cercano != null and distancia_malo_menor <= distancia_para_hueco_malo:
		print("Semilla puesta en hueco malo por distancia")
		get_tree().call_group("game_manager", "recibir_dano_por_hueco_malo")
		return

	# Si no fue hueco malo, intenta sembrar en hueco bueno
	if hueco_bueno_cercano != null and distancia_bueno_menor <= distancia_para_sembrar:
		var sembrado = hueco_bueno_cercano.try_plant()

		if sembrado:
			print("Semilla plantada")
			return

	print("No se soltó sobre un hueco válido")


func desactivar_semilla():
	is_active = false
	global_position = start_position
	z_index = 50
