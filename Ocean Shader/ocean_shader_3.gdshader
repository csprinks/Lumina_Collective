shader_type spatial;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D water_normal_noise;
uniform float uv_scale : hint_range(0.0, 10.0, 0.25) = 1.0;
uniform vec3 shallow_color : source_color;
uniform vec3 deep_color : source_color;
uniform float depth_scale : hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float edge_scale : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float time_scale : hint_range(0.0, 10.0, 0.25) = 1.0;
uniform float normal_strength : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float roughness : hint_range(0.0, 1.0, 0.1) = 0.25;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D sun_highlights;
uniform float color_ratio : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform vec2 abberation_r;
uniform vec2 abberation_g;
uniform vec2 abberation_b;
uniform float highlights_time_scale : hint_range(0.0, 1.0, 0.1) = 1.0;

vec3 soft_light(vec3 base, vec3 blend) {
    vec3 limit = step(0.5, blend);
    return mix(
        2.0 * base * blend + base * base * (1.0 - 2.0 * blend),
        sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend),
        limit
    );
}

void fragment() {
    vec2 uv = UV * uv_scale;
    vec2 suv = SCREEN_UV;

    uv.x += sin(TIME * time_scale + (uv.x + uv.y) * 25.0) * 0.01;
    uv.y += cos(TIME * time_scale + (uv.y - uv.x) * 25.0) * 0.01;

    suv.x += sin(TIME * time_scale + (uv.x + suv.y) * 25.0) * 0.01;
    suv.y += cos(TIME * time_scale + (uv.y - suv.y) * 25.0) * 0.01;

    float r = texture(sun_highlights, uv + abberation_r + vec2(TIME * highlights_time_scale, 0.0)).r;
    float g = texture(sun_highlights, uv + abberation_g + vec2(TIME * highlights_time_scale, 0.0)).g;
    float b = texture(sun_highlights, uv + abberation_b + vec2(TIME * highlights_time_scale, 0.0)).b;

    vec3 screen_color = texture(screen_texture, suv).rgb;
    vec3 highlights = vec3(r, g, b);
    vec3 blended = soft_light(screen_color, highlights);

    // Depth calculation
    float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
    vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view.xyz /= view.w;
    float linear_depth = -view.z;

    // Create water color based on depth
    float water_depth = 1.0 - exp(-depth_scale * linear_depth);
    vec3 water_color = mix(shallow_color, deep_color, water_depth);

    // Add edge foam
    float edge_foam = 1.0 - smoothstep(0.0, edge_scale, linear_depth);
    water_color = mix(water_color, vec3(1.0), edge_foam);

    ALBEDO = mix(water_color, blended, color_ratio);
    NORMAL_MAP = texture(water_normal_noise, uv).rgb;
    NORMAL_MAP_DEPTH = normal_strength;
    ROUGHNESS = roughness;
}