shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.9, 0.95, 1.0, 0.15);
uniform float roughness : hint_range(0.0, 1.0) = 0.05;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float iridescence_strength : hint_range(0.0, 2.0) = 1.0;
uniform float fresnel_power : hint_range(0.5, 8.0) = 3.0;

void fragment() {
	vec3 view_dir = normalize(VIEW);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, view_dir), 0.0, 1.0), fresnel_power);

	// Cosine-palette trick: cycles smoothly through the rainbow
	// based on viewing angle, with a little variation from surface normal
	// so the color shifts as the glass curves, not just at the edges.
	float hue = fresnel * iridescence_strength + NORMAL.x * 0.2 + NORMAL.y * 0.15;
	vec3 iridescent_color = vec3(
		0.5 + 0.5 * cos(6.2831 * (hue + 0.0)),
		0.5 + 0.5 * cos(6.2831 * (hue + 0.33)),
		0.5 + 0.5 * cos(6.2831 * (hue + 0.66))
	);

	ALBEDO = base_color.rgb;
	EMISSION = iridescent_color * fresnel * iridescence_strength;
	ALPHA = base_color.a + fresnel * 0.3;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	RIM = fresnel;
	RIM_TINT = 0.8;
}
