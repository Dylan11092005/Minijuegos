extends Area2D
# =========================================================
# CONFIGURACIÓN DE ROCA
# =========================================================
const ASSETS_DIR := "res://Minigames/minigame_landslide/assets/"
const ROTATION_SPEED := 7.5
const ROCK_SCALE := Vector2(0.16, 0.16)
# Si tu roca es sprite sheet de 3 frames, esto lo anima.
# Si es una sola imagen normal, también funciona sin problema.
const FRAME_COUNT := 3
const FRAME_WIDTH := 512
const FRAME_HEIGHT := 864
const ANIMATION_SPEED := 10.0
# Radio de respaldo si por alguna razón no se puede calcular desde el sprite
# (p. ej. textura comprimida en VRAM sin acceso a píxeles en el build exportado)
const COLLISION_RADIUS_FALLBACK := 20.0
# Qué tan chico es el círculo de colisión respecto al ancho visual REAL
# (bounding box de píxeles opacos) del sprite. 1.0 = ajustado exacto al
# contenido opaco; valores menores lo encogen un poco más para que se
# sienta "justo" y no injustamente grande.
const COLLISION_SHRINK := 0.85
# Umbral de alfa por debajo del cual un píxel se considera "transparente"
# y por lo tanto NO cuenta para el bounding box visual real.
const ALPHA_THRESHOLD := 0.15
# Límites duros: pase lo que pase con el cálculo, el radio nunca sale de
# este rango. Esto evita círculos gigantes si algún factor de escala raro
# de la escena infla el cálculo, o círculos absurdamente chicos si el
# análisis de píxeles falla de forma silenciosa.
const COLLISION_RADIUS_MIN := 8.0
const COLLISION_RADIUS_MAX := 28.0

# Caché estática: evita re-analizar los píxeles de la misma textura cada
# vez que spawnea una roca nueva. Clave = resource_path de la textura,
# Valor = radio "base" (en píxeles de la textura, SIN escala aplicada).
static var _radius_cache: Dictionary = {}

var start_position := Vector2.ZERO
var end_position := Vector2.ZERO
var speed := 160.0
var distance := 1.0
var progress := 0.0
var active := false
var rotation_speed := ROTATION_SPEED
var animation_time := 0.0
var current_frame := 0

# Multiplicador de tamaño de ESTA roca en particular (1.0 = tamaño normal
# ROCK_SCALE). El manager del minijuego lo asigna al llamar setup() para
# variar el tamaño roca por roca. Las rocas más grandes rotan un poco más
# lento (se sienten "más pesadas"); las más chicas rotan más rápido.
var size_multiplier := 1.0

@onready var rock_sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var hitbox: Area2D = get_node_or_null("Hitbox") as Area2D


func setup(p_start: Vector2, p_end: Vector2, p_speed: float, p_size_multiplier: float = 1.0) -> void:
	start_position = p_start
	end_position = p_end
	speed = p_speed
	size_multiplier = clampf(p_size_multiplier, 0.5, 2.0)
	# Rocas grandes rotan un poco más lento (se sienten más pesadas),
	# rocas chicas rotan un poco más rápido. Esto es puramente visual,
	# no afecta la colisión.
	rotation_speed = ROTATION_SPEED / size_multiplier
	global_position = start_position
	distance = max(start_position.distance_to(end_position), 1.0)
	progress = 0.0
	active = true
	_setup_sprite()


func _ready() -> void:
	if rock_sprite == null:
		rock_sprite = get_node_or_null("RockSprite") as Sprite2D
	if rock_sprite == null:
		rock_sprite = Sprite2D.new()
		rock_sprite.name = "Sprite2D"
		add_child(rock_sprite)

	_setup_sprite()
	call_deferred("_setup_collision")

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = false


func _setup_collision() -> void:
	# Capa 4 = "roca", detecta capa 1 = "jugador"
	collision_layer = 4
	collision_mask = 1
	monitoring = true
	monitorable = false

	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D

	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		add_child(shape_node)

	# Si el diseñador ya puso una forma manualmente en el editor (dentro de
	# FallingRock.tscn), la respetamos y no la tocamos.
	if shape_node.shape != null:
		return

	var radius := _compute_collision_radius()

	var circle := CircleShape2D.new()
	circle.radius = radius
	shape_node.shape = circle


# ---------------------------------------------------------
# Cálculo del radio de colisión a partir del contenido
# VISUAL REAL de la roca (bounding box de píxeles opacos),
# no del tamaño total del frame del spritesheet (que suele
# tener márgenes transparentes para permitir la rotación
# sin recortes, y eso era lo que inflaba la hitbox antes).
# ---------------------------------------------------------
func _compute_collision_radius() -> float:
	if rock_sprite == null or rock_sprite.texture == null:
		return COLLISION_RADIUS_FALLBACK

	var texture := rock_sprite.texture
	var cache_key: String = texture.resource_path

	var base_radius: float

	if cache_key != "" and _radius_cache.has(cache_key):
		base_radius = _radius_cache[cache_key]
	else:
		base_radius = _analyze_texture_radius(texture)

		if cache_key != "":
			_radius_cache[cache_key] = base_radius

	var radius: float = base_radius * rock_sprite.scale.x
	radius = clampf(radius, COLLISION_RADIUS_MIN, COLLISION_RADIUS_MAX)
	return radius


# Analiza los píxeles del PRIMER frame (o de toda la imagen si no hay
# spritesheet) y devuelve el radio "base" en píxeles de textura (sin
# escala del nodo aplicada), calculado desde el bounding box real de
# píxeles con alfa por encima de ALPHA_THRESHOLD.
func _analyze_texture_radius(texture: Texture2D) -> float:
	var image := texture.get_image()

	# get_image() puede devolver null si la textura está comprimida en
	# VRAM sin acceso a CPU (típico en builds exportados con ciertos
	# formatos de compresión). En ese caso, usamos el respaldo basado
	# en el tamaño del frame, como antes.
	if image == null:
		return _fallback_frame_radius()

	# Necesitamos el canal alfa en un formato legible por pixel.
	if image.is_compressed():
		image.decompress()

	var frame_rect: Rect2i

	if rock_sprite.region_enabled:
		frame_rect = Rect2i(0, 0, FRAME_WIDTH, FRAME_HEIGHT)
	else:
		frame_rect = Rect2i(0, 0, image.get_width(), image.get_height())

	# Aseguramos que el rect no se salga de los límites reales de la imagen.
	frame_rect = frame_rect.intersection(Rect2i(0, 0, image.get_width(), image.get_height()))

	if frame_rect.size.x <= 0 or frame_rect.size.y <= 0:
		return _fallback_frame_radius()

	var min_x := frame_rect.size.x
	var max_x := 0
	var min_y := frame_rect.size.y
	var max_y := 0
	var found_opaque_pixel := false

	# Paso de muestreo para no escanear pixel por pixel en imágenes grandes
	# (esto se ejecuta una sola vez por textura gracias al caché, pero aun
	# así conviene no ser costoso).
	var step := 2

	for y in range(frame_rect.position.y, frame_rect.position.y + frame_rect.size.y, step):
		for x in range(frame_rect.position.x, frame_rect.position.x + frame_rect.size.x, step):
			var alpha := image.get_pixel(x, y).a

			if alpha > ALPHA_THRESHOLD:
				found_opaque_pixel = true
				var local_x := x - frame_rect.position.x
				var local_y := y - frame_rect.position.y

				if local_x < min_x:
					min_x = local_x
				if local_x > max_x:
					max_x = local_x
				if local_y < min_y:
					min_y = local_y
				if local_y > max_y:
					max_y = local_y

	if not found_opaque_pixel:
		return _fallback_frame_radius()

	var opaque_width := float(max_x - min_x)
	var opaque_height := float(max_y - min_y)

	# Usamos el promedio entre ancho y alto real del contenido opaco para
	# no favorecer un eje sobre otro (la roca no es perfectamente circular).
	var opaque_size := (opaque_width + opaque_height) / 2.0

	if opaque_size <= 0.0:
		return _fallback_frame_radius()

	return (opaque_size / 2.0) * COLLISION_SHRINK


# Respaldo: el cálculo viejo basado en el tamaño del frame completo,
# usado solo si el análisis de píxeles no se pudo hacer.
func _fallback_frame_radius() -> float:
	var frame_width: float

	if rock_sprite.region_enabled:
		frame_width = FRAME_WIDTH
	else:
		frame_width = rock_sprite.texture.get_size().x

	if frame_width <= 0.0:
		return COLLISION_RADIUS_FALLBACK

	return (frame_width / 2.0) * COLLISION_SHRINK


func _on_body_entered(body: Node) -> void:
	if get_meta("hit_player", false):
		return

	if not body.is_in_group("player"):
		return

	set_meta("hit_player", true)

	var managers := get_tree().get_nodes_in_group("game_manager")

	if managers.size() > 0 and managers[0].has_method("_register_rock_hit"):
		managers[0]._register_rock_hit(self, body)

	active = false
	queue_free()


func _process(delta: float) -> void:
	if not active:
		return
	progress += (speed * delta) / distance
	progress = clamp(progress, 0.0, 1.0)
	global_position = start_position.lerp(end_position, progress)
	rotation += rotation_speed * delta
	_update_animation(delta)
	if progress >= 1.0:
		active = false
		queue_free()


func _setup_sprite() -> void:
	if rock_sprite == null:
		return
	if rock_sprite.texture == null:
		var rock_texture := _load_texture(["rock", "roca", "piedra"])
		if rock_texture:
			rock_sprite.texture = rock_texture
	rock_sprite.centered = true
	rock_sprite.z_index = 35
	if rock_sprite.texture:
		var texture_size := rock_sprite.texture.get_size()
		# Si parece sprite sheet, activa región.
		if texture_size.x >= FRAME_WIDTH * FRAME_COUNT and texture_size.y >= FRAME_HEIGHT:
			rock_sprite.region_enabled = true
			rock_sprite.region_rect = Rect2(0, 0, FRAME_WIDTH, FRAME_HEIGHT)
			rock_sprite.scale = ROCK_SCALE * size_multiplier
		else:
			rock_sprite.region_enabled = false
			var desired_width := 70.0 * size_multiplier
			if texture_size.x > 0:
				var final_scale := desired_width / texture_size.x
				rock_sprite.scale = Vector2(final_scale, final_scale)


func _update_animation(delta: float) -> void:
	if rock_sprite == null:
		return
	if rock_sprite.texture == null:
		return
	if not rock_sprite.region_enabled:
		return
	animation_time += delta * ANIMATION_SPEED
	var new_frame: int = int(animation_time) % FRAME_COUNT
	if new_frame == current_frame:
		return
	current_frame = new_frame
	rock_sprite.region_rect = Rect2(
		current_frame * FRAME_WIDTH,
		0,
		FRAME_WIDTH,
		FRAME_HEIGHT
	)


func _load_texture(keywords: Array) -> Texture2D:
	var dir := DirAccess.open(ASSETS_DIR)
	if dir == null:
		return null
	for file in dir.get_files():
		var extension := file.get_extension().to_lower()
		if extension not in ["png", "jpg", "jpeg", "webp"]:
			continue
		var lower := file.to_lower()
		for keyword in keywords:
			if lower.find(str(keyword).to_lower()) != -1:
				var path := ASSETS_DIR + file
				var texture := load(path)
				if texture is Texture2D:
					return texture
	return null
