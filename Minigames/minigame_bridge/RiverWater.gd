extends Node2D


const WAVE_COLOR := Color(0.85, 1.0, 1.0, 0.34)
const FOAM_COLOR := Color(1.0, 1.0, 1.0, 0.42)

const WAVE_SPEED := 70.0
const WAVE_COUNT := 18

var time_passed: float = 0.0


func _ready():
	z_index = -10
	set_process(true)


func _process(delta: float):
	time_passed += delta
	queue_redraw()


func _draw():
	var screen_size: Vector2 = get_viewport_rect().size
	
	_draw_moving_waves(screen_size)
	_draw_small_foam(screen_size)


func _draw_moving_waves(screen_size: Vector2):
	for i in range(WAVE_COUNT):
		var t: float = float(i) / float(WAVE_COUNT - 1)
		
		var y: float = lerpf(screen_size.y * 0.28, screen_size.y * 0.72, t)
		var left_x: float = lerpf(screen_size.x * 0.47, screen_size.x * 0.13, t)
		var right_x: float = lerpf(screen_size.x * 0.53, screen_size.x * 0.87, t)
		
		var offset: float = fmod(time_passed * WAVE_SPEED + float(i) * 35.0, 120.0)
		var x: float = left_x - 120.0 + offset
		
		while x < right_x:
			var points := PackedVector2Array()
			
			for p in range(12):
				var px: float = x + float(p) * 10.0
				var py: float = y + sin(float(p) * 0.8 + time_passed * 3.0 + float(i)) * 3.5
				
				if px >= left_x and px <= right_x:
					points.append(Vector2(px, py))
			
			if points.size() >= 2:
				draw_polyline(points, WAVE_COLOR, 2.0)
			
			x += 130.0


func _draw_small_foam(screen_size: Vector2):
	for i in range(10):
		var t: float = fmod(time_passed * 0.25 + float(i) * 0.11, 1.0)
		
		var y: float = lerpf(screen_size.y * 0.30, screen_size.y * 0.70, t)
		var left_x: float = lerpf(screen_size.x * 0.47, screen_size.x * 0.18, t)
		var right_x: float = lerpf(screen_size.x * 0.53, screen_size.x * 0.82, t)
		
		var x: float = lerpf(left_x, right_x, abs(sin(float(i) * 1.7)))
		var radius: float = lerpf(3.0, 6.0, abs(sin(time_passed + float(i))))
		
		draw_circle(Vector2(x, y), radius, FOAM_COLOR)
