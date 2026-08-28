shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

// Chain 4-6 of these via Next Pass (base material -> shell 1 -> shell 2 -> ...).
// Each shell instance gets its OWN shell_index, evenly spaced 0.0 to 1.0
// across however many shells you're using (e.g. 6 shells: 0.0, 0.2, 0.4,
// 0.6, 0.8, 1.0). shell_index 0.0 should be your BASE mesh material,
// not a fur pass at all.

uniform float shell_index : hint_range(0.0, 1.0) = 0.2;

uniform vec4 root_color : source_color = vec4(0.35, 0.25, 0.18, 1.0);
uniform vec4 tip_color : source_color = vec4(0.6, 0.5, 0.42, 1.0);

// A color-pattern texture (spots, stripes, whatever) carried through the
// fur's depth, instead of just a flat root-to-tip gradient.
uniform sampler2D pattern_texture : source_color, hint_default_white;
uniform float pattern_strength : hint_range(0.0, 1.0) = 0.6;

// Assign a NoiseTexture2D here (Godot can generate one for you in the
// Inspector — no external image needed) for the strand density pattern.
uniform sampler2D fur_pattern : source_color, hint_default_white;
uniform vec2 fur_tiling = vec2(12.0, 12.0);

uniform float fur_density : hint_range(0.0, 1.0) = 0.55;
uniform float fur_thickness : hint_range(0.0, 0.1) = 0.02;

// Combs the fur in a direction instead of it sticking straight out along
// normals — this alone is a big part of what makes reference fur read as
// "styled" rather than "shrink-wrapped spikes." Set in the mesh's LOCAL
// space, e.g. (0.3, -0.6, 0.0) leans fur down and slightly sideways.
uniform vec3 fur_lean = vec3(0.2, -0.4, 0.0);

// Fine glossy highlight on individual strands.
uniform float sheen_strength : hint_range(0.0, 2.0) = 0.4;
uniform float sheen_power : hint_range(1.0, 32.0) = 12.0;

void vertex() {
	vec3 lean_dir = normalize(NORMAL + fur_lean);
	VERTEX += lean_dir * fur_thickness * shell_index;
}

void fragment() {
	vec2 uv = UV * fur_tiling;
	float noise = texture(fur_pattern, uv).r;

	// Higher shell_index requires a higher noise value to stay visible —
	// pow() instead of a flat mix gives a softer, fluffier falloff near
	// the tips rather than a hard linear thinning.
	float density_curve = pow(shell_index, 1.6);
	float threshold = mix(1.0 - fur_density, 1.0, density_curve);

	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA = step(threshold, noise);

	vec3 pattern = texture(pattern_texture, UV).rgb;
	vec3 base_color = mix(root_color.rgb, tip_color.rgb, shell_index);
	ALBEDO = mix(base_color, base_color * pattern, pattern_strength);

	vec3 view_dir = normalize(VIEW);
	float sheen = pow(clamp(dot(NORMAL, view_dir), 0.0, 1.0), sheen_power);
	EMISSION = vec3(sheen) * sheen_strength * shell_index;
}
