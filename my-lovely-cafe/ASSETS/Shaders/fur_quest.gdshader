shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_lambert_wrap, specular_disabled;

// Soft shell fur built for Quest / mobile (Forward+, Mobile and Compatibility renderers).
//
// - Every shell layer is one INSTANCE of a MultiMesh, so the whole coat is ONE draw call.
//   INSTANCE_CUSTOM.x holds that layer's height (0..1). Final_fur.gd sets it all up.
// - Strands are procedural (a jittered, hashed grid in UV space), so there is no noise
//   texture to generate or sample. Only the albedo texture is read, once per pixel.
// - Hairs are anti-aliased analytically and use real alpha, so they stay soft and don't
//   sparkle in VR. Past the point where hairs are smaller than a pixel they fade into a
//   smooth average coat instead of shimmering.
// - "Fluff" adds big soft clumps on top of the hairs: a low-frequency 3D noise (in the
//   mesh's own space, so it ignores UV stretching) bulges the coat into cotton-like lumps,
//   and a finer copy of it gives every layer a cloudy, mottled coverage. With Strand Detail
//   turned down the individual hairs fade away and you get a smooth plush surface.
// - Fur length is in the mesh's OWN units (the script converts "% of body size").
//
// hash12 / hash22 / hash13 follow Dave Hoskins' "Hash without Sine" (MIT License).

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform vec2 albedo_tiling = vec2(1.0);
uniform vec4 fur_tint : source_color = vec4(1.0);

uniform float fur_length = 0.001;
uniform float gravity : hint_range(0.0, 1.0) = 0.3;
uniform vec3 comb = vec3(0.0);

uniform float strand_density = 260.0;
uniform float strand_radius : hint_range(0.1, 0.7) = 0.5;
uniform float min_strand_height : hint_range(0.0, 0.95) = 0.55;
uniform float tip_softness : hint_range(0.0, 1.0) = 0.75;
uniform float clumping : hint_range(0.0, 1.0) = 0.35;
uniform float clump_size = 8.0;
uniform float strand_detail : hint_range(0.0, 1.0) = 1.0;

uniform float fluff_amount : hint_range(0.0, 1.0) = 0.0;
uniform float fluff_frequency = 100.0;
uniform float bump_strength : hint_range(0.0, 1.0) = 0.0;

uniform float silhouette_softness : hint_range(0.0, 1.0) = 0.65;
// > 0 lights the fur with smoothed normals that Final_fur.gd stores in the vertex colour. The fur
// still GROWS along the model's real normals, so the shape stays faithful; only the shading softens.
uniform float smooth_amount : hint_range(0.0, 1.0) = 0.0;
// 1 when the base mesh is hidden: nothing solid is underneath any more, so the innermost layer
// follows the same soft edge fade as the others instead of forming a hard-edged core.
uniform float base_hidden : hint_range(0.0, 1.0) = 0.0;
// How far up the coat (0..1 of its height) the layers stay fully opaque. Beyond that they fade
// into the normal wispy, transparent layers. 0 = off.
uniform float core_depth : hint_range(0.0, 1.0) = 0.0;

uniform vec4 root_tint : source_color = vec4(1.0);
uniform float root_shade : hint_range(0.0, 1.0) = 0.72;
uniform float tip_shade : hint_range(0.5, 1.5) = 1.0;
uniform float strand_variation : hint_range(0.0, 1.0) = 0.15;
uniform float softness : hint_range(0.0, 1.0) = 0.8;
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.25;

varying float shell_t;
varying float shell_undercoat;
varying float shell_puff;
varying vec3 shell_origin;
varying float shell_world_scale;

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float hash13(vec3 p3) {
	p3 = fract(p3 * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}

// Smooth 3D value noise, 0..1.
float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float x00 = mix(hash13(i), hash13(i + vec3(1.0, 0.0, 0.0)), f.x);
	float x10 = mix(hash13(i + vec3(0.0, 1.0, 0.0)), hash13(i + vec3(1.0, 1.0, 0.0)), f.x);
	float x01 = mix(hash13(i + vec3(0.0, 0.0, 1.0)), hash13(i + vec3(1.0, 0.0, 1.0)), f.x);
	float x11 = mix(hash13(i + vec3(0.0, 1.0, 1.0)), hash13(i + vec3(1.0, 1.0, 1.0)), f.x);
	return mix(mix(x00, x10, f.y), mix(x01, x11, f.y), f.z);
}

// Value noise hovers around 0.5, so stretch it for stronger lumps.
float contrast(float v) {
	return clamp((v - 0.5) * 1.8 + 0.5, 0.0, 1.0);
}

void vertex() {
	shell_t = INSTANCE_CUSTOM.x;
	shell_undercoat = INSTANCE_CUSTOM.y; // 1.0 on the innermost layer: a solid dark undercoat
	shell_origin = VERTEX;
	shell_world_scale = length(MODEL_MATRIX[0].xyz); // object units -> world units, for the bump height

	// Fluff clumps: low-frequency noise makes the fur longer in some places and shorter in
	// others, so the outline bulges into soft lumps instead of staying a smooth hull.
	shell_puff = 0.5;
	float length_scale = 1.0;
	if (fluff_amount > 0.0) {
		shell_puff = contrast(vnoise3(VERTEX * fluff_frequency));
		length_scale = 1.0 + fluff_amount * (shell_puff - 0.5) * 1.2;
	}

	// World "down" expressed in the mesh's local space (row-vector * matrix = inverse rotation).
	vec3 down = normalize(vec3(0.0, -1.0, 0.0) * mat3(MODEL_MATRIX));
	vec3 lean = down * gravity + comb;
	VERTEX += (NORMAL + lean * shell_t) * (fur_length * shell_t * length_scale);

	// From here on NORMAL only affects lighting, so swap in the smoothed normal.
	if (smooth_amount > 0.0) {
		NORMAL = normalize(mix(NORMAL, CUSTOM0.xyz, smooth_amount));
	}
}

void fragment() {
	float t = shell_t;

	// Sample first: derivatives (texture + fwidth) must happen before any discard.
	vec3 tex = texture(albedo_tex, UV * albedo_tiling).rgb * fur_tint.rgb;
	vec2 cell_uv = UV * strand_density;
	float px = max(fwidth(cell_uv.x), fwidth(cell_uv.y)); // strand cells per screen pixel

	// Clumping: higher up the coat, strands lean in toward their clump's centre. The pull
	// fades to zero at the clump's border so neighbouring tufts meet without a seam.
	vec2 clump_id = floor(cell_uv / clump_size);
	vec2 clump_centre = (clump_id + 0.5 + (hash22(clump_id) - 0.5) * 0.5) * clump_size;
	vec2 to_centre = cell_uv - clump_centre;
	float clump_falloff = clamp(1.0 - length(to_centre) / (clump_size * 0.5), 0.0, 1.0);
	vec2 p = cell_uv + to_centre * (clumping * t * t * clump_falloff * 2.0);

	// One strand per cell, jittered off the grid, each with its own random height.
	vec2 id = floor(p);
	vec2 jitter = hash22(id) - 0.5;
	float rnd = hash12(id + 17.0);
	float strand_height = mix(min_strand_height, 1.0, rnd);
	float q = t / strand_height; // 0 at the root of this strand, 1 at its tip

	float radius = strand_radius * max(1.0 - q, 0.0);
	float dist = length(fract(p) - 0.5 - jitter * 0.4);

	// Analytic anti-aliasing: the edge is one pixel wide, and hairs thinner than a pixel
	// fade out instead of flickering.
	float edge = max(px, 0.0001);
	float strand_cover = clamp((radius - dist) / edge + 0.5, 0.0, 1.0) * clamp(radius * 2.0 / edge, 0.0, 1.0);

	// Far away (hairs smaller than a pixel) switch to the coat's average coverage.
	float far_blend = smoothstep(0.4, 1.2, px);
	float mean_cover = (1.0 - smoothstep(min_strand_height, 1.0, t)) * clamp(strand_radius * strand_radius * 4.0, 0.0, 1.0);
	strand_cover = mix(strand_cover, mean_cover, far_blend);

	// Fluff: every spot has a soft "column" of fur of its own height, from the big lumps blended
	// with a finer mottling. Layers above that height fade out, which stacks up into cotton clumps.
	float column = 0.5;
	float fluff_cover = 1.0;
	float fine_raw = 0.5;
	if (fluff_amount > 0.0) {
		fine_raw = vnoise3(shell_origin * (fluff_frequency * 3.0));
		float fine = contrast(fine_raw);
		column = mix(shell_puff, fine, 0.5);
		float column_height = mix(1.0, 0.25 + 0.9 * column, fluff_amount);
		fluff_cover = clamp((column_height - t) / 0.35, 0.0, 1.0);
	}

	// Strand Detail fades the individual hairs out, leaving only the smooth fluff.
	float cover = fluff_cover * mix(1.0, strand_cover, strand_detail);

	// The innermost layer is a solid undercoat, so no bare skin shows between the roots.
	cover = max(cover, shell_undercoat);

	// Solid core: the inner layers cover the whole surface (no strand gaps, no tip fade), then
	// fade out over the upper half of the core into the wispy outer layers.
	float core = 0.0;
	if (core_depth > 0.0) {
		core = 1.0 - smoothstep(core_depth * 0.5, core_depth, t);
		cover = max(cover, core);
	}

	// Seen edge-on, stacked layers read as ribs. Fading them there keeps the silhouette soft.
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float graze = mix(1.0 - silhouette_softness, 1.0, smoothstep(0.0, 0.5, facing));
	// ...but never fade the undercoat: it must stay solid so the plain base material underneath
	// (lit differently) can't show through and make the fur look like a separate layer.
	graze = mix(graze, 1.0, shell_undercoat * (1.0 - base_hidden));
	// The core only partly ignores the edge fade, so its outline stays soft rather than stepped.
	graze = mix(graze, 1.0, core * 0.5);

	// Bump: the fine fluff noise doubles as a height field, and its slope tilts the lighting normal
	// so the clumps catch light and shade like little cotton bumps. This is the screen-derivative
	// "surface gradient" method (no texture and no extra noise lookups). Silhouette and rim above
	// keep the smooth geometric normal.
	if (fluff_amount > 0.0 && bump_strength > 0.0) {
		float clump_wavelength = shell_world_scale / (fluff_frequency * 3.0); // world units
		float bump_height = fine_raw * clump_wavelength * 0.7 * bump_strength;
		vec3 dpdx = dFdx(VERTEX);
		vec3 dpdy = dFdy(VERTEX);
		vec3 r1 = cross(dpdy, NORMAL);
		vec3 r2 = cross(NORMAL, dpdx);
		float det = dot(dpdx, r1);
		vec3 surface_gradient = sign(det) * (dFdx(bump_height) * r1 + dFdy(bump_height) * r2);
		NORMAL = normalize(abs(det) * NORMAL - surface_gradient);
	}

	// Tips fade with the hair's own height, or with the layer's height once hairs are faded out.
	float tip_q = mix(t, q, strand_detail);
	float alpha = cover * graze * (1.0 - tip_softness * tip_q * tip_q * (1.0 - core));
	ALPHA = alpha;

	// Roots can be tinted (e.g. pink or lilac) so the shadowed depths of the coat get a colour
	// instead of just going grey. Lump shading darkens the creases between fluff clumps a little.
	float lump_shade = mix(1.0, 0.7 + 0.3 * column, fluff_amount * 0.6);
	vec3 tone = mix(root_tint.rgb * root_shade, vec3(tip_shade), t) * (1.0 - strand_variation * rnd * strand_detail) * lump_shade;
	ALBEDO = tex * tone;
	ROUGHNESS = softness;

	float rim = 1.0 - facing;
	EMISSION = rim_color.rgb * tex * (rim * rim * rim_strength * t);

	if (alpha < 0.02) {
		discard;
	}
}
