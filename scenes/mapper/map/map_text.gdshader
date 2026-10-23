shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec2 curve_points[4];
uniform float arc_lengths[65];
uniform float curve_length = 1.0;
uniform float text_start;
uniform float text_scale = 1.0;
uniform vec2 text_origin;
uniform float glyph_spacing;
uniform vec4 text_color : source_color = vec4(1.0);
uniform vec2 map_size;
uniform float pixel_size = 0.1;
varying vec2 map_position;

vec2 bezier(float t) {
	float s = 1.0 - t;
	return s * s * s * curve_points[0] + 3.0 * s * s * t * curve_points[1]
		+ 3.0 * s * t * t * curve_points[2] + t * t * t * curve_points[3];
}

void vertex() {
	float text_x = VERTEX.x + UV2.x * glyph_spacing;
	float distance = clamp((text_start + (text_x - text_origin.x) * text_scale) / curve_length, 0.0, 1.0);
	int low = 0;
	int high = 64;
	for (int step = 0; step < 6; step++) {
		int middle = (low + high) / 2;
		if (arc_lengths[middle] < distance) {
			low = middle;
		} else {
			high = middle;
		}
	}
	float fraction = (distance - arc_lengths[low]) / max(arc_lengths[high] - arc_lengths[low], 0.000001);
	float t = (float(low) + clamp(fraction, 0.0, 1.0)) / 64.0;
	float s = 1.0 - t;
	vec2 tangent = 3.0 * s * s * (curve_points[1] - curve_points[0])
		+ 6.0 * s * t * (curve_points[2] - curve_points[1])
		+ 3.0 * t * t * (curve_points[3] - curve_points[2]);
	if (length(tangent) < 0.00001) {
		tangent = bezier(min(t + 0.001, 1.0)) - bezier(max(t - 0.001, 0.0));
	}
	tangent = length(tangent) > 0.00001 ? normalize(tangent) : vec2(1.0, 0.0);
	vec2 normal = vec2(-tangent.y, tangent.x);
	map_position = bezier(t) - normal * (VERTEX.y - text_origin.y) * text_scale;
	vec2 world = (map_position - map_size * 0.5) * pixel_size;
	VERTEX = vec3(world.x, 0.025, world.y);
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	if (any(lessThan(map_position, vec2(0.0))) || any(greaterThan(map_position, map_size))) {
		discard;
	}
	ALBEDO = text_color.rgb;
	ALPHA = 1.0;
}
