shader_type spatial;

render_mode blend_mix, depth_draw_never, unshaded;

uniform sampler2D brush_mask : source_color, filter_nearest, repeat_disable;
uniform sampler2D map_00 : source_color, filter_nearest, repeat_disable;
uniform sampler2D map_10 : source_color, filter_nearest, repeat_disable;
uniform sampler2D map_01 : source_color, filter_nearest, repeat_disable;
uniform sampler2D map_11 : source_color, filter_nearest, repeat_disable;

uniform ivec2 map_size = ivec2(1);
uniform ivec2 brush_pixel_origin = ivec2(0);
uniform ivec2 first_chunk = ivec2(0);
uniform vec4 target_color : source_color = vec4(1.0);
uniform vec4 preview_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);
uniform bool targeted = true;
uniform bool preview_enabled = false;

const int CHUNK_SIZE = 256;
const float COLOR_EPSILON = 0.00001;

vec4 get_map_color(ivec2 brush_pixel) {
	ivec2 map_pixel = brush_pixel_origin + brush_pixel;
	if (map_pixel.x < 0 || map_pixel.y < 0 || map_pixel.x >= map_size.x || map_pixel.y >= map_size.y) {
		return vec4(-1.0);
	}

	ivec2 chunk_coord = map_pixel / CHUNK_SIZE;
	ivec2 chunk_slot = chunk_coord - first_chunk;
	ivec2 local_pixel = map_pixel - chunk_coord * CHUNK_SIZE;
	if (all(equal(chunk_slot, ivec2(0, 0)))) {
		return texelFetch(map_00, local_pixel, 0);
	} else if (all(equal(chunk_slot, ivec2(1, 0)))) {
		return texelFetch(map_10, local_pixel, 0);
	} else if (all(equal(chunk_slot, ivec2(0, 1)))) {
		return texelFetch(map_01, local_pixel, 0);
	} else if (all(equal(chunk_slot, ivec2(1, 1)))) {
		return texelFetch(map_11, local_pixel, 0);
	}
	return vec4(-1.0);
}


bool is_preview_pixel(ivec2 brush_pixel, ivec2 mask_size) {
	if (brush_pixel.x < 0 || brush_pixel.y < 0 || brush_pixel.x >= mask_size.x || brush_pixel.y >= mask_size.y) {
		return false;
	}
	if (texelFetch(brush_mask, brush_pixel, 0).a <= 0.0) {
		return false;
	}

	vec4 map_color = get_map_color(brush_pixel);
	if (map_color.a < 0.0) {
		return false;
	}
	if (targeted) {
		return all(lessThanEqual(abs(map_color - target_color), vec4(COLOR_EPSILON)));
	}
	return map_color.a > 0.0;
}


void fragment() {
	if (!preview_enabled) {
		discard;
	}

	ivec2 mask_size = textureSize(brush_mask, 0);
	ivec2 brush_pixel = clamp(ivec2(UV * vec2(mask_size)), ivec2(0), mask_size - ivec2(1));
	if (!is_preview_pixel(brush_pixel, mask_size)) {
		discard;
	}

	ALBEDO = preview_color.rgb;
	ALPHA = preview_color.a;
}
