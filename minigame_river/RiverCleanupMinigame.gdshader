shader_type canvas_item;

uniform sampler2D water_texture;
uniform float speed = 0.08;
uniform float wave_strength = 0.01;
uniform float wave_speed = 1.5;


void fragment() {
	vec2 current_uv = UV;

	current_uv.x -= TIME * speed;
	current_uv.y += sin((current_uv.x * 8.0) + TIME * wave_speed) * wave_strength;

	current_uv = fract(current_uv);

	COLOR = texture(water_texture, current_uv);
}