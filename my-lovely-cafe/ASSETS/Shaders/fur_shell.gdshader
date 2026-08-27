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

// Assign a NoiseTexture2D here (Godot can generate one for you in the
// Inspector — no external image needed) for the strand pattern.
uniform sampler2D fur_pattern : source_color, hint_default_white;
uniform vec2 fur_tiling = vec2(12.0, 12.0);

uniform float fur_density : hint_range(0.0, 1.0) = 0.55;
uniform float fur_thickness : hint_range(0.0, 0.1) = 0.02;

void vertex() {
	// Push this shell outward along the mesh's own normals. shell_index
	// close to 0 stays near the surface; close to 1 sits at the fur tips.
	VERTEX += normalize(NORMAL) * fur_thickness * shell_index;
}

void fragment() {
	vec2 uv = UV * fur_tiling;
	float noise = texture(fur_pattern, uv).r;

	// Higher shell_index requires a higher noise value to stay visible —
	// this is what thins the fur out toward the tips instead of every
	// shell looking like a solid, identical layer.
	float threshold = mix(1.0 - fur_density, 1.0, shell_index);

	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA = step(threshold, noise);

	ALBEDO = mix(root_color.rgb, tip_color.rgb, shell_index);
}
