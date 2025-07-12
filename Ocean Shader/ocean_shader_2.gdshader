shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Wave settings:
uniform float wave_speed : hint_range(0, 1) = 0.5;
uniform vec4 wave_a : source_color = vec4(1.0, 1.0, 0.35, 3.0);
uniform vec4 wave_b : source_color = vec4(1.0, 0.6, 0.30, 1.55);
uniform vec4 wave_c : source_color = vec4(1.0, 1.3, 0.25, 0.9);


// Surface settings:
uniform vec2 sampler_scale = vec2(0.25, 0.25);
uniform vec2 sampler_direction = vec2(0.05, 0.04);

uniform sampler2D uv_sampler : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec2 uv_sampler_scale = vec2(0.25, 0.25);
uniform float uv_sampler_strength : hint_range(0, 1) = 0.04;

uniform sampler2D normalmap_a_sampler : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D normalmap_b_sampler : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform sampler2D foam_sampler : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform float foam_level : hint_range(0, 1) = 0.5;

// Volume settings:
uniform float refraction : hint_range(0, 1) = 0.075;

uniform vec4 color_deep : source_color;
uniform vec4 color_shallow : source_color;
uniform float beers_law : hint_range(0, 10) = 2.0;
uniform float depth_offset : hint_range(-2, 2) = -0.75;

// Projector for the water caustics:
uniform mat4 projector;

uniform sampler2D caustic_sampler : hint_default_black, filter_linear_mipmap, repeat_enable;

// Vertex -> Fragment:
varying float vertex_height;
varying vec3 vertex_normal;
varying vec3 vertex_binormal;
varying vec3 vertex_tangent;
varying mat4 inv_mvp;

vec4 wave(vec4 parameter, vec2 position, float time, inout vec3 tangent, inout vec3 binormal)
{
    float wave_steepness = parameter.z;
    float wave_length = parameter.w;

    float k = 2.0 * 3.14159265359 / wave_length;
    float c = sqrt(9.8 / k);
    vec2 d = normalize(parameter.xy);
    float f = k * (dot(d, position) - c * time);
    float a = wave_steepness / k;

    tangent += normalize(vec3(1.0-d.x * d.x * (wave_steepness * sin(f)), d.x * (wave_steepness * cos(f)), -d.x * d.y * (wave_steepness * sin(f))));
    binormal += normalize(vec3(-d.x * d.y * (wave_steepness * sin(f)), d.y * (wave_steepness * cos(f)), 1.0-d.y * d.y * (wave_steepness * sin(f))));

    return vec4(d.x * (a * cos(f)), a * sin(f) * 0.25, d.y * (a * cos(f)), 0.0);
}

void vertex() {
    float time = TIME * wave_speed;

    vec4 vertex = vec4(VERTEX, 1.0);
    vec3 vertex_position = (MODEL_MATRIX * vertex).xyz;

    vec3 tang = vec3(0.0, 0.0, 0.0);
    vec3 bin = vec3(0.0, 0.0, 0.0);

    vertex += wave(wave_a, vertex_position.xz, time, tang, bin);
    vertex += wave(wave_b, vertex_position.xz, time, tang, bin);
    vertex += wave(wave_c, vertex_position.xz, time, tang, bin);

    vertex_tangent = tang;
    vertex_binormal = bin;

    vertex_position = vertex.xyz;

    vertex_height = (PROJECTION_MATRIX * MODELVIEW_MATRIX * vertex).z;

    TANGENT = vertex_tangent;
    BINORMAL = vertex_binormal;
    vertex_normal = normalize(cross(vertex_binormal, vertex_tangent));
    NORMAL = vertex_normal;

    UV = vertex.xz * sampler_scale;

    VERTEX = vertex.xyz;

    inv_mvp = inverse(PROJECTION_MATRIX * MODELVIEW_MATRIX);
}

void fragment() {
    vec2 uv_offset = sampler_direction * TIME;
    vec2 uv_sampler_uv = UV * uv_sampler_scale + uv_offset;
    vec2 uv_sampler_uv_offset = uv_sampler_strength * texture(uv_sampler, uv_sampler_uv).rg * 2.0 - 1.0;
    vec2 uv = UV + uv_sampler_uv_offset;

    vec3 normalmap = texture(normalmap_a_sampler, uv - uv_offset*2.0).rgb * 0.75;
    normalmap += texture(normalmap_b_sampler, uv + uv_offset).rgb * 0.25;

    vec3 ref_normalmap = normalmap * 2.0 - 1.0;
    ref_normalmap = normalize(vertex_tangent*ref_normalmap.x + vertex_binormal*ref_normalmap.y + vertex_normal*ref_normalmap.z);
    vec2 ref_uv = SCREEN_UV + (ref_normalmap.xy * refraction) / vertex_height;

	float depth_raw = texture(depth_texture, ref_uv).r * 2.0 - 1.0;
    float depth = PROJECTION_MATRIX[3][2] / (depth_raw + PROJECTION_MATRIX[2][2]);

    float depth_blend = exp((depth+VERTEX.z + depth_offset) * -beers_law);
    depth_blend = clamp(1.0-depth_blend, 0.0, 1.0);
    float depth_blend_pow = clamp(pow(depth_blend, 2.5), 0.0, 1.0);

	vec3 screen_color = textureLod(screen_texture, ref_uv, depth_blend_pow * 2.5).rgb;

    vec3 dye_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_pow);
    vec3 color = mix(screen_color*dye_color, dye_color*0.25, depth_blend_pow*0.5);

    vec4 caustic_screenPos = vec4(ref_uv*2.0-1.0, depth_raw, 1.0);
    vec4 caustic_localPos = inv_mvp * caustic_screenPos;
    caustic_localPos = vec4(caustic_localPos.xyz/caustic_localPos.w, caustic_localPos.w);

    vec2 caustic_Uv = caustic_localPos.xz / vec2(1024.0) + 0.5;
// Change this:
// vec4 caustic_color = texture(caustic_sampler, vec3(caustic_Uv*300.0, mod(TIME*14.0, 16.0)));

// To this:
vec2 caustic_uv = caustic_Uv * 300.0 + vec2(TIME * 0.05, TIME * 0.03); // Adjust these values as needed
vec4 caustic_color = texture(caustic_sampler, caustic_uv);

    color *= 1.0 + pow(caustic_color.r, 1.50) * (1.0-depth_blend) * 6.0;

    if(depth + VERTEX.z < vertex_height-0.1)
    {
        float foam_noise = clamp(pow(texture(foam_sampler, (uv*4.0) - uv_offset).r, 10.0)*40.0, 0.0, 0.2);
        float foam_mix = clamp(pow((1.0-(depth + VERTEX.z) + foam_noise), 8.0) * foam_noise * 0.4, 0.0, 1.0);
        color = mix(color, vec3(1.0), foam_mix);
    }

    ALBEDO = color;
    METALLIC = 0.1;
    ROUGHNESS = 0.2;
    SPECULAR = 0.2 + depth_blend_pow * 0.4;
    NORMAL_MAP = normalmap;
    NORMAL_MAP_DEPTH = 1.25;
}