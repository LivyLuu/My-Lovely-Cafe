shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque, shadows_disabled;

// Two small meshes share this one shader:
//   - A thin cylinder for the falling stream (is_splash = false)
//   - A flat disc for the splash on the floor (is_splash = true)
// Toggle the WHOLE EFFECT on/off by setting the parent node's
// `visible = false` in your script — cheapest option, a hidden node
// costs nothing to render.

uniform vec4 liquid_color : source_color = vec4(0.32, 0.18, 0.08, 0.85);

// Stream settings
uniform float flow_speed : hint_range(0.0, 10.0) = 3.0;
uniform float wobble_amount : hint_range(0.0, 0.02) = 0.004;
uniform float wobble_freq : hint_range(0.0, 20.0) = 6.0;

// Splash settings
uniform bool is_splash = false;
uniform float ring_frequency : hint_range(1.0, 40.0) = 14.0;
uniform float ring_speed : hint_range(0.0, 20.0) = 8.0;
uniform float splash_fade_radius : hint_range(0.1, 1.0) = 0.5;

varying float v_uv_y;

void vertex() {
	v_uv_y = UV.y;
	mat3 rot = mat3(MODEL_MATRIX);

	if (is_splash) {
		// Keep the splash disc lying flat, facing world-up, no matter
		// how its parent (the cup) is currently rotated.
		vec3 local_up = transpose(rot) * vec3(0.0, 1.0, 0.0);
		float height = dot(VERTEX, local_up);
		VERTEX -= local_up * height;
	} else {
		// Stream mesh: always points along world-down, regardless of
		// the cup's rotation — the same "counter-rotate against
		// MODEL_MATRIX" trick as the liquid fill shader, just building
		// a full basis instead of a single height value this time.
		// Mesh is assumed authored along +Y, rim at Y=0 down to the tip.
		vec3 local_down = transpose(rot) * vec3(0.0, -1.0, 0.0);
		vec3 reference = abs(local_down.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
		vec3 right = normalize(cross(reference, local_down));
		vec3 forward = cross(local_down, right);

		float wobble = sin(v_uv_y * wobble_freq + TIME * flow_speed) * wobble_amount;
		float original_y = VERTEX.y;
		VERTEX = right * (VERTEX.x + wobble) + local_down * (-original_y) + forward * VERTEX.z;
	}
}

void fragment() {
	if (is_splash) {
		vec2 centered = UV - vec2(0.5);
		float dist = length(centered) * 2.0;

		float ring = sin(dist * ring_frequency - TIME * ring_speed) * 0.5 + 0.5;
		ring = smoothstep(0.55, 0.65, ring);
		float fade = 1.0 - smoothstep(splash_fade_radius * 0.6, splash_fade_radius, dist);

		ALBEDO = liquid_color.rgb;
		ALPHA = ring * fade * liquid_color.a;
	} else {
		// Scrolling band pattern for flow motion, tapered at both ends
		// so it blends into the cup rim and the splash below instead
		// of showing a hard cutoff edge.
		float flow = fract(v_uv_y * 3.0 - TIME * flow_speed);
		float band = smoothstep(0.0, 0.5, flow) * smoothstep(1.0, 0.5, flow);
		float taper = smoothstep(0.0, 0.08, v_uv_y) * smoothstep(1.0, 0.92, v_uv_y);

		ALBEDO = liquid_color.rgb;
		ALPHA = mix(0.6, 1.0, band) * taper * liquid_color.a;
	}
}
