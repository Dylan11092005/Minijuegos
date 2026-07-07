extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_21_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")

	minigame_data.title = "¡Repara las fugas!"

	minigame_data.description = (
		"Evita el desperdicio de agua reparando todas las fugas "
		+ "antes de que el depósito se vacíe."
	)

	minigame_data.instructions = (
		"Arrastra el parche hasta cada fuga de la tubería. "
		+ "Repara todos los chorros antes de que el nivel de agua "
		+ "llegue a cero."
	)

	minigame_data.video_path = (
		"res://Minigames/minigame_water_leak/assets/"
		+ "WaterLeak_Instruction.ogv"
	)

	minigame_data.minigame_scene = (
		"res://Minigames/minigame_water_leak/"
		+ "WaterLeakMinigame.tscn"
	)

	minigame_data.controls = [
		{
			"action": "Arrastrar parche",
			"icon": (
				"res://Minigames/ui_global/assets/"
				+ "ClickIcon.png"
			)
		}
	]

	get_tree().change_scene_to_file(
		"res://Minigames/ui_global/MinigameIntro.tscn"
	)



func _on_button_15_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")

	minigame_data.title = "¡Construye la ruta segura!"

	minigame_data.description = (
		"Construye un camino seguro desde la escuela hasta la zona de reunión, "
		+ "evitando los obstáculos que bloquean algunas casillas."
	)

	minigame_data.instructions = (
		"Arrastra las piezas de camino desde el panel derecho y colócalas "
		+ "en las casillas disponibles del mapa. Conecta la escuela con la "
		+ "zona segura antes de que termine el tiempo. Las piedras y los árboles "
		+ "caídos son obstáculos, por lo que no podrás colocar caminos sobre esas "
		+ "casillas. Si colocas una pieza incorrecta, tócala para quitarla."
	)

	minigame_data.video_path = (
		"res://Minigames/minigame_route/assets/Route_Instruction.ogv"
	)

	minigame_data.minigame_scene = (
		"res://Minigames/minigame_route/SchoolRouteMinigame.tscn"
	)

	minigame_data.controls = [
		{
			"action": "Arrastrar caminos",
			"icon": "res://Minigames/ui_global/assets/ClickIcon.png"
		},
		{
			"action": "Quitar caminos",
			"icon": "res://Minigames/ui_global/assets/ClickIcon.png"
		},
	]

	get_tree().change_scene_to_file(
		"res://Minigames/ui_global/MinigameIntro.tscn"
	)


func _on_button_10_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")

	minigame_data.title = "¡Ordena el botiquín!"
	minigame_data.description = "Abre el botiquín y organiza correctamente todos los implementos médicos."

	minigame_data.instructions = (
		"Primero selecciona los dos seguros para abrir el botiquín. "
		+ "Después, arrastra cada implemento médico hacia su espacio correspondiente. "
		+ "Debes ordenar todos los implementos antes de que se terminen los 30 segundos. "
		+ "Perderás una vida cada vez que coloques un implemento en un espacio incorrecto."
	)

	minigame_data.video_path = "res://Minigames/minigame_kit/assets/kit_Instruction.ogv"
	minigame_data.minigame_scene = "res://Minigames/minigame_kit/MedicalKitMinigame.tscn"

	minigame_data.controls = [
		{
			"action": "Abrir los seguros y arrastrar los implementos",
			"icon": "res://Minigames/ui_global/assets/ClickIcon.png"
		},
	]

	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")
func _on_button_4_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Desmonta la casa!"
	minigame_data.description  = "Un volcán está por hacer erupción, ¡desmontá la casa antes de que sea tarde!"
	minigame_data.instructions = "Tocá todos los tornillos para desmontar cada pieza de la casa."
	minigame_data.video_path   = "res://Minigames/minigame_house/assets/House_Instruction.ogv"
	minigame_data.minigame_scene = "res://Minigames/minigame_house/HouseMinigame.tscn"
	minigame_data.controls = [
		{ "action": "Tocar tornillo", "icon": "res://Minigames/ui_global/assets/ClickIcon.png" },
	]
	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")

func _on_button_3_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Esquiva los rayos!"
	minigame_data.description  = "Te protegiste mientras pasaba la tormenta eléctrica."
	minigame_data.instructions = "Muevete de derecha a izquiera esquivando los rayos"
	minigame_data.video_path   = "res://Minigames/minigame_storm/assets/Thunder_Instruction.ogv"
	minigame_data.minigame_scene = "res://Minigames/minigame_storm/StormMinigame.tscn"
	minigame_data.controls = [
		{ "action": "Moverse derecha, moverse izquierda", "icon": "res://Minigames/ui_global/assets/Left_Right.png" },
	]
	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")


func _on_button_2_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Limpia el río!"
	minigame_data.description  = "Ayuda a limpiar el río"
	minigame_data.instructions = "Selecciona una basura y arrastrala al basurero"
	minigame_data.video_path   = "res://Minigames/minigame_river/assets/River_Instruction.ogv"
	minigame_data.minigame_scene = "res://Minigames/minigame_river/RiverCleanupMinigame.tscn"
	minigame_data.controls = [
		{ "action": "Arrastrar basura", "icon": "res://Minigames/ui_global/assets/ClickIcon.png" },
	]
	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")



func _on_button_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Ordena el mapa de riesgo escolar!"
	minigame_data.description  = "Participaste en la elaboración del mapa de riesgo"
	minigame_data.instructions = "Tocá una pieza y despúes toca donde la quieres acomodar, para armar el mapa de riesgo"
	minigame_data.video_path   = "res://Minigames/minigame_puzzle/assets/Puzzle_Instruction.ogv"
	minigame_data.minigame_scene = "res://Minigames/minigame_puzzle/MapPuzzle.tscn"
	minigame_data.controls = [
		{ "action": "Tocar piezas", "icon": "res://Minigames/ui_global/assets/ClickIcon.png" },
	]
	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")

func _on_button_5_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Reforesta el bosque!"
	minigame_data.description  = "Tu comunidad deforesto el bosque, ayuda a reforestarlo."
	minigame_data.instructions = "Selecciona una semilla y arrástrala hacia un hoyo bueno. 
	Evita los hoyos malos, porque te quitarán vida si sueltas la semilla sobre ellos. 
	Cuando todas las semillas estén plantadas, usa la regadera para regarlas antes de que se acabe el tiempo."
	minigame_data.video_path   = "res://Minigames/minigame_defo/sprites/Tree_instruction2.ogv"
	minigame_data.minigame_scene = "res://Minigames/minigame_defo/mini_game.tscn"
	minigame_data.controls = [
		{ "action": "Arrastrar semillas y regadera", "icon": "res://Minigames/ui_global/assets/ClickIcon.png" },
	]
	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")
	
	

func _on_button_26_pressed() -> void:
	get_tree().change_scene_to_file("res://age_selector/age_selector.tscn")

func _on_button_9_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title = "¡Llega a la zona segura!"
	minigame_data.description = "TERREMOTO, Te metiste debajo de la mesa para protegerte."
	minigame_data.instructions = "Manten presionado el botón rojo cuando ocurra un terromoto para ocultarte debajo de la mesa."
	minigame_data.video_path = "res://Minigames/minigame_earthquake/assets/EarthquakeInstructions.ogv"
	minigame_data.minigame_scene = "res://Minigames/minigame_earthquake/Main.tscn"
	minigame_data.controls = [
	{ "action": "Manten presionado el botón", "icon": "res://Minigames/ui_global/assets/ClickIcon.png" },
]
	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")

func _on_button_6_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title = "¡Rescata a tus amigos!"
	minigame_data.description = "Ayuda a tus amigos a llegar a la zona segura durante la inundación."
	minigame_data.instructions = "Muévete por el laberinto, rescata a los dos amigos y llega a la zona segura antes de que se acabe el tiempo."
	minigame_data.video_path = "res://Minigames/minigame_laberinto/assets/maze_Instructions.ogv"
	minigame_data.minigame_scene = "res://Minigames/minigame_laberinto/maze_minigame.tscn"
	minigame_data.controls = [
	{ "action": "Moverse arriba, abajo, izquiera y derecha", "icon": "res://Minigames/ui_global/assets/Movement.png" },
]
	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")


func _on_button_12_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")

	minigame_data.title = "¡Limpia el río!"
	minigame_data.description = "Las fábricas han contaminado el río. Elimina los desechos sin dañar a los peces."

	minigame_data.instructions = "Mueve el cursor sobre los desechos para recogerlos antes de que termine el tiempo. Evita tocar a los peces, ya que perderás puntos o cometerás errores."

	minigame_data.video_path = "res://Minigames/minigame_river_clean/assets/video/RiverCleanInstructions.ogv"
	minigame_data.minigame_scene = "res://Minigames/minigame_river_clean/RiverCleanMinigame.tscn"

	minigame_data.controls = [
		{
			"action": "Mover guante",
			"icon": "res://Minigames/ui_global/assets/ClickIcon.png"
		},
	]

	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")
func _on_button_11_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")

	minigame_data.title = "¡Identifica el río diferente!"
	minigame_data.description = "Identificaste que el río está creciendo. Observa los ríos y encuentra cuál tiene una característica distinta."
	minigame_data.instructions = "Mira cuidadosamente cada grupo de ríos. Haz clic sobre el río diferente para avanzar de ronda. Ganas si completas las tres rondas antes de quedarte sin vidas o sin tiempo."

	minigame_data.video_path = "res://Minigames/minigame_identify_river/assets/videoriver.ogv"
	minigame_data.minigame_scene = "res://Minigames/minigame_identify_river/main.tscn"

	minigame_data.controls = [
		{ "action": "Seleccionar río", "icon": "res://Minigames/ui_global/assets/ClickIcon.png" },
	]

	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")
	
func _on_button_7_pressed() -> void:
	var minigame_data = get_node_or_null("/root/MinigameData")

	if minigame_data == null:
		print("ERROR: No existe MinigameData en AutoLoad")
		get_tree().change_scene_to_file("res://Minigames/minigame_hillside_barrier/HillsideBarrierMinigame.tscn")
		return

	minigame_data.title = "¡Protege la ladera!"
	minigame_data.description = "Coloca arbolitos en puntos estratégicos para formar barreras naturales y detener las rocas antes de que provoquen un deslizamiento."
	minigame_data.instructions = "Observa la dirección en la que cae cada roca. Cuando aparezca el punto de siembra, arrastra un árbol desde la madera de selección y colócalo en el camino de la roca. Si la roca choca con el árbol, ambos desaparecen y sumas una roca detenida. Ganas si detienes la cantidad necesaria de rocas antes de que se acabe el tiempo. Pierdes si el tiempo llega a cero o si las rocas pasan sin ser detenidas y pierdes todas tus vidas."
	minigame_data.video_path ="res://Minigames/minigame_hillside_barrier/assets/instruction.ogv"
	minigame_data.minigame_scene = "res://Minigames/minigame_hillside_barrier/HillsideBarrierMinigame.tscn"
	minigame_data.controls = [
		{ "action": "Arrastrar y soltar árbol", "icon": "res://Minigames/ui_global/assets/ClickIcon.png" },
	]

	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")


func _on_button_14_pressed() -> void:
	var minigame_data = get_node_or_null("/root/MinigameData")

	if minigame_data == null:
		print("ERROR: No existe MinigameData en AutoLoad")
		get_tree().change_scene_to_file("res://Minigames/minigame_hillside_barrier/HillsideBarrierMinigame.tscn")
		return

	minigame_data.title = "¡Revisa las fechas de vencimiento!"
	minigame_data.description = "Olvidaste revisar la fecha de vencimiento de los suministros"
	minigame_data.instructions = "Observa la fecha actual y las fechas de vencimiento de cada producto, los productos que esten dentro del rango de fecha correcto se arrastran a la refrigeradora en cambio, los productos vencidos se arrastran al basurero"
	minigame_data.video_path ="res://Minigames/minigame_expiration/assets/ExpirationInstruction.ogv"
	minigame_data.minigame_scene = "res://Minigames/minigame_expiration/MainExpiration.tscn"
	minigame_data.controls = [
		{ "action": "Arrastrar comida", "icon": "res://Minigames/ui_global/assets/ClickIcon.png" },
	]

	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")


func _on_button_17_pressed() -> void:
	
	var minigame_data = get_node("/root/MinigameData")

	minigame_data.title = "¡Alarma Inclusiva!"

	minigame_data.description = "Tu escuela aún no cuenta con un sistema de alarma adecuado para personas con discapacidad auditiva."

	minigame_data.instructions = "Arrastra cada objeto a la categoría correcta. Identifica las luces intermitentes, dispositivos de vibración y señales visuales. Evita los errores y evita los distractores. Completa la clasificación antes de que se agote el tiempo."

	minigame_data.video_path = "res://Minigames/minigame_inclusive_alarms/assets/video/InclusiveAlarmsInstructions.ogv"

	minigame_data.minigame_scene = "res://Minigames/minigame_inclusive_alarms/inclusive_alarms_minigame.tscn"

	minigame_data.controls = [
		{
			"action": "Arrastrar objetos",
			"icon": "res://Minigames/ui_global/assets/ClickIcon.png"
		}
	]

	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")

func _on_button_13_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	
	minigame_data.title = "¡Apaga el incendio!"
	minigame_data.description = "Alguien dejó un cigarrillo en el bosque y provocó un incendio."
	minigame_data.instructions = "Presiona los árboles que están en llamas para apagar el fuego. Tienes 2 segundos antes de que el árbol se queme. Si presionas un árbol que no tiene fuego, perderás una vida."
	minigame_data.video_path = "res://Minigames/minigame_fire/assets/Fire_Instruction.ogv"
	minigame_data.minigame_scene = "res://Minigames/minigame_fire/MainFire.tscn"
	
	minigame_data.controls = [
		{ "action": "Presionar árboles en llamas", "icon": "res://Minigames/ui_global/assets/ClickIcon.png" },
	]
	
	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")


func _on_button_16_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	
	minigame_data.title = "¡Alerta de deslizamiento!"
	
	minigame_data.description = "Hay una amenaza de deslizamiento en la comunidad. Debes actuar rápido."
	
	minigame_data.instructions = "Debes esquivar las rocas, luego debes llegar al teléfono, presionar la tecla E y marcar 911 en el teclado. 
	Cuando termines la llamada, completaras la mision, y llegará un camión de bomberos. El camión recogerá al personaje y lo llevará hasta la cabina segura. 
	Ganas cuando el camión llegue al refugio antes de que se acabe el tiempo."
	
	minigame_data.video_path = "res://Minigames/minigame_landslide/assets/MiniGame13.ogv"
	
	minigame_data.minigame_scene = "res://Minigames/minigame_landslide/LandslideMinigame.tscn"
	
	minigame_data.controls = [
		{ "action": "Moverse derecha,izquierda, arriba y abajo", "icon": 
			"res://Minigames/ui_global/assets/Movement.png" },
	]
	
	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")

	



func _on_button_19_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")

	minigame_data.title = "¡Derechos de la niñez!"

	minigame_data.description = "Aprendiste que aún en medio de un desastre, la niñez tiene derechos y debe ser protegida."

	minigame_data.instructions = """Participarás en un juego de preguntas y respuestas relacionado con los derechos de la niñez durante situaciones de desastre.
En cada ronda aparecerá una pregunta con diferentes opciones y deberás seleccionar la respuesta correcta.
Ganas si completas correctamente la cantidad requerida de preguntas antes de que se acabe el tiempo.
Pierdes si fallas demasiadas respuestas o si no terminas dentro del tiempo establecido."""

	minigame_data.video_path = "res://Minigames/minigame_Question/assets/Video.ogv"

	minigame_data.minigame_scene = "res://Minigames/minigame_Question/QuestionMinigame.tscn"

	minigame_data.controls = [
		{
			"action": "Seleccionar respuesta",
			"icon": "res://Minigames/ui_global/assets/ClickIcon.png"
		},
	]

	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")


func _on_button_20_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	
	minigame_data.title = "¡Alerta de maremoto!"
	
	minigame_data.description = "Evacua a un lugar más alto"
	
	minigame_data.instructions = "Debes esquivar los obstaculos y evitar que te alcance el maremoto hasta llegar a la zona segura. Con las flechas de arriba y abajo te mueves entre niveles para evitar los obstaculos"
	
	minigame_data.video_path = "res://Minigames/minigame_wave/assets/WaveInstruction.ogv"
	
	minigame_data.minigame_scene = "res://Minigames/minigame_wave/WaveGame.tscn"
	
	minigame_data.controls = [
		{ "action": "Moverse derecha,izquierda, arriba y abajo", "icon": 
			"res://Minigames/ui_global/assets/Movement.png" },
	]
	
	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")


func _on_button_18_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	
	minigame_data.title = "¡Encuentra a la familia!"
	
	minigame_data.description = "¡Alerta! Debes ir al punto de encuentro acordado con la familia durante una emergencia."
	
	minigame_data.instructions = "Mueve al rescatista dentro de la casa para encontrar a papá, mamá, hijo e hija. Rescata a los cuatro familiares y llévalos a la zona segura antes de que se acabe el tiempo."
	
	minigame_data.video_path = "res://Minigames/minigame_FamilyMeeting/assets/video/FamilyMeetingInstructions.ogv"
	
	minigame_data.minigame_scene = "res://Minigames/minigame_FamilyMeeting/FamilyMeetingMinigame.tscn.tscn"
	
	minigame_data.controls = [
		{
			"action": "Moverse derecha, izquierda, arriba y abajo",
			"icon": "res://Minigames/ui_global/assets/Movement.png"
		},
	]
	
	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")


func _on_button_22_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	
	minigame_data.title = "¡Repara el puente!"
	
	minigame_data.description = "Un puente se rompió y debes arreglarlo antes de que alguien caiga."
	
	minigame_data.instructions = "Arrastra las tablas al lugar correcto para completar el puente. Si te equivocas, perderás vidas. Luego usa el martillo para terminar la reparación."
	
	minigame_data.video_path = "res://Minigames/minigame_bridge/assets/Bridge_Instruction.ogv"
	
	minigame_data.minigame_scene = "res://Minigames/minigame_bridge/BridgeMinigame.tscn"
	
	minigame_data.controls = [
		{ "action": "Arrastrar tablas, arrastrar martillo", "icon": "res://Minigames/ui_global/assets/ClickIcon.png" },
	]
	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")
	


func _on_button_24_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")

	minigame_data.title = "¡Desafío Matemático!"

	minigame_data.description = "Pon a prueba tu rapidez resolviendo operaciones matemáticas antes de que se acabe el tiempo."

	minigame_data.instructions = "Observa la operación que aparece en la pizarra y selecciona el número correcto en el teclado. Completa 10 operaciones antes de que termine el tiempo. Si acumulas 3 errores o se acaba el tiempo, perderás la partida."

	minigame_data.video_path = "res://Minigames/minigame_mathChallenge/assets/video/InstructionsMath.ogv"

	minigame_data.minigame_scene = "res://Minigames/minigame_mathChallenge/MathChallengeMinigame.tscn"

	minigame_data.controls = [
		{
			"action": "Seleccionar la respuesta correcta",
			"icon": "res://Minigames/ui_global/assets/ClickIcon.png"
		},
	]


	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")


func _on_button_23_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")

	minigame_data.title = "¡Evacuación segura!"

	minigame_data.description = "Ayuda a los niños a evacuar de forma ordenada y llegar seguros a la escuela siguiendo el ritmo correcto."

	minigame_data.instructions = "Observa los colores que bajan en pantalla y presiona las flechas correctas o el raton cuando lleguen a la zona de ritmo. Si fallas demasiadas veces o se acaba el tiempo, perderás la partida."

	minigame_data.video_path = "res://Minigames/minigame_evacuation/assets/InstructionsEva.ogv"

	minigame_data.minigame_scene = "res://Minigames/minigame_evacuation/EvacuationRhythmMinigame.tscn.tscn"

	minigame_data.controls = [
		{
			"action": "Usa el raton",
			"icon": "res://Minigames/ui_global/assets/ClickIcon.png"
		},
		{ "action": "Derecha,izquierda, arriba y abajo", "icon": 
			"res://Minigames/ui_global/assets/Movement.png" },
	]

	print("Minijuego seleccionado: ", minigame_data.title)
	print("Escena a cargar: ", minigame_data.minigame_scene)

	if not ResourceLoader.exists(minigame_data.minigame_scene):
		print("ERROR: No existe la escena en esta ruta: ", minigame_data.minigame_scene)
		return

	get_tree().change_scene_to_file("res://Minigames/ui_global/MinigameIntro.tscn")
