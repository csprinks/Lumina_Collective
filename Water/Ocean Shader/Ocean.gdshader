shader_type spatial;

uniform vec3 R = vec3(0.8, 0.6, 0.6);
uniform float scale = 0.5;
uniform float speed = 1.0;
uniform vec3 direction = vec3(1,1,1);
uniform float distortion = 0.5;
uniform float layers = 2.0;
uniform float shades = 3.0;
uniform int steps = 6;
uniform vec3 tint = vec3(0.459, 0.765, 1.0);
uniform vec3 movement_speed = vec3(0.1, 0.05, 0.0); // Movement speed in 3D

float gyroid(vec3 seed) {
    return dot(sin(seed), cos(seed.yzx));
}

float fbm(vec3 seed) {
    float result = 0.0;
    float a = 0.5;
    for (int i = 0; i < steps; ++i, a /= 2.0) {
        seed += direction * TIME * speed * 0.01 / a;
        seed.z += result * distortion;
        result += gyroid(seed / a) * a;
    }
    return result;
}

void fragment() {
    // Get world position and add movement
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_pos += TIME * movement_speed;

    vec3 p = (2.0 * world_pos - R) / R.y;

    float shape = fbm(p * scale);
    float gradient = fract(shape * layers);
    float shade = round(pow(gradient, 4.0) * shades) / shades;
    vec3 color = mix(tint * mix(0.6, 0.8, gradient), vec3(1.0), shade);

    ALBEDO = color;
}