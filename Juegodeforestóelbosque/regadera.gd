extends Area2D

var is_active = false
var start_position = Vector2.ZERO

func _ready():
	start_position = global_position

func _input_event(_viewport, event, _shape_idx):
	# Si el jugador hace clic sobre la regadera, la activa como herramienta
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_active:
			is_active = true
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # Oculta el cursor normal

func _process(_delta):
	if is_active:
		# La regadera sigue al ratón de forma continua
		global_position = get_global_mouse_position()
		realizar_riego()

func _input(event):
	# Si presiona Clic Derecho, cancela la herramienta y la regresa a su sitio
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed && is_active:
			desactivar_regadera()

func realizar_riego():
	# Revisa qué áreas está tocando el pico de la regadera en este fotograma
	var areas = get_overlapping_areas()
	for area in areas:
		if area.is_in_group("holes"):
			# Llama a la función del hueco. Si tenía semilla, pasará a arbusto
			area.try_water()

func desactivar_regadera():
	is_active = false
	global_position = start_position
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Devuelve el cursor normal
