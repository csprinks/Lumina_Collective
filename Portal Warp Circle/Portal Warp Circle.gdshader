shader_type spatial;

uniform vec4 portal_color : source_color = vec4(0.5, 0.2, 1.0, 1.0);
uniform float speed : hint_range(0.1, 5.0) = 1.0;
uniform vec2 direction = vec2(1.0, 0.0);
uniform int num_particles : hint_range(10, 100) = 50;
uniform float portal_radius : hint_range(0.1, 1.0) = 0.4;
uniform float swirl_intensity : hint_range(0.0, 2.0) = 0.5;
uniform float swirl_frequency : hint_range(1.0, 10.0) = 3.0;

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 swirl(vec2 uv, float time) {
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);
    float swirl_amount = sin(dist * swirl_frequency - time * speed) * swirl_intensity;
    float new_angle = angle + swirl_amount;
    return vec2(cos(new_angle), sin(new_angle)) * dist;
}

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;

    // Apply swirl effect
    uv = swirl(uv, TIME);

    float dist = length(uv);

    // Create the circular portal shape
    float circle = smoothstep(portal_radius, portal_radius - 0.02, dist);

    // Create the spinning effect
    float angle = atan(uv.y, uv.x);
    float spin = sin(angle * 10.0 + TIME * speed);

    // Create particles
    float particles = 0.0;
    for (int i = 0; i < num_particles; i++) {
        float t = TIME * speed + float(i) * 6.28 / float(num_particles);
        vec2 pos = vec2(
            cos(t) * direction.x - sin(t) * direction.y,
            sin(t) * direction.x + cos(t) * direction.y
        ) * portal_radius;
        particles += smoothstep(0.05, 0.0, length(uv - pos));
    }

    // Combine effects
    float alpha = circle * (0.5 + 0.5 * spin + particles);

    // Output final color
    ALBEDO = portal_color.rgb;
    ALPHA = alpha * portal_color.a;
    EMISSION = ALBEDO * alpha * 2.0;
}