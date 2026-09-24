shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, blend_add, shadows_disabled;

uniform vec4 droplet_color : source_color = vec4(0.65, 0.95, 1.0, 1.0);

void vertex() {
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
	vec2 centered = UV * 2.0 - 1.0;
	float dist = length(centered);
	float dot_shape = 1.0 - smoothstep(0.0, 1.0, dist);

	ALBEDO = droplet_color.rgb;
	ALPHA = dot_shape * droplet_color.a * COLOR.a;
}
