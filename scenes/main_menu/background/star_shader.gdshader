shader_type sky;

uniform vec3 background_color : source_color = vec3(0.02, 0.04, 0.12);

uniform float sky_zoom : hint_range(0.1, 5.0) = 0.4;

uniform float density : hint_range(0.0, 3.0, 0.0001) = 1.3;
uniform int layer_parascale : hint_range(0, 5, 1) = 4;

uniform vec2 star_speed = vec2(0.0);
uniform vec2 star_wave = vec2(0.0);

uniform float star_size : hint_range(0.0, 100.0, 0.01) = 3.0;
uniform float star_rotate_speed : hint_range(-3.0, 3.0) = 0.5;

uniform float twinkle_effect : hint_range(0.0, 1.0, 0.01) = 0.6;
uniform float twinkle_speed : hint_range(0.0, 100.0, 0.01) = 0.3;

uniform bool pixelate_enabled = false;
uniform float pixelate_count = 1000.0;

float random(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43759.5453123);
}

vec2 rotate(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(
        v.x * c - v.y * s,
        v.x * s + v.y * c
    );
}

void sky() {

    vec3 color = vec3(0.0);

    // Proper sky direction
    vec3 dir = normalize(EYEDIR);

    // Convert to angular spherical coordinates
    float longitude = atan(dir.x, dir.z);
    float latitude  = asin(clamp(dir.y, -1.0, 1.0));

    // Apply angular zoom
    longitude *= sky_zoom;
    latitude  *= sky_zoom;

    vec2 st;
    st.x = longitude / (2.0 * PI);
    st.y = latitude / PI;

    st.x = fract(st.x + 1.0);
    st.y = st.y * 0.5 + 0.5;

    if (pixelate_enabled) {
        st = round(st * pixelate_count) / pixelate_count;
    }

    for (int layer = 0; layer < layer_parascale; layer++) {

        float layer_scale = exp(float(layer + 1) * density);
        vec2 layer_speed = star_speed * (1.0 + float(layer) * 0.3);
        float layer_size = star_size * (1.0 - float(layer) * 0.2);

        vec2 layer_st = st * layer_scale;
        layer_st -= TIME * layer_speed;

        vec2 grid_id = floor(layer_st);
        vec2 grid_st = fract(layer_st);

        float rand_seed = random(grid_id);

        vec2 star_pos = vec2(
            0.5 + 0.3 * sin(rand_seed * 6.28 + TIME * star_wave.x),
            0.5 + 0.2 * cos(rand_seed * 12.56 + TIME * star_wave.y)
        );

        float dist = distance(grid_st, star_pos);

        float snow_size = layer_size * 0.01 * (0.5 + 0.5 * rand_seed);
        float brightness = 1.0 - float(layer) * 0.3;

        float falloff = exp(-(dist * dist) / (snow_size * snow_size));

        vec2 centered = rotate(grid_st - star_pos, TIME * star_rotate_speed);

        float star = falloff;

        float twinkle =
            (1.0 - twinkle_effect) +
            twinkle_effect *
            (sin(rand_seed * 100.0 + TIME * twinkle_speed) *
             cos(rand_seed * 120.0 + TIME * (twinkle_speed + 2.0)));

        star *= twinkle;

        vec3 color_type = vec3(
            random(grid_id - 3.0),
            random(grid_id + 7.0),
            random(grid_id + 5.0)
        );

        color += star * brightness * color_type;
    }

    COLOR = background_color + color * 0.6;
}
