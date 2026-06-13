extends Node2D

var amigos_rescatados = 0

func _ready() -> void:
	$AudioMusica.play()
	$Amigos/Amigo1.body_entered.connect(_on_amigo1_rescatado)
	$Amigos/Amigo2.body_entered.connect(_on_amigo2_rescatado)
	$ZonaSegura.body_entered.connect(_on_zona_segura_entrada)

	actualizar_ui_amigos()

	$TimerUI.iniciar(30, "Evacúa en", "segundos")
	$TimerUI.time_up.connect(_on_tiempo_agotado)

func _on_amigo1_rescatado(body):
	if body.name == "Jugador":
		amigos_rescatados += 1
		$Amigos/Amigo1.queue_free()
		print("Amigos rescatados: ", amigos_rescatados)
		verificar_zona_segura()
		actualizar_ui_amigos()
		$AudioRescate.play()

func _on_amigo2_rescatado(body):
	if body.name == "Jugador":
		amigos_rescatados += 1
		$Amigos/Amigo2.queue_free()
		print("Amigos rescatados: ", amigos_rescatados)
		verificar_zona_segura()
		actualizar_ui_amigos()
		$AudioRescate.play()

func verificar_zona_segura():
	if amigos_rescatados >= 2:
		$ZonaSegura/BloqueoZona/CollisionShape2D.disabled = true

func _on_zona_segura_entrada(body):
	if body.name == "Jugador":
		if amigos_rescatados >= 2:
			$AudioMusica.stop()
			$Jugador.bloquear_movimiento()
			$TimerUI.detener()
			$ResultadoJuego.mostrar_ganaste()
		else:
			print("Aún faltan amigos por rescatar")

func actualizar_ui_amigos():
	$PanelAmigos/LabelAmigos.text = str(amigos_rescatados) + " / 2"

	var tween = create_tween()
	tween.tween_property($PanelAmigos, "scale", Vector2(1.15, 1.15), 0.1)
	tween.tween_property($PanelAmigos, "scale", Vector2(1, 1), 0.1)
	
	
func _on_tiempo_agotado():
	$AudioMusica.stop()
	$Jugador.bloquear_movimiento()
	$TimerUI.detener()
	$ResultadoJuego.mostrar_perdiste()
