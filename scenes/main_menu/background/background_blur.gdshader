shader_type canvas_item;


uniform sampler2D SCREEN_TEXTURE: hint_screen_texture,repeat_disable, filter_nearest;
/**
* How dark the blur will be
*/
uniform float mix_percentage: hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec3 PixelBlurred = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    vec3 color = mix(PixelBlurred, vec3(0.0), mix_percentage);
    // The radius is 3*strength because it is the point where the Gaussian weight is near zero.
    COLOR = vec4(color, 1.);
}