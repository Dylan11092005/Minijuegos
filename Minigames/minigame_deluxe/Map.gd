extends Node2D

signal iniciar_minijuego(nivel: int)

var tramo_actual: PathFollow2D
var personaje: Node2D
var sprite_personaje: CanvasItem
var nodo_actual: int = 1

var esperando_inicio: bool = false

# Offset fijo del sprite del personaje respecto al origen del PathFollow2D
# (ajuste visual para que los pies queden sobre el camino). Se usa SIEMPRE
# el mismo valor tras cada reparent, para no arrastrar offsets corruptos
# por la rotación/posición del tramo anterior (ver reparent() más abajo).
const CHARACTER_OFFSET := Vector2(55.32758, 103.54468)

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
	4: "Nivel 4: cierra las ventanas antes de que se acabe el tiempo.",
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
	2: "res://Minigames/minigame_deluxe/mini_minigame_level2/FaucetGame.tscn",
	3: "res://Minigames/minigame_deluxe/mini_minigame_level3/FlameMain.tscn",
	4: "res://Minigames/minigame_deluxe/mini_minigame_level4/WindowsMain.tscn"
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

	# Seguro adicional: desactivamos "rotates" en TODOS los PathFollow2D del
	# mapa desde el arranque (no solo en el tramo actual), para que ningún
	# tramo pueda hacer rotar al personaje al pasar por su curva, sin
	# importar cómo se haya dibujado esa curva en el editor.
	_desactivar_rotacion_en_todos_los_tramos()

	print("[DEBUG] _ready() del Mapa -> nodo_actual (antes de procesar)=", nodo_actual)

	_crear_ui()

	iniciar_minijuego.connect(_on_iniciar_minijuego)

	_procesar_resultado_minijuego()

func _desactivar_rotacion_en_todos_los_tramos():
	var contenedor := get_node_or_null("Background")
	if contenedor == null:
		return

	for tramo_nodo in contenedor.get_children():
		if tramo_nodo.name.begins_with("Way"):
			var pf: PathFollow2D = tramo_nodo.get_node_or_null("PathFollow2D")
			if pf:
				pf.rotates = false

# Garantiza que el personaje SIEMPRE se vea igual (sin rotación), sin
# importar la curva del tramo por el que esté pasando en ese momento.
# Se fuerza cada frame porque es la única forma de blindarlo del todo,
# incluso si algún PathFollow2D quedó con "rotates" en true por error.
func _process(_delta):
	if personaje:
		personaje.global_rotation = 0.0

func _buscar_sprite(nodo: Node) -> CanvasItem:
	for hijo in nodo.get_children():
		if hijo is Sprite2D or hijo is AnimatedSprite2D:
			return hijo
	return null

func _procesar_resultado_minijuego():
	var resultado = GameState.consumir_resultado()
	print("[DEBUG] _procesar_resultado_minijuego -> resultado=", resultado,
		" | GameState.nivel_actual=", GameState.nivel_actual,
		" | GameState.tramo_guardado_path=", GameState.tramo_guardado_path,
		" | GameState.tramo_guardado_ratio=", GameState.tramo_guardado_ratio)

	if resultado == "gano":
		# El nivel ya quedó marcado como completado en GameState desde
		# volver_al_mapa_con_resultado(). Acá solo actualizamos la posición
		# y nos aseguramos de que el panel de "Empezar" no se muestre.
		nodo_actual = GameState.nivel_actual
		esperando_inicio = false
		_ubicar_personaje_en_nodo(nodo_actual)
		panel_nivel.visible = false
	elif resultado == "perdio":
		nodo_actual = GameState.nivel_actual
		_ubicar_personaje_en_nodo(nodo_actual)
		_entrar_a_nodo(nodo_actual)
	else:
		_ubicar_personaje_en_nodo(nodo_actual)
		_entrar_a_nodo(nodo_actual)

	print("[DEBUG] después de procesar -> nodo_actual=", nodo_actual,
		" | personaje.global_position=", personaje.global_position,
		" | tramo_actual=", tramo_actual.get_path() if tramo_actual else "null",
		" | tramo_actual.progress_ratio=", tramo_actual.progress_ratio if tramo_actual else "null")

# ── Reposiciona al personaje (sin animación) en su posición exacta de antes
# de entrar al minijuego. Necesario porque, al volver de un minijuego, Godot
# reinstancia la escena del mapa y "Character" siempre reaparece en su
# posición original dentro de la escena (Way1-2), sin importar cuánto
# camino se había recorrido antes de entrar al minijuego.
#
# En vez de adivinar en qué extremo (ratio 0.0 o 1.0) de un tramo está cada
# nodo -algo que depende de en qué sentido se dibujó cada Path2D en el
# editor y puede fallar-, usamos la posición exacta (tramo + progress_ratio)
# que se guardó en GameState justo antes de salir al minijuego.
func _ubicar_personaje_en_nodo(nivel: int):
	var path_str: String = GameState.tramo_guardado_path
	var ratio: float = GameState.tramo_guardado_ratio

	# Fallback para la primera carga del mapa (todavía no hay nada guardado):
	# el personaje empieza en el nodo 1, al inicio de Way1-2.
	if path_str == "":
		path_str = "Background/Way1-2/PathFollow2D"
		ratio = 0.0

	var tramo: PathFollow2D = get_node(path_str)
	tramo.rotates = false

	if personaje.get_parent() != tramo:
		# keep_global_transform=false: NO queremos que Godot "preserve" la
		# posición global (eso es lo que causaba el desfase de ~480px:
		# arrastraba un offset calculado con la rotación del tramo anterior).
		# En vez de eso, fijamos siempre el mismo offset conocido.
		personaje.reparent(tramo, false)
		personaje.position = CHARACTER_OFFSET
		personaje.rotation = 0

	tramo.progress_ratio = ratio
	tramo_actual = tramo

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

# Decide qué pasa al llegar/estar en un nodo: si el nivel ya fue completado
# antes, no se muestra el cartel de "Empezar" y el jugador queda libre para
# seguir moviéndose. Si todavía no se completó, se muestra la ventanita
# para jugarlo.
func _entrar_a_nodo(nivel: int):
	if GameState.nivel_esta_completado(nivel):
		esperando_inicio = false
		panel_nivel.visible = false
	else:
		_mostrar_ventanita(nivel)

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
		# Guardamos la posición exacta (tramo + progress_ratio) del personaje
		# ANTES de cambiar de escena, para poder restaurarla tal cual al volver.
		GameState.tramo_guardado_path = str(get_path_to(tramo_actual))
		GameState.tramo_guardado_ratio = tramo_actual.progress_ratio
		print("[DEBUG] _on_iniciar_minijuego(", nivel, ") -> guardando path=",
			GameState.tramo_guardado_path, " ratio=", GameState.tramo_guardado_ratio,
			" | nodo_actual=", nodo_actual)
		GameState.ir_a_minijuego(nivel, escenas_minijuego[nivel])
	else:
		push_warning("No hay minijuego configurado para el nivel %d" % nivel)

# Se deja por compatibilidad, por si algún minijuego llama a esta función
# directamente en vez de pasar por GameState.volver_al_mapa_con_resultado().
func nivel_completado(nivel: int):
	GameState.marcar_nivel_completado(nivel)

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

	# Para avanzar hacia un nodo nuevo, el nivel donde estás parado debe
	# estar completado (GameState lo recuerda aunque el Mapa se recargue).
	# Para retroceder, o para moverte por nodos ya completados en cualquier
	# dirección, no hay restricción: te movés libre.
	if es_avance and not GameState.nivel_esta_completado(nodo_actual):
		print("[DEBUG] Avance bloqueado: el nivel ", nodo_actual,
			" todavía no está marcado como completado en GameState. ",
			"niveles_completados=", GameState.niveles_completados)
		return

	var destino_path = get_node(info["path"])
	var nodo_destino = info["destino"]

	print("[DEBUG] _input -> moviendo de nodo ", nodo_actual, " a ", nodo_destino,
		" via ", info["path"], " invertido=", info["invertido"])
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
	# keep_global_transform=false + offset fijo, por la misma razón que en
	# _ubicar_personaje_en_nodo: evitar que se arrastre un offset corrupto
	# por la rotación del tramo de origen.
	personaje.reparent(destino, false)
	personaje.position = CHARACTER_OFFSET
	personaje.rotation = 0
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
			_entrar_a_nodo(nodo_destino)
	)
