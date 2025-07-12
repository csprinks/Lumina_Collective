shader_type canvas_item;

// Existing uniforms
uniform bool use_sprite_alpha = true;
uniform bool use_transition_texture = false;
uniform sampler2D transition_texture;
uniform int transition_type: hint_enum("Basic", "Mask", "Shape", "Clock") = 0;

group_uniforms positioning;
uniform bool invert = false;
uniform bool from_center = false;
uniform vec2 grid_size = vec2(1.0, 1.0);
uniform float rotation_angle = 0.0;

group_uniforms positioning.stagger;
uniform vec2 stagger = vec2(0.0, 0.0);
uniform ivec2 stagger_frequency = ivec2(2, 2);
uniform ivec2 flip_frequency = ivec2(1, 1);

group_uniforms basic_transition_controls;
uniform float basic_feather = 0.0;

group_uniforms mask_transition_controls;
uniform sampler2D mask_texture;
uniform bool use_mask_size = false;
uniform vec2 mask_size = vec2(100.0);

group_uniforms shape_transition_controls;
uniform int edges : hint_range(3, 64) = 6; // default hexagon
uniform float shape_feather : hint_range(0.0, 10.0) = 0.1;

group_uniforms clock_transition_controls;
uniform int sectors : hint_range(1, 128) = 1;
uniform float clock_feather : hint_range(0.0, 16.0) = 0.0;

group_uniforms animation;
uniform float progress = 0.0;
uniform vec2 progress_bias = vec2(0.0);

// Flash effect uniforms
group_uniforms flash;
uniform bool enable_flash = false;
uniform vec4 flash_color1 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 flash_color2 : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform float flash_frequency = 2.0;
uniform float flash_intensity = 0.5;
uniform float flash_duration = 0.5;
uniform bool use_flash_alpha = true; // New: respect sprite alpha

// Shake effect uniforms
group_uniforms shake;
uniform bool enable_shake = false;
uniform float shake_intensity = 10.0;
uniform float shake_frequency = 15.0;
uniform vec2 shake_direction = vec2(1.0, 1.0);

// ===== EFFECT FUNCTIONS =====
// Shake function
vec2 apply_shake_effect(vec2 original_uv, float time) {
	if (!enable_shake) return original_uv;
	
	// Generate noise-based offset
	vec2 offset;
	offset.x = sin(time * shake_frequency * 12.9898) * 43758.5453;
	offset.y = cos(time * shake_frequency * 78.2330) * 28974.1372;
	offset = fract(offset) * 2.0 - 1.0;
	
	// Apply intensity and direction
	offset *= shake_intensity * 0.01;
	offset *= shake_direction;
	
	return original_uv + offset;
}

// Flash function with alpha control
vec4 apply_flash_effect(vec4 original_color, float time) {
	if (!enable_flash) return original_color;
	
	// Calculate flash cycle
	float cycle = mod(time * flash_frequency, 1.0);
	float flash_factor = smoothstep(0.0, flash_duration, cycle) * 
						smoothstep(1.0, 1.0 - flash_duration, cycle);
	
	// Blend between two colors
	vec4 flash_color = mix(flash_color1, flash_color2, flash_factor);
	
	// Apply flash with intensity control
	vec4 result = mix(original_color, flash_color, flash_factor * flash_intensity);
	
	// Respect sprite alpha if enabled
	if (use_flash_alpha) {
		result.a = original_color.a;
	}
	
	return result;
}

// Existing helper functions
vec2 use_actual_texture_size(vec2 uv, vec2 texture_size) {
	uv -= 0.5;
	vec2 uv_deriv = fwidth(uv);
	float screen_ratio = uv_deriv.x / uv_deriv.y;
	float texture_ratio = texture_size.x / texture_size.y;
	float mixed_ratio = texture_ratio * screen_ratio;

	if (screen_ratio > texture_ratio) {
		uv.x /= mixed_ratio;
	} else {
		uv.y *= mixed_ratio;
	}

	return uv + 0.5;
}

vec2 get_stagger_offset(vec2 grid) {
	vec2 cells = floor(grid);
	float offset_row = mod(cells.y, float(stagger_frequency.x)) == 0.0 ? 0.5 : 0.0;
	float offset_col = mod(cells.x, float(stagger_frequency.y)) == 0.0 ? 0.5 : 0.0;

	return vec2(
		offset_row * stagger.x,
		offset_col * stagger.y
	);
}

vec2 get_grid_flip(vec2 grid) {
	vec2 cells = floor(grid);
	float flip_row = mod(cells.y, float(flip_frequency.x)) == 0.0 ? 1.0 : -1.0;
	float flip_col = mod(cells.x, float(flip_frequency.y)) == 0.0 ? 1.0 : -1.0;

	return vec2(
		flip_row * grid.x,
		flip_col * grid.y
	);
}

vec2 rotate(vec2 v, float angle) {
	return mat2(
		vec2(cos(angle), sin(angle)),
		vec2(-sin(angle), cos(angle))
		) * v;
}

vec2 get_edges(float center, float width) {
	float half_width = width * 0.5;
	float edge0 = center - half_width;
	float edge1 = center + half_width + 1e-5;
	return vec2(edge0, edge1);
}

float get_local_progress(vec2 grid) {
    vec2 cell = floor(grid);
	vec2 pretty_bias = progress_bias / 10.0;
    float offset = dot(cell, pretty_bias);
    return progress - offset;
}

void fragment() {
	// Apply shake effect first
	vec2 base_uv = UV;
	if (enable_shake) {
		base_uv = apply_shake_effect(base_uv, TIME);
	}
	
	vec2 grid = base_uv * grid_size;
	vec2 offset_uv = grid + get_stagger_offset(grid);
	vec2 grid_flipped_uv = get_grid_flip(offset_uv);
	vec2 tiled_uv = fract(grid_flipped_uv);
	vec2 uv = from_center ? 2.0 * tiled_uv - 1.0 : tiled_uv;
	uv = rotate(uv, radians(rotation_angle));

	float local_progress = get_local_progress(grid);

	COLOR = texture(TEXTURE, base_uv);
	float alpha = COLOR.a;
	float transition_progress = 0.0;

	if (transition_type == 1) {
		vec2 mask_zoom_uv = uv / local_progress;
		vec2 mask_zoom_uv_01 = mask_zoom_uv * 0.5 + 0.5;
		mask_zoom_uv_01 = use_mask_size ? use_actual_texture_size(mask_zoom_uv_01, mask_size) : mask_zoom_uv_01;

		transition_progress = texture(mask_texture, mask_zoom_uv_01).r;

	} else if(transition_type == 2) {
    	float radius = length(uv);
	    float angle = atan(uv.y, uv.x);
		float sector_angle = 2.0 * PI / float(edges);
		float half_sector = sector_angle / 2.0;
		float d = cos(half_sector) / cos(mod(angle + half_sector, sector_angle) - half_sector);

		vec2 smooth_edges = get_edges(local_progress, shape_feather);
		transition_progress = smoothstep(smooth_edges.x, smooth_edges.y, radius / d);

	} else if (transition_type == 3) {
		float radius = length(uv);
		float angle = atan(uv.y, uv.x);
		float sector_angle = 2.0 * PI / float(sectors);
		float half_sector = sector_angle / 2.0;
		angle = mod(angle - half_sector, sector_angle);

		float progress_angle = local_progress * 2.0 * PI / float(sectors);
		float smooth_angle = smoothstep(0.0, clock_feather, progress_angle - angle);
		transition_progress = smooth_angle;

	} else {
		vec2 smooth_edges = get_edges(local_progress, basic_feather);

		float separation_x = smoothstep(smooth_edges.x, smooth_edges.y, abs(uv.x));
		float separation_y = smoothstep(smooth_edges.x, smooth_edges.y, abs(uv.y));
		transition_progress = max(separation_x, separation_y);
	}
	alpha = invert ? 1.0 - transition_progress : transition_progress;
	alpha = use_sprite_alpha ? min(COLOR.a, alpha) : alpha;

	vec4 transition_color = texture(transition_texture, base_uv);

	if (use_transition_texture) {
		vec4 chosen_color = mix(COLOR, transition_color, alpha);
		COLOR = chosen_color;
	} else {
		COLOR.a = alpha;
	}
	
	// Apply flash effect last
	if (enable_flash) {
		COLOR = apply_flash_effect(COLOR, TIME);
	}
}