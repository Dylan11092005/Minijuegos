extends Node

# Nivel que se está jugando actualmente en el minijuego
var nivel_actual: int = 1

# Ruta de la escena del mapa (AJUSTA esto a donde tengas guardado tu Map.tscn)
var ruta_escena_mapa: String = "res://Minigames/minigame_deluxe/Map.tscn"

# Guarda el resultado del último minijuego jugado, para que el Mapa lo lea al volver.
# "" = sin resultado pendiente | "gano" | "perdio" | "juego_ganado" | "juego_perdido"
var _resultado_pendiente: String = ""

# Posición exacta del personaje en el mapa justo antes de entrar al
# minijuego, para poder restaurarla tal cual al volver (sin adivinar
# direcciones de curvas).
var tramo_guardado_path: String = ""
var tramo_guardado_ratio: float = 0.0

# NUEVO: niveles que el jugador ya ganó al menos una vez.
# Como GameState es un autoload (singleton), esto NO se pierde cuando el
# Mapa se recarga al volver de un minijuego -- por eso vive acá y no en
# una variable local del script del Mapa.
var niveles_completados: Dictionary = {}

# =========================================================
# VIDAS DEL RECORRIDO (todo el tablero, no de un solo minijuego)
# =========================================================
# El jugador tiene 3 vidas para todo el recorrido del mapa. Cada vez que
# pierde un minijuego se le descuenta una vida y puede reintentar ESE
# mismo nivel. Si se queda sin vidas, todo el progreso se reinicia y hay
# que empezar de nuevo desde el nivel 1.

const MAX_VIDAS_MAPA := 3
const ULTIMO_NIVEL := 10

var vidas_mapa: int = MAX_VIDAS_MAPA


func ir_a_minijuego(nivel: int, ruta_escena: String) -> void:
	nivel_actual = nivel
	_resultado_pendiente = ""
	get_tree().change_scene_to_file(ruta_escena)


func volver_al_mapa_con_resultado(gano: bool) -> void:
	if gano:
		marcar_nivel_completado(nivel_actual)

		if nivel_actual >= ULTIMO_NIVEL:
			# Completó el último nivel: ganó todo el juego.
			_resultado_pendiente = "juego_ganado"
		else:
			_resultado_pendiente = "gano"
	else:
		vidas_mapa -= 1
		vidas_mapa = max(vidas_mapa, 0)

		if vidas_mapa <= 0:
			# Se quedó sin vidas: se reinicia todo el progreso del tablero.
			_resultado_pendiente = "juego_perdido"
			reiniciar_progreso()
		else:
			_resultado_pendiente = "perdio"

	get_tree().change_scene_to_file(ruta_escena_mapa)


# El Mapa llama esto en su _ready() para saber qué pasó
func consumir_resultado() -> String:
	var r = _resultado_pendiente
	_resultado_pendiente = ""
	return r


# =========================================================
# PROGRESO DE NIVELES
# =========================================================

func marcar_nivel_completado(nivel: int) -> void:
	niveles_completados[nivel] = true


func nivel_esta_completado(nivel: int) -> bool:
	return niveles_completados.get(nivel, false)


# Reinicia todo: niveles completados, vidas y posición en el mapa. Se llama
# automáticamente cuando se agotan las 3 vidas, y también se puede llamar
# a mano (ej: desde el botón "Jugar de nuevo" de la pantalla de victoria
# final del mapa).
func reiniciar_progreso() -> void:
	niveles_completados.clear()
	vidas_mapa = MAX_VIDAS_MAPA
	nivel_actual = 1
	tramo_guardado_path = ""
	tramo_guardado_ratio = 0.0
