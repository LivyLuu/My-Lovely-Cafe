shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, blend_mix, shadows_disabled;

uniform vec4 rain_color : source_color = vec4(0.75, 0.92, 1.0, 0.35);
uniform vec4 holo_tint_a : source_color = vec4(0.55, 1.0, 1.0, 1.0);
uniform vec4 holo_tint_b : source_color = vec4(1.0, 0.65, 1.0, 1.0);
uniform float scroll_speed : hint_range(0.0, 10.0) = 5.0;
uniform float edge_softness : hint_range(0.01, 1.0) = 0.35;
uniform float glow_strength : hint_range(0.0, 3.0) = 1.2;
uniform float streak_length : hint_range(0.1, 3.0) = 1.0;

void vertex() {
	// stretch the quad along its local "up" (streak) axis only,
	// so faster rain reads as longer streaks without getting wider
	VERTEX.y *= streak_length;

	vec3 model_pos = MODEL_MATRIX[3].xyz;
	vec3 to_camera = normalize(CAMERA_POSITION_WORLD - model_pos);

	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 right = normalize(cross(up, to_camera));
	vec3 forward = normalize(cross(right, up));

	mat4 billboard_matrix = mat4(
		vec4(right, 0.0),
		vec4(up, 0.0),
		vec4(forward, 0.0),
		vec4(model_pos, 1.0)
	);

	MODELVIEW_MATRIX = VIEW_MATRIX * billboard_matrix;
}

void fragment() {
	float edge_fade = 1.0 - abs(UV.y - 0.5) * 2.0;
	edge_fade = smoothstep(0.0, edge_softness, edge_fade);

	// bright glowing core running down the center of the streak
	float core = 1.0 - abs(UV.x - 0.5) * 2.0;
	core = pow(clamp(core, 0.0, 1.0), 3.0);

	float holo_mix = sin(UV.y * 6.283185 + TIME * scroll_speed) * 0.5 + 0.5;
	vec3 holo = mix(holo_tint_a.rgb, holo_tint_b.rgb, holo_mix);

	vec3 base = mix(rain_color.rgb, holo, 0.6);
	ALBEDO = base + core * glow_strength;
	ALPHA = clamp(rain_color.a * edge_fade + core * edge_fade * 0.5, 0.0, 1.0);
}