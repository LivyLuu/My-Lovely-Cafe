shader_type spatial;
render_mode cull_front, unshaded, depth_draw_always;

// Attach this as the main shader's "Next Pass" material — don't apply
// it as a standalone material on its own mesh.

uniform vec4 outline_color : source_color = vec4(0.05, 0.05, 0.08, 1.0);
uniform float outline_width : hint_range(0.0, 0.05) = 0.006;

void vertex() {
	// Push the mesh outward along its own normals, then render only the
	// BACK faces (cull_front). Since the inflated backfaces poke out
	// slightly past the real mesh's silhouette, this creates a clean
	// outline ring with a single extra draw call — no duplicate geometry
	// or geometry shader needed, which matters since Quest doesn't
	// support geometry shaders anyway.
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
