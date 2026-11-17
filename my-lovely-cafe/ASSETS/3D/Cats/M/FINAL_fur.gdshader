shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

// Chain 4-6+ of these via Next Pass (base material -> shell 1 -> shell 2 -> ...).
// Each shell instance gets its OWN shell_index, evenly spaced 0.0 to 1.0
// across however many shells you're using. shell_index 0.0 should be
// your BASE mesh material, not a fur pass at all.

uniform float shell_index : hint_range(0.0, 1.0) = 0.2;

uniform vec4 root_color : source_color = vec4(0.35, 0.25, 0.18, 1.0);
uniform vec4 tip_color : source_color = vec4(0.6, 0.5, 0.42, 1.0);

// A color-pattern texture (spots, stripes, whatever) carried through the
// fur's depth. Tileable via pattern_tiling instead of stretching once
// across the UV.
uniform sampler2D pattern_texture : source_color, hint_default_white;
uniform vec2 pattern_tiling = vec2(4.0, 4.0);
uniform float pattern_strength : hint_range(0.0, 1.0) = 0.6;

// Assign a NoiseTexture2D here (Godot can generate one for you in the
// Inspector — no external image needed) for the strand density pattern.
uniform sampler2D fur_pattern : source_color, hint_default_white;
uniform vec2 fur_tiling = vec2(12.0, 12.0);

uniform float fur_density : hint_range(0.0, 1.0) = 0.55;

// How far this shell sits from the surface. "or_greater" lets you type
// values past the slider's visible range for genuinely long fur.
uniform float fur_thickness : hint_range(0.0, 0.3, 0.001) = 0.02;

// Direction the fur is combed — this is your "sag vs. stand up" control.
// e.g. (0.0, -0.6, 0.0) sags downward, (0.0, 0.6, 0.0) lifts upward,
// mix in X/Z for a sideways sweep.
uniform vec3 fur_lean = vec3(0.2, -0.4, 0.0);

// Direct highlight, strongest where the surface faces the camera.
uniform vec4 sheen_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float sheen_strength : hint_range(0.0, 2.0) = 0.4;
uniform float sheen_power : hint_range(1.0, 32.0) = 12.0;

// Edge glow, strongest at grazing angles — separate from sheen above.
uniform bool rim_enabled = true;
uniform vec4 rim_color : source_color = vec4(1.0, 0.9, 0.75, 1.0);
uniform float rim_power : hint_range(1.0, 8.0) = 3.0;
uniform float rim_strength : hint_range(0.0, 3.0) = 0.5;

void vertex() {
	vec3 lean_dir = normalize(NORMAL + fur_lean);
	VERTEX += lean_dir * fur_thickness * shell_index;
}

void fragment() {
	vec2 uv = UV * fur_tiling;
	float noise = texture(fur_pattern, uv).r;

	float density_curve = pow(shell_index, 1.6);
	float threshold = mix(1.0 - fur_density, 1.0, density_curve);

	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA = step(threshold, noise);

	vec3 pattern = texture(pattern_texture, UV * pattern_tiling).rgb;
	vec3 base_color = mix(root_color.rgb, tip_color.rgb, shell_index);
	ALBEDO = mix(base_color, base_color * pattern, pattern_strength);

	vec3 view_dir = normalize(VIEW);

	float sheen = pow(clamp(dot(NORMAL, view_dir), 0.0, 1.0), sheen_power);
	EMISSION = sheen_color.rgb * sheen * sheen_strength * shell_index;

	if (rim_enabled) {
		float rim = pow(1.0 - clamp(dot(NORMAL, view_dir), 0.0, 1.0), rim_power);
		EMISSION += rim_color.rgb * rim * rim_strength;
	}
}
