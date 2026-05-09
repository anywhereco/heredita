shader_type canvas_item;

uniform vec3 hue;

varying vec4 modulate_color;

void vertex() {
	modulate_color = COLOR;
}

void fragment() {
	vec3 hs = mix(vec3(1), hue, UV.x);
	COLOR = vec4(mix(hs, vec3(0), UV.y), 1) * modulate_color;
}