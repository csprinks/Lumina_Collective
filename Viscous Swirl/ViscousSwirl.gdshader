shader_type spatial;
render_mode unshaded;

#define C(x) sin(x) * 0.5 + 0.5

uniform vec2 resolution = vec2(400.0, 600.0);
uniform int octaves: hint_range(0, 10, 1) = 5;
uniform float speed: hint_range(0.1, 4.0, 0.1) = 1.0;
uniform float frequency: hint_range(0.1, 10.0, 0.1) = 1.0;
uniform float amplitude: hint_range(0.1, 10.0, 0.1) = 1.0;
uniform float time_shift: hint_range(0.1, 10.0, 0.1) = 1.0;
uniform float zoom: hint_range(1.0, 20.0, 0.1) = 5.0;
uniform float radiance: hint_range(0.1, 4.0, 0.1) = 0.5;
uniform float sharpness: hint_range(0.1, 10.0, 0.1) = 2.0;
uniform float gloss: hint_range(0.1, 2.0, 0.01) = 0.50;

vec2 warp(vec2 uv, float time) {
	float f = frequency;
	float a = amplitude;
	float t = time_shift;
	
	for (int s = 0; s < octaves; s++) {
		uv += vec2(sin(uv.y * f + time * time_shift), cos(uv.x * f + time * t)) / a;
		f *= 1.9;
		t *= 0.2;
		a *= 2.0;
	}
	return uv;
}

vec4 specular(vec4 color) {
	float shine = pow(abs(normalize(vec3(length(dFdx(color)), 
	length(dFdy(color)), radiance / resolution.x)).z), sharpness) + gloss;
	return color * shine;
}

void fragment() {
	float time = TIME * speed;
	vec2 uv = UV - 0.5;
	uv.x *= resolution.x / resolution.y;
	uv *= zoom;
	uv = warp(uv, time);
	float r = C(uv.x - time) * 0.8 + 0.3;
	float g = C(uv.y + time) * 0.5 + 0.5;
	float b = C(uv.x * uv.y + C(time * 0.5)) * 0.8 + 0.3;
	
	vec4 color = specular(vec4(r, g, b, 1.0));
	ALBEDO = color.rgb;
}