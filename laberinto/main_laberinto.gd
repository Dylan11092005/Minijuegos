extends Node2D

var tiempo_restante = 35
var juego_activo = false
var tamano_celda = 40

var columnas = 23
var filas = 13
var offset_x = (1152 - 23 * 40) / 2
var offset_y = (648 - 13 * 40) / 2

var mapa = [
	[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
	[1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
	[1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1,0,1,1,1,0,1],
	[1,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,1],
	[1,0,1,0,1,0,1,1,1,1,1,1,1,0,1,1,1,1,0,1,1,0,1],
	[1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1],
	[1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,0,1,1,0,1,1,0,1],
	[1,0,0,0,0,0,0,0,1,0,1,0,0,0,1,0,1,0,0,0,1,0,1],
	[1,0,1,1,1,1,1,0,1,0,1,1,1,0,1,0,1,0,1,0,1,0,1],
	[1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,1],
	[1,1,1,1,1,0,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1],
	[1,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,3,1],
	[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
]

func _ready():
	configurar_laberinto()
	configurar_jugador()
	configurar_meta()
	configurar_ui()
	configurar_timer()
	juego_activo = true

func configurar_laberinto():
	var laberinto = $Laberinto
	var grosor = 5
	for fila in range(mapa.size()):
		for col in range(mapa[fila].size()):
			var celda = mapa[fila][col]
			var x = col * tamano_celda + offset_x
			var y = fila * tamano_celda + offset_y
			if celda == 1:
				var arriba = ColorRect.new()
				arriba.color = Color(0.0, 0.8, 1.0, 0.9)
				arriba.size = Vector2(tamano_celda, grosor)
				arriba.position = Vector2(x, y)
				laberinto.add_child(arriba)

				var abajo = ColorRect.new()
				abajo.color = Color(0.0, 0.8, 1.0, 0.9)
				abajo.size = Vector2(tamano_celda, grosor)
				abajo.position = Vector2(x, y + tamano_celda - grosor)
				laberinto.add_child(abajo)

				var izquierda = ColorRect.new()
				izquierda.color = Color(0.0, 0.8, 1.0, 0.9)
				izquierda.size = Vector2(grosor, tamano_celda)
				izquierda.position = Vector2(x, y)
				laberinto.add_child(izquierda)

				var derecha = ColorRect.new()
				derecha.color = Color(0.0, 0.8, 1.0, 0.9)
				derecha.size = Vector2(grosor, tamano_celda)
				derecha.position = Vector2(x + tamano_celda - grosor, y)
				laberinto.add_child(derecha)

				var cuerpo = StaticBody2D.new()
				var forma = CollisionShape2D.new()
				var rectangulo = RectangleShape2D.new()
				rectangulo.size = Vector2(tamano_celda, tamano_celda)
				forma.shape = rectangulo
				cuerpo.position = Vector2(x + tamano_celda/2, y + tamano_celda/2)
				cuerpo.add_child(forma)
				laberinto.add_child(cuerpo)

			elif celda == 3:
				var meta_rect = ColorRect.new()
				meta_rect.color = Color(0.0, 0.9, 0.3, 0.9)
				meta_rect.size = Vector2(tamano_celda, tamano_celda)
				meta_rect.position = Vector2(x, y)
				laberinto.add_child(meta_rect)

				var label_meta = Label.new()
				label_meta.text = "🏁\nSALIDA"
				label_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label_meta.position = Vector2(x + 3, y + 3)
				label_meta.add_theme_font_size_override("font_size", 12)
				label_meta.add_theme_color_override("font_color", Color(1, 1, 1))
				label_meta.z_index = 5
				laberinto.add_child(label_meta)

func configurar_jugador():
	var jugador = preload("res://player_laberinto.tscn").instantiate()
	jugador.position = Vector2(1 * tamano_celda + offset_x + tamano_celda/2, 1 * tamano_celda + offset_y + tamano_celda/2)
	add_child(jugador)

func configurar_meta():
	var meta = $Area2D
	meta.position = Vector2(21 * tamano_celda + offset_x + tamano_celda/2, 11 * tamano_celda + offset_y + tamano_celda/2)
	var forma = $Area2D/CollisionShape2D
	var rectangulo = RectangleShape2D.new()
	rectangulo.size = Vector2(tamano_celda - 5, tamano_celda - 5)
	forma.shape = rectangulo
	meta.body_entered.connect(_on_meta_entered)

func configurar_ui():
	var label = $Label
	label.text = "⏱ Tiempo: " + str(tiempo_restante)
	label.position = Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.z_index = 10

	var panel = ColorRect.new()
	panel.color = Color(0, 0, 0, 0.6)
	panel.size = Vector2(230, 45)
	panel.position = Vector2(5, 5)
	panel.z_index = 9
	add_child(panel)

func configurar_timer():
	var timer = $Timer
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	if juego_activo:
		tiempo_restante -= 1
		$Label.text = "⏱ Tiempo: " + str(tiempo_restante)
		if tiempo_restante <= 0:
			juego_perdido()

func _on_meta_entered(body):
	if body is CharacterBody2D and juego_activo:
		juego_ganado()

func juego_ganado():
	juego_activo = false
	$Timer.stop()
	var jugador = get_node_or_null("PlayerLaberinto")
	if jugador:
		jugador.juego_activo = false
		mostrar_mensaje("🎉 ¡Llegaste a la zona segura!\n¡Ganaste!", true)


func juego_perdido():
	juego_activo = false
	$Timer.stop()
	var jugador = get_node_or_null("PlayerLaberinto")
	if jugador:
		jugador.juego_activo = false
		mostrar_mensaje("💧 ¡La inundación te atrapó!\n¡Perdiste!", false)


func mostrar_mensaje(texto, es_ganador):
	# Fondo oscuro
	var fondo_msg = ColorRect.new()
	fondo_msg.color = Color(0, 0, 0, 0.75)
	fondo_msg.size = Vector2(1152, 648)
	fondo_msg.position = Vector2(0, 0)
	fondo_msg.z_index = 20
	add_child(fondo_msg)

	# Panel principal con esquinas redondeadas
	var panel = Panel.new()
	panel.size = Vector2(500, 260)
	panel.position = Vector2(326, 194)
	panel.z_index = 21

	# Estilo del panel
	var estilo = StyleBoxFlat.new()
	if es_ganador:
		estilo.bg_color = Color(0.15, 0.55, 0.15, 0.97)
		estilo.border_color = Color(0.1, 0.8, 0.1)
	else:
		estilo.bg_color = Color(0.55, 0.12, 0.12, 0.97)
		estilo.border_color = Color(0.9, 0.1, 0.1)
	estilo.corner_radius_top_left = 20
	estilo.corner_radius_top_right = 20
	estilo.corner_radius_bottom_left = 20
	estilo.corner_radius_bottom_right = 20
	estilo.border_width_top = 4
	estilo.border_width_bottom = 4
	estilo.border_width_left = 4
	estilo.border_width_right = 4
	panel.add_theme_stylebox_override("panel", estilo)
	add_child(panel)

	# Texto del mensaje
	var label_fin = Label.new()
	label_fin.text = texto
	label_fin.add_theme_font_size_override("font_size", 36)
	label_fin.add_theme_color_override("font_color", Color(1, 1, 1))
	label_fin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_fin.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_fin.size = Vector2(480, 160)
	label_fin.position = Vector2(336, 204)
	label_fin.z_index = 22
	add_child(label_fin)

	# Botón volver al menú
	var boton_panel = Panel.new()
	boton_panel.size = Vector2(240, 55)
	boton_panel.position = Vector2(456, 384)
	boton_panel.z_index = 22

	var estilo_boton = StyleBoxFlat.new()
	estilo_boton.bg_color = Color(0.1, 0.5, 0.9, 0.95)
	estilo_boton.border_color = Color(0.2, 0.7, 1.0)
	estilo_boton.corner_radius_top_left = 15
	estilo_boton.corner_radius_top_right = 15
	estilo_boton.corner_radius_bottom_left = 15
	estilo_boton.corner_radius_bottom_right = 15
	estilo_boton.border_width_top = 3
	estilo_boton.border_width_bottom = 3
	estilo_boton.border_width_left = 3
	estilo_boton.border_width_right = 3
	boton_panel.add_theme_stylebox_override("panel", estilo_boton)
	add_child(boton_panel)

	var label_boton = Label.new()
	label_boton.text = "🔄 Volver al menú"
	label_boton.add_theme_font_size_override("font_size", 22)
	label_boton.add_theme_color_override("font_color", Color(1, 1, 1))
	label_boton.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_boton.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_boton.size = Vector2(240, 55)
	label_boton.position = Vector2(456, 384)
	label_boton.z_index = 23
	add_child(label_boton)
