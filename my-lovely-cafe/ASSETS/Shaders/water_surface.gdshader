shader_type spatial;
render_mode cull_back, specular_disabled, blend_mix, depth_draw_opaque;

uniform vec4 shallow_color : source_color = vec4(0.45, 0.78, 0.82, 0.55);
uniform vec4 deep_color : source_color = vec4(0.12, 0.4, 0.55, 0.85);
uniform vec4 shade_color : source_color = vec4(0.25, 0.4, 0.6, 1.0);
uniform int depth_bands : hint_range(1, 6) = 3;
uniform float fresnel_power : hint_range(0.5, 8.0) = 2.5;

// Gentle ambient surface motion, independent of ripples.
uniform float wave_speed : hint_range(0.0, 3.0) = 0.4;
uniform float wave_scale : hint_range(0.1, 10.0) = 2.0;
uniform float wave_height : hint_range(0.0, 0.1) = 0.01;

// Ripple system — filled in by water_surface.gd whenever a collider
// touches the water. A start_time of -1.0 means that slot is unused.
const int MAX_RIPPLES = 6;
uniform vec2 ripple_positions[MAX_RIPPLES];
uniform float ripple_start_times[MAX_RIPPLES];
uniform float ripple_speed : hint_range(0.1, 5.0) = 1.5;
uniform float ripple_wavelength : hint_range(0.05, 2.0) = 0.3;
uniform float ripple_amplitude : hint_range(0.0, 0.2) = 0.03;
uniform float ripple_lifetime : hint_range(0.5, 10.0) = 3.0;

// Bold, hard-edged highlight right at a ripple's crest — reads like a
// comic/anime linework accent instead of a soft realistic foam gradient.
uniform vec4 ring_highlight_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float ring_threshold : hint_range(0.0, 1.0) = 0.6;

// Little twinkling sparkle dots across the surface.
uniform bool sparkle_enabled = true;
uniform vec4 sparkle_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float sparkle_density : hint_range(1.0, 100.0) = 40.0;
uniform float sparkle_speed : hint_range(0.0, 5.0) = 1.0;
uniform float sparkle_chance : hint_range(0.9, 0.999) = 0.985;

uniform bool rim_enabled = true;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_power : hint_range(1.0, 8.0) = 3.0;
uniform float rim_strength : hint_range(0.0, 3.0) = 0.6;

varying float ripple_height_v;
varying vec2 world_xz_v;

float ripple_contribution(vec2 world_xz, vec2 center, float start_time) {
	if (start_time < 0.0) {
		return 0.0;
	}
	float age = TIME - start_time;
	if (age < 0.0 || age > ripple_lifetime) {
		return 0.0;
	}

	float dist = length(world_xz - center);
	float wave_front = age * ripple_speed;
	float falloff = clamp(1.0 - (age / ripple_lifetime), 0.0, 1.0);

	float ring = sin((dist - wave_front) * (6.2831 / ripple_wavelength));
	float proximity = exp(-abs(dist - wave_front) * 2.0);

	return ring * proximity * falloff * ripple_amplitude;
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 world_xz = world_pos.xz;

	float total_ripple = 0.0;
	for (int i = 0; i < MAX_RIPPLES; i++) {
		total_ripple += ripple_contribution(world_xz, ripple_positions[i], ripple_start_times[i]);
	}

	float ambient_wave = sin((world_xz.x + world_xz.y) * wave_scale + TIME * wave_speed) * wave_height;

	VERTEX.y += total_ripple + ambient_wave;
	ripple_height_v = total_ripple;
	world_xz_v = world_xz;
}

void fragment() {
	vec3 view_dir = normalize(VIEW);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, view_dir), 0.0, 1.0), fresnel_power);

	// Hard bands instead of a smooth gradient — the core "toon" look.
	float banded_fresnel = floor(fresnel * float(depth_bands)) / float(depth_bands);
	vec3 water_color = mix(deep_color.rgb, shallow_color.rgb, banded_fresnel);
	float water_alpha = mix(deep_color.a, shallow_color.a, banded_fresnel);

	// Bold crest highlight, sharp-edged rather than soft.
	float crest_mask = step(ripple_amplitude * ring_threshold, ripple_height_v);
	water_color = mix(water_color, ring_highlight_color.rgb, crest_mask);

	if (sparkle_enabled) {
		vec2 sparkle_uv = world_xz_v * sparkle_density;
		vec2 cell = floor(sparkle_uv + TIME * sparkle_speed * 0.1);
		float n = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
		float twinkle = step(sparkle_chance, n);
		water_color += sparkle_color.rgb * twinkle;
	}

	ALBEDO = water_color;
	ALPHA = water_alpha;
	ROUGHNESS = 0.3;
	METALLIC = 0.0;

	if (rim_enabled) {
		float rim = pow(1.0 - clamp(dot(NORMAL, view_dir), 0.0, 1.0), rim_power);
		EMISSION = rim_color.rgb * rim * rim_strength;
	}
}

void light() {
	// Same two-tone tinted-shadow toon technique as your anime shader,
	// so the water reads as part of the same visual style as everything
	// else in the cafe.
	float ndotl = dot(NORMAL, LIGHT);
	float band = smoothstep(-0.05, 0.05, ndotl);

	vec3 lit = ALBEDO;
	vec3 shadowed = ALBEDO * shade_color.rgb;
	DIFFUSE_LIGHT += mix(shadowed, lit, band) * ATTENUATION * LIGHT_COLOR;
}
