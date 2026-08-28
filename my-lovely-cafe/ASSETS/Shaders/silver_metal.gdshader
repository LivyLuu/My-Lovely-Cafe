shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.75, 0.76, 0.78, 1.0);
uniform float metallic_amount : hint_range(0.0, 1.0) = 0.95;
uniform float roughness_amount : hint_range(0.0, 1.0) = 0.22;

// Optional detail texture for wear/etching/variation. Leave unassigned
// and it has zero effect (multiplies against pure white).
uniform sampler2D detail_texture : source_color, hint_default_white;
uniform vec2 detail_tiling = vec2(1.0, 1.0);

// Cheap procedural brushed-metal streaks — no texture needed, just a
// sine wave perturbing roughness along one direction.
uniform bool brushed_streaks_enabled = true;
uniform float streak_frequency : hint_range(10.0, 400.0) = 120.0;
uniform float streak_strength : hint_range(0.0, 0.3) = 0.06;

// Rim light, same control set as your other shaders.
uniform bool rim_enabled = true;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_power : hint_range(1.0, 8.0) = 3.0;
uniform float rim_strength : hint_range(0.0, 3.0) = 0.6;

void fragment() {
	vec3 detail = texture(detail_texture, UV * detail_tiling).rgb;
	ALBEDO = base_color.rgb * detail;
	METALLIC = metallic_amount;

	float roughness = roughness_amount;
	if (brushed_streaks_enabled) {
		float streak = sin(UV.x * streak_frequency) * 0.5 + 0.5;
		roughness += (streak - 0.5) * streak_strength;
	}
	ROUGHNESS = clamp(roughness, 0.0, 1.0);

	if (rim_enabled) {
		vec3 view_dir = normalize(VIEW);
		float rim = pow(1.0 - clamp(dot(NORMAL, view_dir), 0.0, 1.0), rim_power);
		EMISSION = rim_color.rgb * rim * rim_strength;
	}
}
