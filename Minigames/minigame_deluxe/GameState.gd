extends Node

# Nivel que se está jugando actualmente en el minijuego
var nivel_actual: int = 1

# Ruta de la escena del mapa (AJUSTA esto a donde tengas guardado tu Map.tscn)
var ruta_escena_mapa: String = "res://Minigames/minigame_deluxe/Map.tscn"

# Guarda el resultado del último minijuego jugado, para que el Mapa lo lea al volver
# "" = sin resultado pendiente | "gano" | "perdio"
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


func ir_a_minijuego(nivel: int, ruta_escena: String) -> void:
	nivel_actual = nivel
	_resultado_pendiente = ""
	get_tree().change_scene_to_file(ruta_escena)


func volver_al_mapa_con_resultado(gano: bool) -> void:
	_resultado_pendiente = "gano" if gano else "perdio"

	if gano:
		marcar_nivel_completado(nivel_actual)

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
