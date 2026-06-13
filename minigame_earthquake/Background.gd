# Background.gd — arquitectura con clip correcto del camino
#
# SOLUCIÓN AL PROBLEMA:
# El camino (bg_ground) se renderiza dentro de un Node2D cuyo
# primer sprite empieza en y=0 RELATIVO al contenedor, y el
# contenedor tiene position.y = _horizon_y.
# Al hacer scroll, el contenedor se mueve HACIA ABAJO desde _horizon_y,
# nunca hacia arriba — fmod garantiza que offset >= 0.
# Así el camino físicamente nunca puede estar por encima del horizonte.
#
# Orden visual:
#   ColorRect azul (z=-12) — relleno cielo, toda la pantalla
#   bg_sky texture (z=-10) — nubes, mitad superior, ESTÁTICO
#   bg_buildings  (z=-9)  — franja fija, scroll vertical lento
#   bg_ground     (z=-8)  — mitad inferior, scroll vertical rápido
#   safe_sign     (z=-7)  — se acerca desde los edificios

extends Node2D

const SPEED_BUILDINGS = 0.20
const SPEED_GROUND    = 1.00

const SIGN_SCALE_MIN  = 0.05
const SIGN_SCALE_MAX  = 0.75

var _sw: float
var _sh: float
var _horizon_y: float

var _layer_bld:    Node2D
var _layer_ground: Node2D
var _safe_sign:    Node2D

var _progress: float = 0.0
var _offset_bld:    float = 0.0
var _offset_ground: float = 0.0


func _ready() -> void:
	z_as_relative = false

	var win = DisplayServer.window_get_size()
	_sw = float(win.x)
	_sh = float(win.y)
	_horizon_y = _sh * 0.50

	_build_all()
	_build_safe_zone_sign()


func _build_all() -> void:
	# ── 1. Relleno sólido azul — TODA la pantalla (nunca habrá gris) ──────
	var sky_fill = ColorRect.new()
	sky_fill.color    = Color(0.42, 0.78, 0.98)
	sky_fill.size     = Vector2(_sw, _sh)
	sky_fill.position = Vector2.ZERO
	sky_fill.z_index  = -12
	sky_fill.z_as_relative = false
	add_child(sky_fill)

	# ── 2. Textura del cielo — mitad superior, ESTÁTICA ───────────────────
	var sky_tex = load("res://minigame_earthquake/assets/backgrounds/bg_sky.png") as Texture2D
	if sky_tex:
		var spr = Sprite2D.new()
		spr.centered      = false
		spr.z_index       = -10
		spr.z_as_relative = false
		spr.position      = Vector2.ZERO
		spr.texture       = sky_tex
		var sx = max(_sw        / float(sky_tex.get_width()),  1.0)
		var sy = max(_horizon_y / float(sky_tex.get_height()), 1.0)
		spr.scale = Vector2(max(sx,sy), max(sx,sy))
		add_child(spr)

	# ── 3. EDIFICIOS — siempre visibles en la franja del horizonte ────────
	#    Franja de alto = 30% de la pantalla, centrada en el horizonte.
	#    Dos copias en bucle vertical (scroll lento hacia abajo).
	var bld_h      = _sh * 0.30
	var bld_origin = _horizon_y - bld_h * 0.70   # 70% por encima, 30% por debajo

	_layer_bld = _make_looping_layer(
		"res://minigame_earthquake/assets/backgrounds/bg_buildings.png",
		Color(0.62, 0.55, 0.48), -9, bld_origin, bld_h
	)

	# ── 4. CAMINO — ocupa desde _horizon_y hasta el fondo ─────────────────
	#    El contenedor empieza en _horizon_y.
	#    offset siempre >= 0 (fmod de valor positivo), así que
	#    el camino NUNCA sube por encima de _horizon_y.
	var ground_h = _sh - _horizon_y

	_layer_ground = _make_looping_layer(
		"res://minigame_earthquake/assets/backgrounds/bg_ground.png",
		Color(0.58, 0.46, 0.32), -8, _horizon_y, ground_h
	)


# Crea un Node2D con 2 Sprite2D apilados verticalmente para loop continuo.
# El contenedor se posiciona en origin_y; los sprites son relativos a él.
func _make_looping_layer(path: String, fallback: Color,
		z: int, origin_y: float, target_h: float) -> Node2D:

	var container = Node2D.new()
	container.z_index       = z
	container.z_as_relative = false
	container.position      = Vector2(0.0, origin_y)
	add_child(container)

	var tex       = load(path) as Texture2D
	var tile_h    = target_h
	var scale_val = 1.0

	if tex:
		var sx = max(_sw      / float(tex.get_width()),  1.0)
		var sy = max(target_h / float(tex.get_height()), 1.0)
		scale_val = max(sx, sy)
		tile_h    = tex.get_height() * scale_val

	for i in range(2):
		var spr = Sprite2D.new()
		spr.centered      = false
		spr.z_index       = z
		spr.z_as_relative = false
		if tex:
			spr.texture = tex
			spr.scale   = Vector2(scale_val, scale_val)
		else:
			var cr = ColorRect.new()
			cr.color = fallback
			cr.size  = Vector2(_sw, tile_h)
			spr.add_child(cr)
		spr.position = Vector2(0.0, tile_h * float(i))
		container.add_child(spr)

	container.set_meta("origin_y", origin_y)
	container.set_meta("tile_h",   tile_h)
	return container


# ---------------------------------------------------------------------------
func scroll_step(speed: float, delta: float) -> void:
	_offset_bld    += speed * SPEED_BUILDINGS * delta
	_offset_ground += speed * SPEED_GROUND    * delta

	_apply_scroll(_layer_bld,    _offset_bld)
	_apply_scroll(_layer_ground, _offset_ground)


func _apply_scroll(layer: Node2D, offset: float) -> void:
	if layer == null:
		return
	var tile_h:   float = layer.get_meta("tile_h")
	var origin_y: float = layer.get_meta("origin_y")
	# offset es siempre >= 0 → position.y >= origin_y
	# El camino NUNCA puede subir por encima de su origin_y
	layer.position.y = origin_y + fmod(offset, tile_h)


# ---------------------------------------------------------------------------
func update_progress(p: float) -> void:
	_progress = clamp(p, 0.0, 1.0)
	_update_sign_transform()


func _update_sign_transform() -> void:
	if _safe_sign == null:
		return
	var t  = _progress
	var s  = lerp(SIGN_SCALE_MIN, SIGN_SCALE_MAX, t)
	_safe_sign.scale = Vector2(s, s)

	# La señal va desde el fondo de los edificios hasta cerca del horizonte.
	# Zona de edificios: horizon_y - bld_h*0.70  a  horizon_y + bld_h*0.30
	var bld_h   = _sh * 0.30
	var sign_y0 = _horizon_y - bld_h * 0.60   # lejos (pequeña)
	var sign_y1 = _horizon_y - bld_h * 0.05   # cerca (grande)
	_safe_sign.position = Vector2(_sw * 0.50, lerp(sign_y0, sign_y1, t))


func _build_safe_zone_sign() -> void:
	_safe_sign = Node2D.new()
	_safe_sign.z_index       = -7
	_safe_sign.z_as_relative = false
	add_child(_safe_sign)

	var tex = load("res://minigame_earthquake/assets/backgrounds/safe_zone_sign.png") as Texture2D
	if tex:
		var spr = Sprite2D.new()
		spr.texture  = tex
		spr.centered = true
		_safe_sign.add_child(spr)
	else:
		var bg = ColorRect.new()
		bg.color    = Color(0.1, 0.55, 0.1)
		bg.size     = Vector2(240, 72)
		bg.position = Vector2(-120, -72)
		_safe_sign.add_child(bg)

		var lbl = Label.new()
		lbl.text = "ZONA SEGURA"
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_font_size_override("font_size", 26)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size     = Vector2(240, 72)
		lbl.position = Vector2(-120, -72)
		_safe_sign.add_child(lbl)

		var pole = ColorRect.new()
		pole.color    = Color(0.55, 0.55, 0.55)
		pole.size     = Vector2(10, 100)
		pole.position = Vector2(-5, 0)
		_safe_sign.add_child(pole)

	_update_sign_transform()


func start_walking() -> void:
	pass

func stop_walking() -> void:
	pass
