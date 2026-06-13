# Background.gd
#
# Lógica visual:
#   - Cielo fijo arriba
#   - Camino estático abajo
#   - bg_city.png (casas + cartel) arranca pequeña/lejana y va haciendo zoom
#     conforme avanza el progreso, además de "bajar" un poco para dar la
#     sensación de que el personaje entra en la ciudad (la imagen pasa
#     por encima/tapa parte de la pantalla).
#
# Capas (z):
#   -12  ColorRect azul (relleno cielo)
#   -10  bg_sky.png     (textura cielo, estática)
#   -8   bg_ground.png  (camino, estático)
#   -6   bg_city.png    (ciudad + cartel, zoom + descenso)

extends Node2D

var _sw: float
var _sh: float
var _horizon_y: float

var _city_node: Node2D

var _progress: float = 0.0


func _ready() -> void:
	z_as_relative = false

	var win = DisplayServer.window_get_size()
	_sw = float(win.x)
	_sh = float(win.y)
	_horizon_y = _sh * 0.52

	_build_sky()
	_build_ground()
	_build_city()
	_update_zoom()


# ── CIELO ────────────────────────────────────────────────────────────────────
func _build_sky() -> void:
	var fill           = ColorRect.new()
	fill.color         = Color(0.42, 0.78, 0.98)
	fill.size          = Vector2(_sw, _sh)
	fill.position      = Vector2.ZERO
	fill.z_index       = -12
	fill.z_as_relative = false
	add_child(fill)

	var tex = load("res://minigame_earthquake/assets/backgrounds/bg_sky.png") as Texture2D
	if tex:
		var spr           = Sprite2D.new()
		spr.centered      = false
		spr.texture       = tex
		spr.position      = Vector2.ZERO
		spr.z_index       = -10
		spr.z_as_relative = false
		var sx = _sw        / float(tex.get_width())
		var sy = _horizon_y / float(tex.get_height())
		spr.scale = Vector2(max(sx, sy), max(sx, sy))
		add_child(spr)


# ── CAMINO (estático) ─────────────────────────────────────────────────────────
func _build_ground() -> void:
	var ground_h = _sh - _horizon_y
	var tex = load("res://minigame_earthquake/assets/backgrounds/bg_ground.png") as Texture2D

	if tex:
		var spr           = Sprite2D.new()
		spr.centered      = false
		spr.texture       = tex
		spr.position      = Vector2(0.0, _horizon_y)
		spr.z_index       = -8
		spr.z_as_relative = false
		var sx = _sw      / float(tex.get_width())
		var sy = ground_h / float(tex.get_height())
		spr.scale = Vector2(max(sx, sy), max(sx, sy))
		add_child(spr)
	else:
		var cr            = ColorRect.new()
		cr.color          = Color(0.58, 0.46, 0.32)
		cr.size           = Vector2(_sw, ground_h)
		cr.position       = Vector2(0.0, _horizon_y)
		cr.z_index        = -8
		cr.z_as_relative  = false
		add_child(cr)


# ── CIUDAD + CARTEL (un solo asset) ──────────────────────────────────────────
func _build_city() -> void:
	_city_node               = Node2D.new()
	_city_node.z_index       = -6
	_city_node.z_as_relative = false
	add_child(_city_node)

	# Intenta cargar bg_city.png primero, si no bg_buildings.png como fallback
	var tex = load("res://minigame_earthquake/assets/backgrounds/bg_city.png") as Texture2D
	if tex == null:
		tex = load("res://minigame_earthquake/assets/backgrounds/bg_buildings.png") as Texture2D

	if tex:
		var spr           = Sprite2D.new()
		spr.centered      = false   # origen en esquina superior-izquierda
		spr.texture       = tex
		spr.z_index       = -6
		spr.z_as_relative = false
		_city_node.add_child(spr)
		_city_node.set_meta("tex_w", float(tex.get_width()))
		_city_node.set_meta("tex_h", float(tex.get_height()))
	else:
		# Fallback visual si no hay asset
		var cr      = ColorRect.new()
		cr.color    = Color(0.55, 0.50, 0.45)
		cr.size     = Vector2(_sw, _sh * 0.35)
		cr.z_index       = -6
		cr.z_as_relative = false
		_city_node.add_child(cr)
		var lbl     = Label.new()
		lbl.text    = "CIUDAD  •  ZONA SEGURA"
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size     = Vector2(_sw, 48)
		lbl.position = Vector2(0, _sh * 0.35 * 0.3)
		lbl.z_index       = -6
		lbl.z_as_relative = false
		_city_node.add_child(lbl)
		_city_node.set_meta("tex_w", _sw)
		_city_node.set_meta("tex_h", _sh * 0.35)


# ── ZOOM + DESCENSO ────────────────────────────────────────────────────────────
func _update_zoom() -> void:
	if _city_node == null:
		return

	var tex_w: float = _city_node.get_meta("tex_w")
	var tex_h: float = _city_node.get_meta("tex_h")

	# zoom_cover: el mínimo necesario para que la imagen cubra
	# TODO el ancho y TODO el alto de la pantalla (sin dejar huecos)
	var zoom_cover = max(_sw / tex_w, _sh / tex_h)

	# zoom_min: tamaño inicial (ciudad pequeña/lejana)
	# zoom_max: tamaño final (acercamiento, puede cubrir o exceder pantalla)
	var zoom_min = zoom_cover * 1
	var zoom_max = zoom_cover * 1.2

	var zoom = lerp(zoom_min, zoom_max, _progress)

	var img_w = tex_w * zoom
	var img_h = tex_h * zoom

	# Centrada horizontalmente
	var pos_x = (_sw - img_w) * 0.5

	# BASE de la imagen anclada al horizonte, crece hacia arriba...
	var base_pos_y = _horizon_y - img_h

	# ...pero además "baja" conforme avanza el progreso, dando sensación
	# de que la ciudad desciende y empieza a tapar/pasar por encima del personaje
	var descend_offset = lerp(0.0, _sh * 0.35, _progress)

	var pos_y = base_pos_y + descend_offset

	_city_node.position = Vector2(pos_x, pos_y)
	_city_node.scale    = Vector2(zoom, zoom)


# ── API pública ───────────────────────────────────────────────────────────────
func scroll_step(_speed: float, _delta: float) -> void:
	pass   # sin scroll

func update_progress(p: float) -> void:
	_progress = clamp(p, 0.0, 1.0)
	_update_zoom()

func start_walking() -> void:
	pass

func stop_walking() -> void:
	pass
