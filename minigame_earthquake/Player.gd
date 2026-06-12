# Player.gd
# La chica aparece al centro-inferior de la pantalla, dando la espalda.
# La mesa está FIJA al costado del camino (no sigue a la chica).
# Al esconderse, la chica se desplaza hacia la mesa.
#
# Estados:
#   IDLE    → girl_idle.png
#   WALKING → girl_walk_1..4.png
#   HIDING  → girl_hiding.png  (chica se mueve junto a la mesa, mesa la cubre)
#   WIN     → girl_idle.png tinte verde

extends Node2D

const SCREEN_W = 1152
const SCREEN_H = 648

# Posición fija de la chica en pantalla
const PLAYER_X = SCREEN_W * 0.50
const PLAYER_Y = SCREEN_H * 0.78

const PLAYER_SCALE = Vector2(2.2, 2.2)

# Mesa fija al costado izquierdo del camino
const TABLE_X     = SCREEN_W * 0.34
const TABLE_Y     = SCREEN_H * 0.80
const TABLE_SCALE = Vector2(2.0, 2.0)

# Al esconderse la chica se desplaza hacia la mesa
const HIDING_OFFSET_X = TABLE_X - PLAYER_X   # desplazamiento hacia la mesa
const HIDING_OFFSET_Y = 20.0                  # baja un poco al agacharse

const WALK_FRAME_TIME = 0.12

# ---- Señales ---------------------------------------------------------------
signal safe_zone_reached

# ---- Nodos -----------------------------------------------------------------
var _girl_sprite:  Sprite2D
var _table_sprite: Sprite2D

var _walk_textures:  Array[Texture2D] = []
var _idle_texture:   Texture2D
var _hiding_texture: Texture2D
var _table_texture:  Texture2D

# ---- Estado ----------------------------------------------------------------
enum PlayerState { IDLE, WALKING, HIDING, WIN }
var current_state: PlayerState = PlayerState.IDLE

var _is_holding_button: bool = false
var _earthquake_active:  bool = false

var _walk_frame: int   = 0
var _walk_timer: float = 0.0


func _ready() -> void:
	z_index = 5
	z_as_relative = false

	_load_textures()
	_build_table()
	_build_girl()
	_set_state(PlayerState.IDLE)

	await get_tree().process_frame
	var main = get_parent()
	if main and main.has_signal("earthquake_started"):
		main.earthquake_started.connect(_on_earthquake_started)
		main.earthquake_ended.connect(_on_earthquake_ended)
	else:
		push_warning("Player.gd: No se encontraron las señales earthquake_started/ended en el nodo padre (Main).")


# ---------------------------------------------------------------------------
func _load_textures() -> void:
	_idle_texture   = load("res://minigame_earthquake/assets/sprites/girl_idle.png")   as Texture2D
	_hiding_texture = load("res://minigame_earthquake/assets/sprites/girl_hiding.png") as Texture2D
	_table_texture  = load("res://minigame_earthquake/assets/sprites/table.png")       as Texture2D

	for i in range(1, 5):
		var t = load("res://minigame_earthquake/assets/sprites/girl_walk_%d.png" % i) as Texture2D
		_walk_textures.append(t)

	if _idle_texture   == null: push_error("Player.gd: No se pudo cargar girl_idle.png")
	if _hiding_texture == null: push_error("Player.gd: No se pudo cargar girl_hiding.png")
	if _table_texture  == null: push_error("Player.gd: No se pudo cargar table.png")
	for i in range(_walk_textures.size()):
		if _walk_textures[i] == null:
			push_error("Player.gd: No se pudo cargar girl_walk_%d.png" % (i + 1))


func _build_girl() -> void:
	_girl_sprite          = Sprite2D.new()
	_girl_sprite.centered = true
	_girl_sprite.scale    = PLAYER_SCALE
	_girl_sprite.z_index  = 5
	_girl_sprite.z_as_relative = false
	_girl_sprite.position = Vector2(PLAYER_X, PLAYER_Y)
	add_child(_girl_sprite)

	if _idle_texture:
		_girl_sprite.texture = _idle_texture
	else:
		var cr = ColorRect.new()
		cr.color    = Color(0.95, 0.6, 0.7)
		cr.size     = Vector2(40, 64)
		cr.position = Vector2(-20, -48)
		_girl_sprite.add_child(cr)


func _build_table() -> void:
	_table_sprite          = Sprite2D.new()
	_table_sprite.centered = true
	_table_sprite.scale    = TABLE_SCALE
	_table_sprite.z_index  = 4   # detrás de la chica normalmente
	_table_sprite.z_as_relative = false
	# POSICIÓN FIJA — costado izquierdo del camino
	_table_sprite.position = Vector2(TABLE_X, TABLE_Y)
	add_child(_table_sprite)

	if _table_texture:
		_table_sprite.texture = _table_texture
	else:
		var cr = ColorRect.new()
		cr.color    = Color(0.55, 0.35, 0.2)
		cr.size     = Vector2(80, 50)
		cr.position = Vector2(-40, -25)
		_table_sprite.add_child(cr)


# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if current_state == PlayerState.WALKING:
		_animate_walk(delta)


func _animate_walk(delta: float) -> void:
	if _walk_textures.is_empty():
		return
	_walk_timer += delta
	if _walk_timer >= WALK_FRAME_TIME:
		_walk_timer = 0.0
		_walk_frame = (_walk_frame + 1) % _walk_textures.size()
		var tex = _walk_textures[_walk_frame]
		if tex:
			_girl_sprite.texture = tex


# ---------------------------------------------------------------------------
func _set_state(new_state: PlayerState) -> void:
	current_state = new_state
	match new_state:

		PlayerState.IDLE:
			if _idle_texture:
				_girl_sprite.texture = _idle_texture
			_girl_sprite.modulate = Color.WHITE
			_girl_sprite.position = Vector2(PLAYER_X, PLAYER_Y)
			_table_sprite.z_index = 4   # mesa detrás

		PlayerState.WALKING:
			_walk_frame = 0
			_walk_timer = 0.0
			_girl_sprite.modulate = Color.WHITE
			_girl_sprite.position = Vector2(PLAYER_X, PLAYER_Y)
			_table_sprite.z_index = 4

		PlayerState.HIDING:
			# Chica se desplaza hacia la mesa y se agacha
			if _hiding_texture:
				_girl_sprite.texture = _hiding_texture
			_girl_sprite.modulate = Color.WHITE
			_girl_sprite.position = Vector2(
				PLAYER_X + HIDING_OFFSET_X,
				PLAYER_Y + HIDING_OFFSET_Y
			)
			_table_sprite.z_index = 6   # mesa encima (la cubre)

		PlayerState.WIN:
			if _idle_texture:
				_girl_sprite.texture = _idle_texture
			_girl_sprite.modulate = Color(0.5, 1.0, 0.5)
			_girl_sprite.position = Vector2(PLAYER_X, PLAYER_Y)
			_table_sprite.z_index = 4


# ---------------------------------------------------------------------------
func on_hold_button_pressed() -> void:
	_is_holding_button = true
	if _earthquake_active and current_state != PlayerState.HIDING:
		_set_state(PlayerState.HIDING)

func on_hold_button_released() -> void:
	_is_holding_button = false
	if _earthquake_active and current_state == PlayerState.HIDING:
		_set_state(PlayerState.IDLE)


# ---------------------------------------------------------------------------
func _on_earthquake_started() -> void:
	_earthquake_active = true
	if _is_holding_button:
		_set_state(PlayerState.HIDING)
	else:
		_set_state(PlayerState.IDLE)

func _on_earthquake_ended() -> void:
	_earthquake_active = false
	if current_state != PlayerState.WIN:
		_set_state(PlayerState.WALKING)


# ---------------------------------------------------------------------------
func _on_safe_zone_reached() -> void:
	_set_state(PlayerState.WIN)
	emit_signal("safe_zone_reached")
	get_parent().on_player_reached_safe_zone()
