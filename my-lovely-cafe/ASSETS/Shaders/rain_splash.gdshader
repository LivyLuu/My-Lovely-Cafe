shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, blend_add, shadows_disabled;

uniform vec4 splash_color : source_color = vec4(0.6, 0.95, 1.0, 1.0);
uniform float ring_thickness : hint_range(0.01, 0.5) = 0.12;
uniform float ring_radius : hint_range(0.1, 1.0) = 0.75;

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float dist = length(centered);
	float ring = 1.0 - smoothstep(0.0, ring_thickness, abs(dist - ring_radius));

	ALBEDO = splash_color.rgb;
	ALPHA = ring * splash_color.a * COLOR.a;
}