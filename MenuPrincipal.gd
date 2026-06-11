extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_button_4_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Desmonta la casa!"
	minigame_data.description  = "Un volcán está por hacer erupción, ¡desmontá la casa antes de que sea tarde!"
	minigame_data.instructions = "Tocá todos los tornillos para desmontar cada pieza de la casa."
	minigame_data.video_path   = "res://minigame_house/assets/House_Instruction.ogv"
	minigame_data.minigame_scene = "res://minigame_house/HouseMinigame.tscn"
	minigame_data.controls = [
		{ "action": "Tocar tornillo", "icon": "res://ui_global/assets/ClickIcon.png" },
	]
	get_tree().change_scene_to_file("res://ui_global/MinigameIntro.tscn")

func _on_button_3_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Esquiva los rayos!"
	minigame_data.description  = "Te protegiste mientras pasaba la tormenta eléctrica."
	minigame_data.instructions = "Muevete de derecha a izquiera esquivando los rayos"
	minigame_data.video_path   = "res://minigame_rayo/assets/Thunder_Instruction.ogv"
	minigame_data.minigame_scene = "res://minigame_rayo/MainRayo.tscn"
	minigame_data.controls = [
		{ "action": "Moverse derecha", "icon": "res://ui_global/assets/left-button.png" },
		{ "action": "Moverse izquierda", "icon": "res://ui_global/assets/right-button.png" },
	]
	get_tree().change_scene_to_file("res://ui_global/MinigameIntro.tscn")


func _on_button_2_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Limpia el río!"
	minigame_data.description  = "Ayuda a limpiar el río"
	minigame_data.instructions = "Selecciona una basura y arrastrala al basurero"
	minigame_data.video_path   = "res://minigame_river/assets/River_Instruction.ogv"
	minigame_data.minigame_scene = "res://minigame_river/RiverCleanupMinigame.tscn"
	minigame_data.controls = [
		{ "action": "Arrastrar basura", "icon": "res://ui_global/assets/ClickIcon.png" },
	]
	get_tree().change_scene_to_file("res://ui_global/MinigameIntro.tscn")

func _on_button_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Ordena el mapa de riesgo escolar!"
	minigame_data.description  = "Participaste en la elaboración del mapa de riesgo"
	minigame_data.instructions = "Tocá una pieza y despúes toca donde la quieres acomodar, para armar el mapa de riesgo"
	minigame_data.video_path   = "res://minigame_puzzle/assets/Puzzle_Instruction.ogv"
	minigame_data.minigame_scene = "res://minigame_puzzle/MapPuzzle.tscn"
	minigame_data.controls = [
		{ "action": "Tocar piezas", "icon": "res://ui_global/assets/ClickIcon.png" },
	]
	get_tree().change_scene_to_file("res://ui_global/MinigameIntro.tscn")

func _on_button_5_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Reforesta el bosque!"
	minigame_data.description  = "Tu comunidad deforesto el bosque, ayuda a reforestarlo."
	minigame_data.instructions = "Selecciona las semilas y arrastralas a los hoyos buenos, y luego riegalas"
	minigame_data.video_path   = "res://minigame_defo/sprites/Tree_Instruction.ogv"
	minigame_data.minigame_scene = "res://minigame_defo/mini_juego.tscn"
	minigame_data.controls = [
		{ "action": "Arrastrar semillas y regadera", "icon": "res://ui_global/assets/ClickIcon.png" },
	]
	get_tree().change_scene_to_file("res://ui_global/MinigameIntro.tscn")

func _on_button_26_pressed() -> void:
	get_tree().change_scene_to_file("res://selector_edad/age_selector.tscn")
