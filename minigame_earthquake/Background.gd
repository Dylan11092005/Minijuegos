# Background.gd  — scroll VERTICAL para simular avance "de frente"
#
# Capas (de más lejos a más cerca):
#   _layer_sky       → casi no se mueve   (SPEED_SKY       = 0.05)
#   _layer_buildings → velocidad media    (SPEED_BUILDINGS  = 0.30)
#   _layer_ground    → se mueve rápido    (SPEED_GROUND     = 1.00)
#
# Cada capa usa DOS copias apiladas verticalmente para un loop sin salto.
# El scroll es hacia ABAJO → ilusión de avanzar "hacia el fondo".

extends Node2D

const SCREEN_W = 1152
const SCREEN_H = 648

const HORIZON_Y      = SCREEN_H * 0.42
const HORIZON_X      = SCREEN_W * 0.50
const SIGN_SCALE_MIN = 0.15
const SIGN_SCALE_MAX = 1.05
const SIGN_ARRIVAL_Y = SCREEN_H * 0.52

const SPEED_SKY       = 0.05
const SPEED_BUILDINGS = 0.30
const SPEED_GROUND    = 1.00

var _layer_sky:       Node2D
var _layer_buildings: Node2D
var _layer_ground:    Node2D

var _safe_sign: Node2D
var _progress:  float = 0.0

var _offset_sky:       float = 0.0
var _offset_buildings: float = 0.0
var _offset_ground:    float = 0.0


func _ready() -> void:
	z_as_relative = false
	_build_background()
	_build_safe_zone_sign()


# ---------------------------------------------------------------------------
func _build_background() -> void:
	_layer_sky = _make_vertical_layer(
		"res://minigame_earthquake/assets/backgrounds/bg_sky.png",
		Color(0.55, 0.80, 0.95),
		-10,
		0.0,
		SCREEN_H * 0.55
	)

	_layer_buildings = _make_vertical_layer(
		"res://minigame_earthquake/assets/backgrounds/bg_buildings.png",
		Color(0.55, 0.50, 0.45),
		-9,
		SCREEN_H * 0.22,
		SCREEN_H * 0.60
	)

	_layer_ground = _make_vertical_layer(
		"res://minigame_earthquake/assets/backgrounds/bg_ground.png",
		Color(0.40, 0.38, 0.35),
		-8,
		SCREEN_H * 0.42,
		SCREEN_H * 0.58
	)


# Crea un Node2D contenedor con 2 copias de la textura apiladas verticalmente.
# Copia A en y=0, copia B en y=tile_h → loop continuo sin saltos.
func _make_vertical_layer(path: String, fallback: Color,
		z: int, origin_y: float, target_h: float) -> Node2D:

	var container = Node2D.new()
	container.z_index = z
	container.z_as_relative = false
	container.position = Vector2(0.0, origin_y)
	add_child(container)

	var tex = load(path) as Texture2D
	var tile_h: float = target_h

	for i in range(2):
		var spr = Sprite2D.new()
		spr.centered = false
		spr.z_index = z
		spr.z_as_relative = false

		if tex:
			spr.texture = tex
			var sx = max(float(SCREEN_W) / float(tex.get_width()),  1.0)
			var sy = max(target_h        / float(tex.get_height()), 1.0)
			var s  = max(sx, sy)
			spr.scale = Vector2(s, s)
			tile_h = tex.get_height() * s
		else:
			var cr = ColorRect.new()
			cr.color = fallback
			cr.size  = Vector2(SCREEN_W, target_h)
			spr.add_child(cr)
			tile_h = target_h

		spr.position = Vector2(0.0, tile_h * float(i))
		container.add_child(spr)

	container.set_meta("origin_y", origin_y)
	container.set_meta("tile_h",   tile_h)
	return container


# ---------------------------------------------------------------------------
func scroll_step(speed: float, delta: float) -> void:
	_offset_sky       += speed * SPEED_SKY       * delta
	_offset_buildings += speed * SPEED_BUILDINGS * delta
	_offset_ground    += speed * SPEED_GROUND    * delta

	_apply_scroll(_layer_sky,       _offset_sky)
	_apply_scroll(_layer_buildings, _offset_buildings)
	_apply_scroll(_layer_ground,    _offset_ground)


func _apply_scroll(layer: Node2D, offset: float) -> void:
	if layer == null:
		return
	var tile_h:   float = layer.get_meta("tile_h")
	var origin_y: float = layer.get_meta("origin_y")
	# offset crece → capas bajan → ilusión de avanzar hacia el fondo
	layer.position.y = origin_y + fmod(offset, tile_h)


# ---------------------------------------------------------------------------
func update_progress(p: float) -> void:
	_progress = clamp(p, 0.0, 1.0)
	_update_sign_transform()


func _update_sign_transform() -> void:
	if _safe_sign == null:
		return
	var t = _progress
	var s = lerp(SIGN_SCALE_MIN, SIGN_SCALE_MAX, t)
	_safe_sign.scale    = Vector2(s, s)
	_safe_sign.position = Vector2(
		HORIZON_X,
		lerp(HORIZON_Y, SIGN_ARRIVAL_Y, t)
	)


# ---------------------------------------------------------------------------
func _build_safe_zone_sign() -> void:
	_safe_sign = Node2D.new()
	_safe_sign.z_index = 2
	_safe_sign.z_as_relative = false
	add_child(_safe_sign)

	var tex = load("res://minigame_earthquake/assets/backgrounds/safe_zone_sign.png") as Texture2D
	if tex:
		var spr = Sprite2D.new()
		spr.texture = tex
		spr.centered = true
		_safe_sign.add_child(spr)
	else:
		var bg = ColorRect.new()
		bg.color    = Color(0.1, 0.6, 0.1)
		bg.size     = Vector2(260, 80)
		bg.position = Vector2(-130, -80)
		_safe_sign.add_child(bg)

		var lbl = Label.new()
		lbl.text = "ZONA SEGURA"
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size     = Vector2(260, 80)
		lbl.position = Vector2(-130, -80)
		_safe_sign.add_child(lbl)

		var pole = ColorRect.new()
		pole.color    = Color(0.6, 0.6, 0.6)
		pole.size     = Vector2(12, 120)
		pole.position = Vector2(-6, 0)
		_safe_sign.add_child(pole)

	_update_sign_transform()


# Compat con versiones anteriores
func start_walking() -> void:
	pass

func stop_walking() -> void:
	pass
