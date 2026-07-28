extends Node2D

signal iniciar_minijuego(nivel: int)

var tramo_actual: PathFollow2D
var personaje: Node2D
var sprite_personaje: CanvasItem
var nodo_actual: int = 1

var nivel_completado_actual: bool = false
var esperando_inicio: bool = false

# ── Paleta unificada con TimerUI (reloj de "Tiempo restante") ──────────────────
const C_BEIGE        := Color("#E5C89E")
const C_ORANGE_BORDE  := Color("#E0B080")
const C_ORANGE_FUERTE := Color("#E07820")
const C_BLUE          := Color("#3E5F8F")
const C_WHITE         := Color("#FFFFFF")

# Colores usados por el panel de nivel / botón (renombrados para mantener
# compatibilidad con el resto del script, pero ahora con la misma paleta)
const COLOR_FONDO        := C_BEIGE
const COLOR_BORDE        := C_ORANGE_BORDE
const COLOR_TEXTO        := C_BLUE
const COLOR_BOTON        := C_BLUE
const COLOR_BOTON_HOVER  := Color("#4B71A8")   # azul un poco más claro
const COLOR_BOTON_PRESS  := Color("#324D73")   # azul un poco más oscuro
const COLOR_BOTON_TEXTO  := C_WHITE
# ────────────────────────────────────────────────────────────────────────────

var descripciones_nivel := {
	1: "Nivel 1: rescata los objetos buenos antes de que se acabe el tiempo.",
	2: "Nivel 2: cierra todas las llaves de agua antes de que se acabe el tiempo.",
	3: "Nivel 3: pon a prueba tus reflejos.",
	4: "Nivel 4: resuelve el acertijo del camino.",
	5: "Nivel 5: cuidado con los obstáculos.",
	6: "Nivel 6: la mitad del camino recorrido.",
	7: "Nivel 7: se pone interesante.",
	8: "Nivel 8: cerca del volcán, ten cuidado.",
	9: "Nivel 9: casi llegas a la meta.",
	10: "Nivel 10: el reto final."
}

# Qué escena de minijuego corresponde a cada nivel
var escenas_minijuego := {
	1: "res://Minigames/minigame_deluxe/mini_minigame_level1/FloodGame.tscn",
	2: "res://Minigames/minigame_deluxe/mini_minigame_level2/FaucetGame.tscn"
}

var conexiones = {
	1: {"derecha": {"path": "Background/Way1-2/PathFollow2D", "destino": 2, "invertido": false}},
	2: {
		"izquierda": {"path": "Background/Way1-2/PathFollow2D", "destino": 1, "invertido": true},
		"derecha": {"path": "Background/Way2-3/PathFollow2D", "destino": 3, "invertido": false}
	},
	3: {
		"izquierda": {"path": "Background/Way2-3/PathFollow2D", "destino": 2, "invertido": true},
		"derecha": {"path": "Background/Way3-4/PathFollow2D", "destino": 4, "invertido": false}
	},
	4: {
		"izquierda": {"path": "Background/Way3-4/PathFollow2D", "destino": 3, "invertido": true},
		"derecha": {"path": "Background/Way4-5/PathFollow2D", "destino": 5, "invertido": false}
	},
	5: {
		"izquierda": {"path": "Background/Way4-5/PathFollow2D", "destino": 4, "invertido": true},
		"derecha": {"path": "Background/Way5-6/PathFollow2D", "destino": 6, "invertido": false}
	},
	6: {
		"izquierda": {"path": "Background/Way5-6/PathFollow2D", "destino": 5, "invertido": true},
		"derecha": {"path": "Background/Way6-7/PathFollow2D", "destino": 7, "invertido": false}
	},
	7: {
		"izquierda": {"path": "Background/Way6-7/PathFollow2D", "destino": 6, "invertido": true},
		"derecha": {"path": "Background/Way7-8/PathFollow2D", "destino": 8, "invertido": false}
	},
	8: {
		"izquierda": {"path": "Background/Way7-8/PathFollow2D", "destino": 7, "invertido": true},
		"derecha": {"path": "Background/Way8-9/PathFollow2D", "destino": 9, "invertido": false}
	},
	9: {
		"izquierda": {"path": "Background/Way8-9/PathFollow2D", "destino": 8, "invertido": true},
		"derecha": {"path": "Background/Way9-10/PathFollow2D", "destino": 10, "invertido": false}
	},
	10: {
		"izquierda": {"path": "Background/Way9-10/PathFollow2D", "destino": 9, "invertido": true}
	}
}

var ui_capa: CanvasLayer
var panel_nivel: Panel
var label_nivel: Label
var boton_comenzar: Button

func _ready():
	tramo_actual = $"Background/Way1-2/PathFollow2D"
	tramo_actual.rotates = false
	personaje = tramo_actual.get_node("Character")
	sprite_personaje = _buscar_sprite(personaje)
	if sprite_personaje == null:
		push_warning("No se encontró ningún Sprite2D/AnimatedSprite2D dentro de Character")

	_crear_ui()

	iniciar_minijuego.connect(_on_iniciar_minijuego)

	_procesar_resultado_minijuego()

func _buscar_sprite(nodo: Node) -> CanvasItem:
	for hijo in nodo.get_children():
		if hijo is Sprite2D or hijo is AnimatedSprite2D:
			return hijo
	return null

func _procesar_resultado_minijuego():
	var resultado = GameState.consumir_resultado()

	if resultado == "gano":
		nodo_actual = GameState.nivel_actual
		nivel_completado_actual = true
		esperando_inicio = false
		panel_nivel.visible = false
	elif resultado == "perdio":
		nodo_actual = GameState.nivel_actual
		nivel_completado_actual = false
		_mostrar_ventanita(nodo_actual)
	else:
		_mostrar_ventanita(nodo_actual)

func _crear_ui():
	ui_capa = CanvasLayer.new()
	ui_capa.layer = 10
	add_child(ui_capa)

	# ── Panel del nivel: mismo lenguaje visual que el reloj de tiempo ──────────
	panel_nivel = Panel.new()
	panel_nivel.custom_minimum_size = Vector2(280, 150)
	panel_nivel.visible = false
	ui_capa.add_child(panel_nivel)

	var estilo_panel := StyleBoxFlat.new()
	estilo_panel.bg_color = COLOR_FONDO
	estilo_panel.border_color = COLOR_BORDE
	estilo_panel.set_border_width_all(4)
	estilo_panel.set_corner_radius_all(22)
	estilo_panel.content_margin_left = 18
	estilo_panel.content_margin_right = 18
	estilo_panel.content_margin_top = 16
	estilo_panel.content_margin_bottom = 16
	# sombra suave, igual de estilo "tarjeta" que el panel del reloj
	estilo_panel.shadow_color = Color(0, 0, 0, 0.25)
	estilo_panel.shadow_size = 6
	estilo_panel.shadow_offset = Vector2(0, 3)
	panel_nivel.add_theme_stylebox_override("panel", estilo_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	panel_nivel.add_child(vbox)

	label_nivel = Label.new()
	label_nivel.autowrap_mode = TextServer.AUTOWRAP_WORD
	label_nivel.add_theme_color_override("font_color", COLOR_TEXTO)
	label_nivel.add_theme_font_size_override("font_size", 17)
	label_nivel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label_nivel)

	# ── Botón "Empezar": azul del reloj sobre fondo beige, con estados claros ──
	boton_comenzar = Button.new()
	boton_comenzar.text = "▶  Empezar"
	boton_comenzar.custom_minimum_size = Vector2(0, 42)
	boton_comenzar.add_theme_font_size_override("font_size", 18)

	var estilo_boton := StyleBoxFlat.new()
	estilo_boton.bg_color = COLOR_BOTON
	estilo_boton.border_color = C_WHITE
	estilo_boton.set_border_width_all(3)
	estilo_boton.set_corner_radius_all(18)
	estilo_boton.shadow_color = Color(0, 0, 0, 0.2)
	estilo_boton.shadow_size = 4
	estilo_boton.shadow_offset = Vector2(0, 2)

	var estilo_boton_hover := estilo_boton.duplicate()
	estilo_boton_hover.bg_color = COLOR_BOTON_HOVER
	estilo_boton_hover.border_color = C_ORANGE_BORDE

	var estilo_boton_press := estilo_boton.duplicate()
	estilo_boton_press.bg_color = COLOR_BOTON_PRESS
	estilo_boton_press.shadow_size = 1
	estilo_boton_press.shadow_offset = Vector2(0, 1)

	var estilo_boton_focus := estilo_boton_hover.duplicate()
	estilo_boton_focus.border_color = C_ORANGE_FUERTE

	boton_comenzar.add_theme_stylebox_override("normal", estilo_boton)
	boton_comenzar.add_theme_stylebox_override("hover", estilo_boton_hover)
	boton_comenzar.add_theme_stylebox_override("pressed", estilo_boton_press)
	boton_comenzar.add_theme_stylebox_override("focus", estilo_boton_focus)
	boton_comenzar.add_theme_color_override("font_color", COLOR_BOTON_TEXTO)
	boton_comenzar.add_theme_color_override("font_hover_color", COLOR_BOTON_TEXTO)
	boton_comenzar.add_theme_color_override("font_pressed_color", COLOR_BOTON_TEXTO)
	boton_comenzar.pressed.connect(_on_boton_empezar_pressed)
	vbox.add_child(boton_comenzar)

func _mostrar_ventanita(nivel: int):
	esperando_inicio = true

	label_nivel.text = descripciones_nivel.get(nivel, "Nivel %d" % nivel)
	panel_nivel.visible = true

	var pos_personaje = personaje.global_position
	var camera = get_viewport().get_camera_2d()
	var pos_pantalla: Vector2
	if camera:
		pos_pantalla = pos_personaje - camera.get_screen_center_position() + get_viewport().get_visible_rect().size / 2.0
	else:
		pos_pantalla = pos_personaje

	panel_nivel.position = pos_pantalla + Vector2(60, -70)

func _on_boton_empezar_pressed():
	panel_nivel.visible = false
	esperando_inicio = false
	emit_signal("iniciar_minijuego", nodo_actual)

func _on_iniciar_minijuego(nivel: int):
	if escenas_minijuego.has(nivel):
		GameState.ir_a_minijuego(nivel, escenas_minijuego[nivel])
	else:
		push_warning("No hay minijuego configurado para el nivel %d" % nivel)

func nivel_completado(nivel: int):
	if nivel == nodo_actual:
		nivel_completado_actual = true

func _input(event):
	if esperando_inicio:
		return

	var direccion = ""
	if event.is_action_pressed("ui_right"):
		direccion = "derecha"
	elif event.is_action_pressed("ui_left"):
		direccion = "izquierda"
	else:
		return

	if not conexiones.has(nodo_actual) or not conexiones[nodo_actual].has(direccion):
		return

	var info = conexiones[nodo_actual][direccion]
	var es_avance = info["destino"] > nodo_actual

	if es_avance and not nivel_completado_actual:
		return

	var destino_path = get_node(info["path"])
	var nodo_destino = info["destino"]

	mover_por_tramo(destino_path, info["invertido"], 1.0, nodo_destino)
	nodo_actual = nodo_destino

	if sprite_personaje != null:
		if direccion == "izquierda":
			sprite_personaje.flip_h = true
		elif direccion == "derecha":
			sprite_personaje.flip_h = false
		if sprite_personaje.has_method("play"):
			sprite_personaje.play("Walk")

func mover_por_tramo(destino: PathFollow2D, invertido: bool = false, duracion: float = 1.0, nodo_destino: int = -1):
	destino.rotates = false
	personaje.reparent(destino)
	var inicio_ratio = 1.0 if invertido else 0.0
	var final_ratio = 0.0 if invertido else 1.0
	destino.progress_ratio = inicio_ratio
	tramo_actual = destino
	var tween = create_tween()
	tween.tween_property(destino, "progress_ratio", final_ratio, duracion)
	tween.tween_callback(func():
		if sprite_personaje != null and sprite_personaje.has_method("stop"):
			sprite_personaje.stop()
		if nodo_destino != -1:
			_mostrar_ventanita(nodo_destino)
	)
