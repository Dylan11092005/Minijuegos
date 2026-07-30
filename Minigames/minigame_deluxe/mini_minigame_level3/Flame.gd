extends Area2D
class_name Flame

# Se emite cuando el jugador apaga la llama a punta de clicks.
signal extinguished(flame)

# Se emite cuando la llama termina de crecer sin haber sido apagada.
signal matured(flame)

@onready var sprite: Sprite2D = $FlameSprite
@onready var collision: CollisionShape2D = $CollisionShape2D

var base_scale: float = 1.0
var growth_multiplier: float = 1.9
var growth_time: float = 6.0
var hits_to_extinguish: int = 3

var hits_left: int = 3
var _resolved: bool = false
var _grow_tween: Tween
var _growth_timer: Timer


func _ready() -> void:
	input_event.connect(_on_input_event)

	# --- Fijar el pivote en la BASE de la llama (no en el centro) ---
	# Así, al crecer con "scale", la llama crece hacia ARRIBA manteniendo
	# fija su base, en vez de crecer para todos lados y parecer que se mueve.
	if sprite and sprite.texture:
		var tex_size: Vector2 = sprite.texture.get_size()
		sprite.centered = false
		sprite.offset = Vector2(-tex_size.x / 2.0, -tex_size.y)

		if collision:
			collision.position = Vector2(0, -tex_size.y / 2.0)

	scale = Vector2(base_scale, base_scale)
	hits_left = hits_to_extinguish

	_growth_timer = Timer.new()
	add_child(_growth_timer)
	_growth_timer.one_shot = true
	_growth_timer.wait_time = growth_time
	_growth_timer.timeout.connect(_on_growth_timeout)
	_growth_timer.start()

	var target_scale: float = base_scale * growth_multiplier
	_grow_tween = create_tween()
	_grow_tween.tween_property(self, "scale", Vector2(target_scale, target_scale), growth_time)


# Llamar desde el spawner justo después de instanciar la llama.
func configure(p_base_scale: float, p_growth_time: float, p_growth_multiplier: float, p_hits_to_extinguish: int = 3) -> void:
	base_scale = p_base_scale
	growth_time = p_growth_time
	growth_multiplier = p_growth_multiplier
	hits_to_extinguish = p_hits_to_extinguish


func _on_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if _resolved:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_take_hit()


func _take_hit() -> void:
	if _resolved:
		return

	hits_left -= 1

	# Reduce el tamaño actual como feedback visual de cada click,
	# manteniendo la base fija (mismo pivote de _ready()).
	var shrink_tween := create_tween()
	var shrunk_scale: Vector2 = scale * 0.8
	shrink_tween.tween_property(self, "scale", shrunk_scale, 0.1)

	if hits_left <= 0:
		_extinguish()


func _extinguish() -> void:
	if _resolved:
		return
	_resolved = true
	_growth_timer.stop()
	if _grow_tween and _grow_tween.is_valid():
		_grow_tween.kill()
	extinguished.emit(self)
	queue_free()


func _on_growth_timeout() -> void:
	if _resolved:
		return
	_resolved = true
	matured.emit(self)
	queue_free()
