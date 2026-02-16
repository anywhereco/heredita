shader_type canvas_item;


uniform sampler2D SCREEN_TEXTURE: hint_screen_texture,repeat_disable, filter_nearest;
/**
* How dark the blur will be
*/
uniform float mix_percentage: hint_range(0.0, 1.0) = 0.3;

void fragment() {
    COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
}