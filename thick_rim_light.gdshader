shader_type canvas_item;

uniform vec4 rim_color : source_color = vec4(1.0, 0.9, 0.6, 1.0);
uniform float rim_thickness : hint_range(0.0, 100.0) = 30.0;
uniform float rim_intensity : hint_range(0.0, 5.0) = 2.0;
uniform float rim_fade : hint_range(0.1, 5.0) = 1.5;

void fragment() {
    vec4 col = texture(TEXTURE, UV);

    vec2 size = vec2(rim_thickness) / vec2(textureSize(TEXTURE, 0));

    float rim = 0.0;
    int samples = 16;

    for(int i = 0; i < samples; i++) {
        float angle = float(i) * 6.28318 / float(samples);
        vec2 offset = vec2(cos(angle), sin(angle)) * size;

        for(float dist = 0.2; dist <= 1.0; dist += 0.2) {
            vec2 sample_pos = UV + offset * dist;
            float sample_alpha = texture(TEXTURE, sample_pos).a;
            rim = max(rim, sample_alpha * (1.0 - dist * 0.5));
        }
    }

    rim = pow(rim, rim_fade) * rim_intensity;
    rim *= (1.0 - col.a);

    vec4 final_color = col;
    final_color.rgb = mix(final_color.rgb, rim_color.rgb, rim);
    final_color.a = max(col.a, rim * rim_color.a);

    COLOR = final_color;
}