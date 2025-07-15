shader_type spatial;

void vertex() {
	// Called for every vertex the material is visible on.
}
render_mode blend_add, cull_back, depth_prepass_alpha;

uniform sampler2D noise_tex : hint_default_black;
uniform sampler2D normal_map : hint_normal;

uniform float time_speed : hint_range(0.0, 10.0) = 1.0;

uniform vec4 color1 : source_color = vec4(1.0, 0.3, 0.0, 1.0);
uniform vec4 color2 : source_color = vec4(1.0, 1.0, 0.2, 1.0);

uniform float distortion_strength : hint_range(0.0, 1.0) = 0.15;
uniform float alpha_power : hint_range(0.1, 5.0) = 2.5;

uniform float emission_strength : hint_range(0.0, 10.0) = 4.0;
uniform float center_boost : hint_range(0.0, 2.0) = 1.0;
uniform float edge_fade : hint_range(0.0, 5.0) = 1.0;
uniform float height_sharpness : hint_range(0.1, 5.0) = 1.5;
uniform float overall_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    float t = TIME * time_speed;

    vec2 uv = UV;
    vec2 noise_uv = uv + vec2(0.0, -t * 0.5);
    float noise = texture(noise_tex, noise_uv).r;

    uv.x += (noise - 0.5) * distortion_strength;

    float flame_pos = 1.0 - uv.y;
    vec4 flame_color = mix(color1, color2, flame_pos);

    float center_curve = pow(sin(uv.x * 3.14159), edge_fade) * center_boost;
    float alpha = pow(flame_pos, height_sharpness) * center_curve * noise;
    alpha = clamp(alpha * overall_alpha, 0.0, 1.0);

    ALBEDO = flame_color.rgb;
    EMISSION = flame_color.rgb * emission_strength * center_curve;
    ALPHA = alpha;

    NORMAL_MAP = texture(normal_map, uv).rgb * 2.0 - 1.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
