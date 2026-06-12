extends CharacterBody2D

# ─── Config ───────────────────────────────────────────────────────────────────
@export var walk_speed: float = 120.0

# ─── State ────────────────────────────────────────────────────────────────────
enum PlayerState { IDLE, HIDING, WALKING, WIN }
var current_state: PlayerState = PlayerState.IDLE
var is_holding_button: bool = false
var earthquake_active: bool = false

# ─── Node references ──────────────────────────────────────────────────────────
@onready var girl_sprite:   AnimatedSprite2D = $GirlSprite
@onready var hiding_sprite: Sprite2D         = $HidingSprite
@onready var main_node:     Node2D           = get_parent()

func _ready() -> void:
	hiding_sprite.visible = false
	girl_sprite.visible = true
	_play_animation("idle")
	# Conectar señales del juego
	main_node.earthquake_started.connect(_on_earthquake_started)
	main_node.earthquake_ended.connect(_on_earthquake_ended)

func _physics_process(delta: float) -> void:
	match current_state:
		PlayerState.WALKING:
			_do_walk(delta)

# ─── Movement ─────────────────────────────────────────────────────────────────
func _do_walk(delta: float) -> void:
	# La niña está fija en X; el fondo se mueve en background.gd
	# Actualizar barra de progreso en HUD
	var hud = get_node("/root/Main/HUD")
	# El progreso lo maneja background.gd, acá sólo animamos
	pass

# ─── Button events (llamados desde hud.gd vía señal) ─────────────────────────
func on_hold_button_pressed() -> void:
	is_holding_button = true
	if earthquake_active:
		_enter_hiding()

func on_hold_button_released() -> void:
	is_holding_button = false
	if earthquake_active and current_state == PlayerState.HIDING:
		# Soltó el botón durante el terremoto → pierde vida
		_exit_hiding_without_earthquake_end()
		main_node.on_button_released_during_earthquake()

# ─── State transitions ────────────────────────────────────────────────────────
func _enter_hiding() -> void:
	current_state = PlayerState.HIDING
	girl_sprite.visible = false
	hiding_sprite.visible = true

func _exit_hiding_without_earthquake_end() -> void:
	# Quedó expuesta, vuelve a idle para la penalización
	current_state = PlayerState.IDLE
	hiding_sprite.visible = false
	girl_sprite.visible = true
	_play_animation("idle")

func _enter_walking() -> void:
	current_state = PlayerState.WALKING
	hiding_sprite.visible = false
	girl_sprite.visible = true
	_play_animation("walk")
	# Avisar al fondo que empiece a scrollear rápido
	get_node("/root/Main/Background").start_walking()

func _enter_win() -> void:
	current_state = PlayerState.WIN
	_play_animation("idle")

# ─── Signal handlers ──────────────────────────────────────────────────────────
func _on_earthquake_started() -> void:
	earthquake_active = true
	# Si ya está presionando el botón, entra a HIDING automáticamente
	if is_holding_button:
		_enter_hiding()

func _on_earthquake_ended() -> void:
	earthquake_active = false
	if current_state == PlayerState.HIDING:
		# Estaba bien escondida → ahora puede caminar
		_enter_walking()
	elif current_state == PlayerState.IDLE:
		# No se escondió a tiempo pero sobrevivió (ya perdió vida antes)
		_enter_walking()

# ─── Safe zone ────────────────────────────────────────────────────────────────
func _on_safe_zone_reached() -> void:
	current_state = PlayerState.WIN
	_enter_win()
	main_node.on_player_reached_safe_zone()

# ─── Animation helper ─────────────────────────────────────────────────────────
func _play_animation(anim_name: String) -> void:
	if girl_sprite.sprite_frames and girl_sprite.sprite_frames.has_animation(anim_name):
		girl_sprite.play(anim_name)
