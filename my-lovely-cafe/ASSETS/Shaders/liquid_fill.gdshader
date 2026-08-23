shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Drive these from your Cup state machine, e.g.:
// liquid_mesh.material_override.set_shader_parameter("fill_amount", 0.8)
// liquid_mesh.material_override.set_shader_parameter("liquid_color", espresso_brown)

uniform vec4 liquid_color : source_color = vec4(0.32, 0.18, 0.08, 1.0);
uniform vec4 foam_color : source_color = vec4(0.85, 0.75, 0.6, 1.0);
uniform float fill_amount : hint_range(0.0, 1.0) = 0.8;

// Local-space bounds of your liquid mesh along its up axis — set these
// to roughly match the inner height of your cup (in meters).
uniform float container_bottom = -0.04;
uniform float container_top = 0.04;

uniform float foam_thickness : hint_range(0.0005, 0.01) = 0.003;
uniform float edge_smoothness : hint_range(0.0001, 0.005) = 0.0008;
uniform float roughness : hint_range(0.0, 1.0) = 0.12;

// Optional gentle idle motion. Leave slosh_strength at 0.0 for a
// perfectly still surface, or drive it from angular velocity in code
// for real sloshing when the cup gets jostled.
uniform float slosh_strength : hint_range(0.0, 0.01) = 0.0;
uniform float slosh_speed : hint_range(0.0, 5.0) = 1.5;

varying float liquid_height;

void vertex() {
	// mat3(MODEL_MATRIX) is orthogonal for a pure rotation (no non-uniform
	// scale), so transpose() gives the same result as inverse() here —
	// much cheaper on mobile GPUs than a real matrix inverse.
	mat3 rot = mat3(MODEL_MATRIX);
	vec3 local_up = transpose(rot) * vec3(0.0, 1.0, 0.0);

	// This single dot product is what makes the surface "stay flat" in
	// world space even as the mesh itself rotates underneath it.
	liquid_height = dot(VERTEX, local_up);
}

void fragment() {
	float fill_level = mix(container_bottom, container_top, fill_amount);
	fill_level += sin(TIME * slosh_speed) * slosh_strength;

	// Cutout instead of alpha blending: cheaper on Quest, sorts correctly
	// with depth automatically, no transparency-order issues against the
	// cup's glass shader.
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA = smoothstep(fill_level + edge_smoothness, fill_level - edge_smoothness, liquid_height);

	float foam = 1.0 - smoothstep(0.0, foam_thickness, abs(liquid_height - fill_level));

	vec3 view_dir = normalize(VIEW);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, view_dir), 0.0, 1.0), 4.0);

	ALBEDO = mix(liquid_color.rgb, foam_color.rgb, foam);
	EMISSION = foam_color.rgb * foam * fresnel * 0.25;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
}
