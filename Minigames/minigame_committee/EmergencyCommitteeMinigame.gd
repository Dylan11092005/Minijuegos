extends Node2D


# =========================================================
# PATHS
# =========================================================

const BACKGROUND_PATH := "res://Minigames/minigame_committee/assets/background.png"

const EMERGENCY_ROLE_SCENE_PATH := "res://Minigames/minigame_committee/EmergencyRole.tscn"
const EMERGENCY_ITEM_SCENE_PATH := "res://Minigames/minigame_committee/EmergencyItem.tscn"

const TIMER_UI_SCENE_PATH := "res://Minigames/ui_global/TimerUI.tscn"
const GAME_RESULT_SCENE_PATH := "res://Minigames/ui_global/GameResult.tscn"

const LIVES_UI_SCENE_PATH := "res://Minigames/ui_global/LivesUi.tscn"
const LIVES_UI_SCRIPT_PATH := "res://Minigames/ui_global/LivesUi.gd"


# =========================================================
# GAME SETTINGS
# =========================================================

const TOTAL_TIME := 45.0
const MAX_LIVES := 3

# Ahora estos valores representan altura deseada en píxeles.
const ROLE_SCALE := Vector2(310, 310)
const ITEM_SCALE := Vector2(82, 82)
const PLACED_ITEM_SCALE := Vector2(52, 52)

const DROP_DISTANCE := 160.0


# =========================================================
# COLORS
# =========================================================

const C_BEIGE := Color("#E5C89E")
const C_ORANGE := Color("#E0B080")
const C_BLUE := Color("#3E5F8F")
const C_PHASE_BLUE := Color("#3E5F8F")
const C_PHASE_ORANGE := Color("#E07820")
const C_PHASE_RED := Color("#D63A3A")


# =========================================================
# NODE REFERENCES
# =========================================================

@onready var background: Sprite2D = $Background
@onready var roles_parent: Node2D = $Roles
@onready var items_parent: Node2D = $Items

@onready var hud: CanvasLayer = $HUD
@onready var counter_label: Label = $HUD/CounterLabel


# =========================================================
# VARIABLES
# =========================================================

var timer_ui = null
var game_result = null

var lives_layer: CanvasLayer = null
var lives_ui = null

var damage_layer: CanvasLayer = null
var damage_rect: ColorRect = null

var items_tray: Panel = null

var roles: Array = []
var items: Array = []

var current_lives: int = MAX_LIVES
var placed_items: int = 0
var total_items: int = 0

var game_started: bool = false
var game_over: bool = false


# =========================================================
# LIFECYCLE
# =========================================================

func _ready():
	randomize()
	
	_setup_background()
	_setup_timer_ui()
	_setup_game_result()
	_setup_lives_ui()
	_setup_damage_effect()
	_setup_ui()
	_setup_items_tray()
	
	call_deferred("_start_game")


func _process(_delta):
	if not game_started:
		return
	
	if game_over:
		return
	
	_update_hud()


# =========================================================
# DATA
# =========================================================

func _get_roles_data() -> Array:
	return [
		{
			"id": "firefighter",
			"name": "Bombero",
			"paths": [
				"res://Minigames/minigame_committee/assets/characters/firefighter.png",
				"res://Minigames/minigame_committee/assets/firefighter.png",
				"res://Minigames/minigame_committee/assets/fireFighter.png",
				"res://Minigames/minigame_committee/assets/fireFighter.PNG",
				"res://Minigames/minigame_committee/assets/fireFighter.jpg"
			]
		},
		{
			"id": "red_cross",
			"name": "Cruz Roja",
			"paths": [
				"res://Minigames/minigame_committee/assets/characters/cruz_roja.png",
				"res://Minigames/minigame_committee/assets/cruz_roja.png",
				"res://Minigames/minigame_committee/assets/cruz Roja.png",
				"res://Minigames/minigame_committee/assets/cruz Roja.PNG",
				"res://Minigames/minigame_committee/assets/cruz Roja.jpg"
			]
		},
		{
			"id": "rescuer",
			"name": "Rescatista",
			"paths": [
				"res://Minigames/minigame_committee/assets/characters/rescuer.png",
				"res://Minigames/minigame_committee/assets/rescuer.png",
				"res://Minigames/minigame_committee/assets/rescuer.PNG",
				"res://Minigames/minigame_committee/assets/rescuer.jpg"
			]
		},
		{
			"id": "communicator",
			"name": "Comunicador",
			"paths": [
				"res://Minigames/minigame_committee/assets/characters/communicator.png",
				"res://Minigames/minigame_committee/assets/communicator.png",
				"res://Minigames/minigame_committee/assets/communicator.PNG",
				"res://Minigames/minigame_committee/assets/communicator.jpg"
			]
		}
	]


func _get_items_data() -> Array:
	return [
		{
			"id": "fire_extinguisher",
			"name": "Extintor",
			"role": "firefighter",
			"paths": [
				"res://Minigames/minigame_committee/assets/items/fire_extinguisher.png",
				"res://Minigames/minigame_committee/assets/FireExtinguisher.png",
				"res://Minigames/minigame_committee/assets/FireExtinguisher.PNG"
			]
		},
		{
			"id": "firefighter_hat",
			"name": "Casco",
			"role": "firefighter",
			"paths": [
				"res://Minigames/minigame_committee/assets/items/firefighter_hat.png",
				"res://Minigames/minigame_committee/assets/FirefighterHat.png",
				"res://Minigames/minigame_committee/assets/FirefigtherHat.png",
				"res://Minigames/minigame_committee/assets/FirefigtherHat.PNG"
			]
		},
		{
			"id": "hose",
			"name": "Manguera",
			"role": "firefighter",
			"paths": [
				"res://Minigames/minigame_committee/assets/items/hose.png",
				"res://Minigames/minigame_committee/assets/Hose.png",
				"res://Minigames/minigame_committee/assets/Hose.PNG"
			]
		},
		{
			"id": "medicine_cabinet",
			"name": "Botiquín",
			"role": "red_cross",
			"paths": [
				"res://Minigames/minigame_committee/assets/items/medicine_cabinet.png",
				"res://Minigames/minigame_committee/assets/MedicineCabinet.png",
				"res://Minigames/minigame_committee/assets/MedicineCabinet.PNG"
			]
		},
		{
			"id": "rope",
			"name": "Cuerda",
			"role": "rescuer",
			"paths": [
				"res://Minigames/minigame_committee/assets/items/rope.png",
				"res://Minigames/minigame_committee/assets/Rope.png",
				"res://Minigames/minigame_committee/assets/Rope.PNG"
			]
		},
		{
			"id": "flare",
			"name": "Linterna",
			"role": "rescuer",
			"paths": [
				"res://Minigames/minigame_committee/assets/items/flare.png",
				"res://Minigames/minigame_committee/assets/Flare.png",
				"res://Minigames/minigame_committee/assets/Flare.PNG"
			]
		},
		{
			"id": "megaphone",
			"name": "Megáfono",
			"role": "communicator",
			"paths": [
				"res://Minigames/minigame_committee/assets/items/megaphone.png",
				"res://Minigames/minigame_committee/assets/Megaphone.png",
				"res://Minigames/minigame_committee/assets/Megaphone.PNG"
			]
		},
		{
			"id": "communicator_radio",
			"name": "Radio",
			"role": "communicator",
			"paths": [
				"res://Minigames/minigame_committee/assets/items/communicator_radio.png",
				"res://Minigames/minigame_committee/assets/Communicator2.png",
				"res://Minigames/minigame_committee/assets/Communicator 2.png",
				"res://Minigames/minigame_committee/assets/Communicator2.PNG",
				"res://Minigames/minigame_committee/assets/Communicator 2.PNG"
			]
		}
	]


func _first_existing_path(paths: Array) -> String:
	for path in paths:
		if ResourceLoader.exists(path):
			return path
	
	return ""


# =========================================================
# BACKGROUND
# =========================================================

func _setup_background():
	if not background:
		return
	
	if ResourceLoader.exists(BACKGROUND_PATH):
		background.texture = load(BACKGROUND_PATH)
	else:
		push_error("No se encontró background.png en: " + BACKGROUND_PATH)
	
	background.position = get_viewport_rect().size / 2
	background.z_index = -20
	
	var screen_size: Vector2 = get_viewport_rect().size
	
	if background.texture:
		var texture_size: Vector2 = background.texture.get_size()
		var scale_x: float = screen_size.x / texture_size.x
		var scale_y: float = screen_size.y / texture_size.y
		var final_scale: float = max(scale_x, scale_y)
		
		background.scale = Vector2(final_scale, final_scale)
		background.position = screen_size / 2


# =========================================================
# TIMER UI GLOBAL
# =========================================================

func _setup_timer_ui():
	if ResourceLoader.exists(TIMER_UI_SCENE_PATH):
		var timer_scene = load(TIMER_UI_SCENE_PATH)
		timer_ui = timer_scene.instantiate()
		timer_ui.name = "TimerUI"
		add_child(timer_ui)
	else:
		push_error("No se encontró TimerUI en: " + TIMER_UI_SCENE_PATH)
		return
	
	if timer_ui.has_signal("time_up"):
		if not timer_ui.time_up.is_connected(_on_time_up):
			timer_ui.time_up.connect(_on_time_up)
	
	if timer_ui.has_method("ocultar"):
		timer_ui.ocultar()


func _start_global_timer():
	if not timer_ui:
		return
	
	if timer_ui.has_method("set_tamano_panel"):
		timer_ui.set_tamano_panel(780, 60)
	
	if timer_ui.has_method("iniciar"):
		timer_ui.iniciar(TOTAL_TIME, "Tiempo restante", "para organizar el comité")
	else:
		push_error("TimerUI no tiene el método iniciar().")


func _stop_global_timer():
	if not timer_ui:
		return
	
	if timer_ui.has_method("detener"):
		timer_ui.detener()


# =========================================================
# LIVES UI GLOBAL
# =========================================================

func _setup_lives_ui():
	# Usa el LivesUi que pusiste manualmente dentro del HUD.
	lives_ui = null
	
	if hud:
		lives_ui = hud.get_node_or_null("LivesUi")
		
		if not lives_ui:
			lives_ui = hud.get_node_or_null("LivesUI")
	
	if not lives_ui:
		push_error("No se encontró HUD/LivesUi. Revisa que el nodo exista y se llame exactamente LivesUi.")
		return
	
	lives_ui.visible = true
	
	# Lo ponemos arriba a la derecha, encima del fondo.
	lives_ui.position = Vector2(get_viewport_rect().size.x - 360, 25)
	lives_ui.z_index = 999
	
	# Propiedades del LivesUi global, si existen.
	_set_property_if_exists(lives_ui, "panel_corner", 1)
	_set_property_if_exists(lives_ui, "panel_margin", Vector2(35, 25))
	_set_property_if_exists(lives_ui, "corner", 1)
	_set_property_if_exists(lives_ui, "margin", Vector2(35, 25))
	
	if lives_ui.has_method("set_max_lives"):
		lives_ui.set_max_lives(MAX_LIVES)
	
	_update_lives_ui()
		
		

func _set_property_if_exists(node, property_name: String, value):
	if not node:
		return
	
	for property in node.get_property_list():
		if property.has("name") and property["name"] == property_name:
			node.set(property_name, value)
			return
			
func _update_lives_ui():
	if not lives_ui:
		return
	
	if lives_ui.has_method("actualizar_vidas"):
		lives_ui.actualizar_vidas(current_lives)
	else:
		_set_property_if_exists(lives_ui, "current_lives", current_lives)
		_set_property_if_exists(lives_ui, "lives", current_lives)
	
	if lives_ui.has_method("queue_redraw"):
		lives_ui.queue_redraw()


# =========================================================
# GAME RESULT GLOBAL
# =========================================================

func _setup_game_result():
	if ResourceLoader.exists(GAME_RESULT_SCENE_PATH):
		var result_scene = load(GAME_RESULT_SCENE_PATH)
		game_result = result_scene.instantiate()
		game_result.name = "GameResult"
		add_child(game_result)
	else:
		push_error("No se encontró GameResult.tscn en: " + GAME_RESULT_SCENE_PATH)


# =========================================================
# DAMAGE EFFECT
# =========================================================

func _setup_damage_effect():
	damage_layer = CanvasLayer.new()
	damage_layer.name = "DamageLayer"
	damage_layer.layer = 200
	add_child(damage_layer)
	
	damage_rect = ColorRect.new()
	damage_rect.name = "DamageRect"
	damage_rect.color = Color(1, 0, 0)
	damage_rect.modulate.a = 0.0
	damage_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	damage_layer.add_child(damage_rect)


func _play_damage_effect():
	if not damage_rect:
		return
	
	var original_position: Vector2 = position
	
	var flash_tween := create_tween()
	damage_rect.modulate.a = 0.0
	flash_tween.tween_property(damage_rect, "modulate:a", 0.35, 0.08)
	flash_tween.tween_property(damage_rect, "modulate:a", 0.0, 0.22)
	
	var shake_tween := create_tween()
	
	for i in range(6):
		var offset := Vector2(
			randf_range(-8.0, 8.0),
			randf_range(-8.0, 8.0)
		)
		
		shake_tween.tween_property(self, "position", original_position + offset, 0.03)
	
	shake_tween.tween_property(self, "position", original_position, 0.05)


# =========================================================
# UI
# =========================================================

func _setup_ui():
	if not hud or not counter_label:
		return
	
	if hud.has_node("CounterPanel"):
		return
	
	var counter_panel := Panel.new()
	counter_panel.name = "CounterPanel"
	counter_panel.position = Vector2(30, 95)
	counter_panel.size = Vector2(390, 46)
	counter_panel.z_index = 100
	counter_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = C_BEIGE
	style.border_color = C_ORANGE
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	
	counter_panel.add_theme_stylebox_override("panel", style)
	hud.add_child(counter_panel)
	
	if counter_label.get_parent():
		counter_label.get_parent().remove_child(counter_label)
	
	counter_panel.add_child(counter_label)
	
	counter_label.position = Vector2.ZERO
	counter_label.size = counter_panel.size
	counter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	counter_label.add_theme_font_size_override("font_size", 22)
	counter_label.add_theme_color_override("font_color", C_BLUE)
	
	_update_hud()


func _setup_items_tray():
	if items_tray:
		return
	
	var screen_size: Vector2 = get_viewport_rect().size
	
	items_tray = Panel.new()
	items_tray.name = "ItemsTray"
	items_tray.position = Vector2(screen_size.x * 0.08, screen_size.y * 0.755)
	items_tray.size = Vector2(screen_size.x * 0.84, screen_size.y * 0.19)
	items_tray.z_index = 5
	items_tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.90, 0.72, 0.45, 0.88)
	style.border_color = Color("#E0B080")
	style.border_width_left = 5
	style.border_width_right = 5
	style.border_width_top = 5
	style.border_width_bottom = 5
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 10
	style.shadow_offset = Vector2(3, 4)
	
	items_tray.add_theme_stylebox_override("panel", style)
	add_child(items_tray)


func _update_hud():
	if not counter_label:
		return
	
	counter_label.text = "Asignados: " + str(placed_items) + "/" + str(total_items)
	counter_label.add_theme_color_override("font_color", _get_counter_color())


func _get_counter_color() -> Color:
	if not timer_ui:
		return C_PHASE_BLUE
	
	if not timer_ui.has_method("get_remaining_time"):
		return C_PHASE_BLUE
	
	var remaining_time: float = timer_ui.get_remaining_time()
	var fraction: float = remaining_time / TOTAL_TIME
	
	if fraction > 0.5:
		return C_PHASE_BLUE
	elif fraction > 0.25:
		return C_PHASE_ORANGE
	else:
		return C_PHASE_RED


# =========================================================
# GAME START
# =========================================================

func _start_game():
	game_started = true
	game_over = false
	
	current_lives = MAX_LIVES
	_update_lives_ui()
	
	_clear_round()
	_create_roles()
	_create_items()
	
	_update_lives_ui()
	_update_hud()
	_start_global_timer()


func _clear_round():
	for child in roles_parent.get_children():
		child.queue_free()
	
	for child in items_parent.get_children():
		child.queue_free()
	
	roles.clear()
	items.clear()


# =========================================================
# CREATE ROLES AND ITEMS
# =========================================================

func _create_roles():
	if not ResourceLoader.exists(EMERGENCY_ROLE_SCENE_PATH):
		push_error("No se encontró EmergencyRole.tscn")
		return
	
	var role_scene = load(EMERGENCY_ROLE_SCENE_PATH)
	var screen_size: Vector2 = get_viewport_rect().size
	
	var positions := [
		Vector2(screen_size.x * 0.18, screen_size.y * 0.47),
		Vector2(screen_size.x * 0.39, screen_size.y * 0.47),
		Vector2(screen_size.x * 0.61, screen_size.y * 0.47),
		Vector2(screen_size.x * 0.82, screen_size.y * 0.47)
	]
	
	var role_data: Array = _get_roles_data()
	
	for i in range(role_data.size()):
		var data: Dictionary = role_data[i]
		var texture_path: String = _first_existing_path(data["paths"])
		
		var role = role_scene.instantiate()
		roles_parent.add_child(role)
		
		role.setup(
			data["id"],
			data["name"],
			texture_path,
			positions[i],
			ROLE_SCALE
		)
		
		roles.append(role)


func _create_items():
	if not ResourceLoader.exists(EMERGENCY_ITEM_SCENE_PATH):
		push_error("No se encontró EmergencyItem.tscn")
		return
	
	var item_scene = load(EMERGENCY_ITEM_SCENE_PATH)
	var screen_size: Vector2 = get_viewport_rect().size
	
	var item_data: Array = _get_items_data()
	item_data.shuffle()
	
	total_items = item_data.size()
	
	var tray_slots := [
		Vector2(screen_size.x * 0.17, screen_size.y * 0.855),
		Vector2(screen_size.x * 0.27, screen_size.y * 0.855),
		Vector2(screen_size.x * 0.37, screen_size.y * 0.855),
		Vector2(screen_size.x * 0.47, screen_size.y * 0.855),
		Vector2(screen_size.x * 0.57, screen_size.y * 0.855),
		Vector2(screen_size.x * 0.67, screen_size.y * 0.855),
		Vector2(screen_size.x * 0.77, screen_size.y * 0.855),
		Vector2(screen_size.x * 0.87, screen_size.y * 0.855),
	]
	
	tray_slots.shuffle()
	
	for i in range(item_data.size()):
		var data: Dictionary = item_data[i]
		var texture_path: String = _first_existing_path(data["paths"])
		
		var random_offset := Vector2(
			randf_range(-18.0, 18.0),
			randf_range(-10.0, 10.0)
		)
		
		var item_position: Vector2 = tray_slots[i] + random_offset
		
		var item = item_scene.instantiate()
		items_parent.add_child(item)
		
		item.setup(
			data["id"],
			data["name"],
			data["role"],
			texture_path,
			item_position,
			ITEM_SCALE
		)
		
		if item.has_signal("dropped"):
			if not item.dropped.is_connected(_on_item_dropped):
				item.dropped.connect(_on_item_dropped)
		
		items.append(item)


# =========================================================
# DROP LOGIC
# =========================================================

func _on_item_dropped(item):
	if game_over:
		return
	
	var target_role = _get_matching_role_for_item(item)
	
	if target_role:
		var snap_position: Vector2 = target_role.get_next_item_position()
		target_role.register_item()
		
		item.lock_to_position(snap_position, PLACED_ITEM_SCALE)
		
		placed_items += 1
		_update_hud()
		
		if placed_items >= total_items:
			await get_tree().create_timer(0.35).timeout
			_win_game()
	else:
		item.set_wrong_feedback()
		item.return_to_start()
		_lose_life()


func _get_matching_role_for_item(item):
	for role in roles:
		if not role.can_accept(item.target_role_id):
			continue
		
		var distance: float = item.global_position.distance_to(role.global_position)
		
		if distance <= DROP_DISTANCE:
			return role
	
	return null


# =========================================================
# LIVES
# =========================================================

func _lose_life():
	current_lives -= 1
	current_lives = max(current_lives, 0)
	
	_update_lives_ui()
	_play_damage_effect()
	
	if current_lives <= 0:
		await get_tree().create_timer(0.25).timeout
		_lose_game()


# =========================================================
# WIN / LOSE
# =========================================================

func _on_time_up():
	if game_over:
		return
	
	_lose_game()


func _win_game():
	if game_over:
		return
	
	game_over = true
	game_started = false
	
	_stop_global_timer()
	_disable_items()
	
	if game_result:
		if game_result.has_method("show_win"):
			game_result.show_win()
		elif game_result.has_method("mostrar_ganaste"):
			game_result.mostrar_ganaste()


func _lose_game():
	if game_over:
		return
	
	game_over = true
	game_started = false
	
	_stop_global_timer()
	_disable_items()
	
	if game_result:
		if game_result.has_method("show_lose"):
			game_result.show_lose()
		elif game_result.has_method("mostrar_perdiste"):
			game_result.mostrar_perdiste()


func _disable_items():
	for item in items:
		if item.has_method("set_disabled"):
			item.set_disabled(true)
		else:
			item.locked = true
