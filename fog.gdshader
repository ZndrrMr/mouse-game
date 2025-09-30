shader_type canvas_item;

uniform vec4 fog_color : source_color = vec4(0.9, 0.4, 0.2, 1.0);
uniform vec2 world_offset = vec2(0.0, 0.0);
uniform float radiusf : hint_range(0.0001, 1) = 0.4;
uniform float radius_offset : hint_range(0.0, 0.2) = 0.01;
uniform float edge_softness : hint_range(0.0, 10) = 0.002;
uniform float animation_speed = 0.5;
uniform sampler2D noise_texture: hint_default_black, repeat_enable;

void fragment() {
	vec2 directions[4] = vec2[4](vec2(0.0, 1.0), vec2(0.0, -1.0), vec2(1.0, 0.0), vec2(-1.0, 0.0));
	vec2 offsets[4] = vec2[4](vec2(0.0, 0.0), vec2(0.0, 0.25), vec2(0.5, 0.0), vec2(0.2, 0.4));
	
	vec4 sum_color = vec4(0.0);
	sum_color.rgb = fog_color.rgb;
	
	for (int i = 0; i < 4; i++) {
		vec2 uv = UV + (animation_speed * directions[i] * TIME) + offsets[i] + world_offset;
		vec4 noise_color = texture(noise_texture, uv);
		
		vec2 norm = (UV - vec2(0.5)) / max(vec2(radiusf + (radius_offset * float(i))), vec2(0.0001));
		float d = dot(norm, norm);
		
		float fw = fwidth(d);
		// combine driver edge_softness with fwidth for stable AA across scales
		float edge = max(edge_softness, fw);
		
		// alpha = 1 inside, 0 outside, with smooth transition at the boundary
		float a = 1.0 - (2.0 * smoothstep(1.0 - edge, 1.0 + edge, d));
		
		vec4 final_color = noise_color;
		final_color.rgb += vec3(a);
		
		//final_color.rgb = step(final_color.rgb, vec3(0.5));
		final_color.rgb = vec3(1.0) - final_color.rgb;
		final_color.a = final_color.r * 0.25;
		
		sum_color.a += final_color.a;
	}
	COLOR = sum_color;
}
