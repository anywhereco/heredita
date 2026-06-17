shader_type spatial;
render_mode unshaded;

uniform sampler2D spriteTexture: source_color, filter_linear;
uniform sampler2D curve: source_color, filter_linear;
uniform float dots = 3.0;
uniform float anim_time = 1.5;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

float s_curve(float x) {
    return x * x * (3.0 - 2.0 * x);
}

void fragment() {
	vec4 tex = texture(spriteTexture, UV);
	float sampled_color = texture(curve, vec2(ceil(UV.x*dots)/dots, mod(TIME/anim_time, 2.0*anim_time))).r;
	float growth = s_curve(1.0 - sampled_color);
	growth = (growth + 0.25) / 2.0;
	float border = growth + 0.15;
	if (tex.a < growth) {
		ALBEDO = vec3(0,0,0);
		ALPHA = 0.0;
	} else if (tex.a < border) {
		ALBEDO = vec3(0,0,0);
		ALPHA = sampled_color/2.0;
	} else {
		ALBEDO = vec3(1,1,1);
		ALPHA = sampled_color;
	}
	
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
