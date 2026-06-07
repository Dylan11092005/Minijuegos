## MapPuzzle.gd
## Minijuego: Rompecabezas de Mapa
## Godot 4.x

extends Node2D

signal puzzle_completed
signal puzzle_failed

# =========================================================
# CONFIGURACIÓN
# =========================================================
@export var map_texture: Texture2D
@export var background_texture: Texture2D
@export var cols: int = 4
@export var rows: int = 3
@export var piece_gap: int = 6

const TOTAL_TIME = 60.0

# =========================================================
# ESCENAS GLOBALES
# =========================================================
const TIMER_HUD_SCENE      = preload("res://ui_global/timer_ui.tscn")
const PANEL_RESULTADO_SCENE = preload("res://ui_global/ResultadoJuego.tscn")

# =========================================================
# RESOLUCIÓN
# =========================================================
const SCREEN_SIZE = Vector2(1920, 1080)
const MODAL_SIZE  = Vector2(1600, 920)

# =========================================================
# VARIABLES
# =========================================================
var piece_size: Vector2
var pieces: Array = []

var selected_index: int = -1
var game_active: bool   = false

# =========================================================
# UI
# =========================================================
var modal:           Panel
var board_container: Node2D
var guide_preview:   TextureRect

var timer_hud:       CanvasLayer
var panel_resultado: CanvasLayer

# =========================================================
# COLORES
# =========================================================
const COLOR_GOLD     = Color("#D4AF37")
const COLOR_SELECTED = Color(1.0, 0.878, 0.251, 0.35)
const COLOR_CORRECT  = Color(0.251, 1.0, 0.502, 0.2)

# =========================================================
# READY
# =========================================================
func _ready() -> void:
	timer_hud = TIMER_HUD_SCENE.instantiate()
	add_child(timer_hud)
	timer_hud.tiempo_agotado.connect(_on_tiempo_agotado)
	timer_hud.set_tamano_panel(600, 60)

	panel_resultado = PANEL_RESULTADO_SCENE.instantiate()
	add_child(panel_resultado)

	_build_ui()

	if map_texture:
		_start_game()

# =========================================================
# PROCESS
# =========================================================
func _process(_delta: float) -> void:
	pass

# =========================================================
# START GAME
# =========================================================
func _start_game() -> void:
	_clear_pieces()

	selected_index = -1
	game_active    = true

	if map_texture == null:
		return

	guide_preview.texture = map_texture

	var available_width  = 1050.0
	var available_height = 620.0

	piece_size = Vector2(
		available_width  / cols,
		available_height / rows
	)

	_create_pieces()
	_shuffle_pieces()
	_animate_modal()

	timer_hud.iniciar(TOTAL_TIME, "Tiempo restante", "para completar el mapa")

# =========================================================
# CREAR PIEZAS
# =========================================================
func _create_pieces() -> void:
	var image: Image = map_texture.get_image()

	var original_piece_size = Vector2(
		map_texture.get_width()  / cols,
		map_texture.get_height() / rows
	)

	for row in rows:
		for col in cols:
			var index: int = row * cols + col

			var region := Rect2i(
				col * int(original_piece_size.x),
				row * int(original_piece_size.y),
				int(original_piece_size.x),
				int(original_piece_size.y)
			)

			var piece_image := image.get_region(region)
			var piece_tex   := ImageTexture.create_from_image(piece_image)

			var sprite := Sprite2D.new()
			sprite.texture  = piece_tex
			sprite.centered = false
			sprite.scale    = Vector2(
				piece_size.x / original_piece_size.x,
				piece_size.y / original_piece_size.y
			)

			board_container.add_child(sprite)

			var highlight := ColorRect.new()
			highlight.size         = piece_size - Vector2(piece_gap * 2, piece_gap * 2)
			highlight.color        = Color.TRANSPARENT
			highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE

			sprite.add_child(highlight)
			highlight.position = Vector2(piece_gap, piece_gap)

			pieces.append({
				"sprite":      sprite,
				"highlight":   highlight,
				"correct_pos": index,
				"current_pos": index
			})

# =========================================================
# SHUFFLE
# =========================================================
func _shuffle_pieces() -> void:
	var positions: Array = range(cols * rows)
	positions.shuffle()
	for i in pieces.size():
		pieces[i]["current_pos"] = positions[i]
	_apply_positions()

# =========================================================
# POSICIONES
# =========================================================
func _apply_positions() -> void:
	var start_x = 70
	var start_y = 240

	for piece in pieces:
		var pos_index: int = piece["current_pos"]
		var col: int = pos_index % cols
		var row: int = pos_index / cols

		var target := Vector2(
			start_x + col * (piece_size.x + piece_gap),
			start_y + row * (piece_size.y + piece_gap)
		)

		piece["sprite"].position = target

	_refresh_highlights()

# =========================================================
# INPUT
# =========================================================
func _input(event: InputEvent) -> void:
	if not game_active:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var clicked_index = _get_piece_at(event.position)

			if clicked_index == -1:
				return

			if selected_index == -1:
				selected_index = clicked_index

			elif selected_index == clicked_index:
				selected_index = -1

			else:
				_swap_pieces(selected_index, clicked_index)
				selected_index = -1
				_check_win()

			_refresh_highlights()

# =========================================================
# DETECTAR PIEZA
# =========================================================
func _get_piece_at(pos: Vector2) -> int:
	for i in pieces.size():
		var p     = pieces[i]
		var p_pos = p["sprite"].global_position
		var rect  = Rect2(p_pos, piece_size)
		if rect.has_point(pos):
			return i
	return -1

# =========================================================
# SWAP
# =========================================================
func _swap_pieces(a: int, b: int) -> void:
	var temp_pos             = pieces[a]["current_pos"]
	pieces[a]["current_pos"] = pieces[b]["current_pos"]
	pieces[b]["current_pos"] = temp_pos
	_apply_positions()

# =========================================================
# HIGHLIGHTS
# =========================================================
func _refresh_highlights() -> void:
	for i in pieces.size():
		var p         = pieces[i]
		var highlight = p["highlight"]
		var is_sel    = (i == selected_index)
		var is_ok     = (p["current_pos"] == p["correct_pos"])

		if is_sel:
			highlight.color = COLOR_SELECTED
		elif is_ok:
			highlight.color = COLOR_CORRECT
		else:
			highlight.color = Color.TRANSPARENT

# =========================================================
# WIN CHECK
# =========================================================
func _check_win() -> void:
	for piece in pieces:
		if piece["current_pos"] != piece["correct_pos"]:
			return
	_win()

# =========================================================
# WIN / LOSE
# =========================================================
func _win() -> void:
	game_active = false
	timer_hud.detener()
	panel_resultado.mostrar_ganaste()
	emit_signal("puzzle_completed")

func _lose() -> void:
	game_active = false
	timer_hud.detener()
	panel_resultado.mostrar_perdiste()
	emit_signal("puzzle_failed")

# =========================================================
# CALLBACK TIMER
# =========================================================
func _on_tiempo_agotado() -> void:
	if game_active:
		_lose()

# =========================================================
# BUILD UI
# =========================================================
func _build_ui() -> void:

	# --- Fondo ---
	if background_texture:
		var bg := TextureRect.new()
		bg.texture      = background_texture
		bg.size         = SCREEN_SIZE
		bg.position     = Vector2.ZERO
		bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(bg)

	# --- Modal ---
	modal          = Panel.new()
	modal.size     = MODAL_SIZE
	modal.position = (SCREEN_SIZE - MODAL_SIZE) / 2
	add_child(modal)

	var style := StyleBoxFlat.new()
	style.bg_color            = Color(0, 0, 0, 0.0)
	style.border_width_left   = 0
	style.border_width_top    = 0
	style.border_width_right  = 0
	style.border_width_bottom = 0
	modal.add_theme_stylebox_override("panel", style)

	board_container = Node2D.new()
	modal.add_child(board_container)



	# --- Mini mapa de referencia ---
	var preview_border      := Panel.new()
	preview_border.position  = Vector2(1260, 40)
	preview_border.size      = Vector2(280, 200)

	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color                   = Color(0, 0, 0, 0.2)
	preview_style.border_width_left          = 3
	preview_style.border_width_top           = 3
	preview_style.border_width_right         = 3
	preview_style.border_width_bottom        = 3
	preview_style.border_color               = COLOR_GOLD
	preview_style.corner_radius_top_left     = 10
	preview_style.corner_radius_top_right    = 10
	preview_style.corner_radius_bottom_left  = 10
	preview_style.corner_radius_bottom_right = 10
	preview_border.add_theme_stylebox_override("panel", preview_style)
	modal.add_child(preview_border)

	guide_preview              = TextureRect.new()
	guide_preview.position     = Vector2(1275, 55)
	guide_preview.size         = Vector2(250, 170)
	guide_preview.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	guide_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	modal.add_child(guide_preview)
	guide_preview.move_to_front()

# =========================================================
# ANIMACIÓN MODAL
# =========================================================
func _animate_modal() -> void:
	modal.scale = Vector2(0.8, 0.8)
	var tween   = create_tween()
	tween.tween_property(modal, "scale", Vector2.ONE, 0.2)

# =========================================================
# CLEAR
# =========================================================
func _clear_pieces() -> void:
	for piece in pieces:
		piece["sprite"].queue_free()
	pieces.clear()
