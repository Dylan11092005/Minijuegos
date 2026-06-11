shader_type canvas_item;

uniform sampler2D water_texture;
uniform float speed = 0.08;
uniform float wave_strength = 0.01;
uniform float wave_speed = 1.5;

void fragment() {
	vec2 uv = UV;

	// Corriente hacia la derecha
	uv.x -= TIME * speed;

	// Movimiento suave, no exagerado
	uv.y += sin((uv.x * 8.0) + TIME * wave_speed) * wave_strength;

	// Repetición infinita
	uv = fract(uv);

	COLOR = texture(water_texture, uv);
}