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
	get_tree().change_scene_to_file("res://minigame_rayo/MainRayo.tscn")

func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://minigame_rio/RiverCleanupMinigame.tscn")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://minigame_puzzle/MapPuzzle.tscn")

func _on_button_5_pressed() -> void:
	get_tree().change_scene_to_file("res://minigame_defo/mini_juego.tscn")

func _on_button_26_pressed() -> void:
	get_tree().change_scene_to_file("res://selector_edad/age_selector.tscn")
