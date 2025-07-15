shader_type canvas_item;

uniform sampler2D textureNoise: repeat_enable;
uniform float radius: hint_range(0.0, 1.0) = 0.459;
uniform float effectControl: hint_range(0.0, 1.0) = 0.309;
uniform float warpSpeed: hint_range(-1.0, 1.0) = 0.076;
uniform float shape: hint_range(0.0, 1.0) = 1.0;
uniform float warpStrength: hint_range(0.0, 0.1) = 0.05;

void fragment() {
    vec2 centerUV = UV - 0.5;
    float distToCenter = length(centerUV);

    // Calculate the warp effect
    float warpEffect = sin(distToCenter * 10.0 - TIME * warpSpeed) * warpStrength;
    vec2 warpedUV = UV + normalize(centerUV) * warpEffect;

    // Calculate edge distance for the shape
    float distToCircleEdge = distToCenter * radius;
    float distToSquareEdge = 0.5 * (0.5 - min(min(abs(centerUV.x), 0.5 - abs(centerUV.x)),
                                              min(abs(centerUV.y), 0.5 - abs(centerUV.y))));
    float distToEdge = mix(distToCircleEdge, distToSquareEdge, shape);

    float gradient = smoothstep(0.5, 0.5 - radius, distToEdge);

    // Use the warped UV for noise sampling
    float noiseValue = texture(textureNoise, warpedUV + vec2(TIME * warpSpeed * 0.1)).r;

    float opacity = step(radius, mix(gradient, noiseValue, effectControl) - distToEdge);

    // Sample the texture with the warped UV
    COLOR = texture(TEXTURE, warpedUV) * vec4(1.0, 1.0, 1.0, opacity);
}