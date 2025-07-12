shader_type canvas_item;

uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 size = vec2(1.0, 1.0);
uniform float border_size: hint_range(0.0, 0.5) = 0.1;
uniform float corner_radius = 0.0;

float rounded_rectangle(vec2 position, vec2 rect_size, float radius) {
    vec2 q = abs(position) - rect_size + radius;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

void fragment() {
    vec2 scaled_uv = (UV - 0.5) * size;

float outer_distance = rounded_rectangle(scaled_uv, size / 2.0, corner_radius);
float inner_distance = rounded_rectangle(scaled_uv, size / 2.0 - vec2(border_size), max(corner_radius - border_size, 0.0));

    float border_factor = smoothstep(-0.01, 0.01, abs(inner_distance) - border_size / 2.0);

    vec4 final_color = border_color;
    final_color.a *= (1.0 - border_factor) * smoothstep(0.01, -0.01, outer_distance);

    COLOR = final_color;
}