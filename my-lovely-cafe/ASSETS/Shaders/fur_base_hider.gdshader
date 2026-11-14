shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_always, cull_back;

// Used by Final_fur.gd when "Hide Base Mesh" is on. It is applied to the fur surface through the
// RenderingServer only (the node's real material is never changed or saved).
//
// The surface draws NO colour, so the base mesh can never show through the fur, but it still
// writes depth. That keeps the fur correctly hidden behind other body parts, exactly as when the
// base mesh was opaque. render_priority is set very low so this draws before the fur layers.

void fragment() {
	ALBEDO = vec3(0.0);
	ALPHA = 0.0;
}
