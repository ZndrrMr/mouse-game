shader_type canvas_item;

uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_width : hint_range(0.0, 50.0) = 10.0;
uniform float rim_sharpness : hint_range(0.1, 10.0) = 1.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);

    float rim_size = rim_width / 100.0;

    float alpha = col.a;
    float rim = 0.0;

    for(float x = -1.0; x <= 1.0; x += 0.5) {
        for(float y = -1.0; y <= 1.0; y += 0.5) {
            vec2 offset = vec2(x, y) * rim_size;
            float sample_alpha = texture(TEXTURE, UV + offset).a;
            rim = max(rim, sample_alpha);
        }
    }

    rim = (rim - alpha) * rim_sharpness;
    rim = clamp(rim, 0.0, 1.0);

    COLOR = mix(col, rim_color, rim * (1.0 - alpha));
    COLOR.a = max(col.a, rim * rim_color.a);
}